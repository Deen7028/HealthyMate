<?php
require_once "db_connect.php";

$method = $_SERVER['REQUEST_METHOD'];

switch ($method) {
    // 1. GET: ดึงข้อมูลโปรไฟล์ผู้ใช้จาก TbUsers
    case 'GET':
        $userId = isset($_GET['nUserId']) ? intval($_GET['nUserId']) : 1;

        try {
            $stmt = $conn->prepare("SELECT nUserId, sEmail, sFirstName, sLastName, nAge, nHeight, nWeight, sGender, sActivityLevel, isDarkMode, sProfileImagePath, dtCreatedAt FROM TbUsers WHERE nUserId = :userId");
            $stmt->execute([':userId' => $userId]);
            $user = $stmt->fetch();

            if ($user) {
                echo json_encode([
                    "status" => "success",
                    "data" => $user
                ], JSON_UNESCAPED_UNICODE);
            } else {
                echo json_encode([
                    "status" => "error",
                    "message" => "User not found"
                ]);
            }
        } catch (PDOException $e) {
            echo json_encode([
                "status" => "error",
                "message" => $e->getMessage()
            ]);
        }
        break;

    // 2. POST / PUT: บันทึกหรืออัปเดตข้อมูลผู้ใช้ใน TbUsers
    case 'POST':
    case 'PUT':
        $data = json_decode(file_get_contents("php://input"), true);

        if (!$data) {
            $data = $_POST;
        }

        $userId = isset($data['nUserId']) ? intval($data['nUserId']) : null;
        $email = isset($data['sEmail']) ? trim($data['sEmail']) : null;
        $firstName = isset($data['sFirstName']) ? trim($data['sFirstName']) : null;
        $lastName = isset($data['sLastName']) ? trim($data['sLastName']) : '';
        $passwordHash = isset($data['sPasswordHash']) ? trim($data['sPasswordHash']) : '';
        $age = isset($data['nAge']) ? intval($data['nAge']) : 0;
        $height = isset($data['nHeight']) ? floatval($data['nHeight']) : 0.0;
        $weight = isset($data['nWeight']) ? floatval($data['nWeight']) : 0.0;
        $gender = isset($data['sGender']) ? trim($data['sGender']) : 'male';
        $activityLevel = isset($data['sActivityLevel']) ? trim($data['sActivityLevel']) : 'light';
        $profileImagePath = isset($data['sProfileImagePath']) ? trim($data['sProfileImagePath']) : '';

        if (!$email && !$userId) {
            echo json_encode([
                "status" => "error",
                "message" => "Missing required user identifier (nUserId or sEmail)"
            ]);
            exit();
        }

        try {
            // 1. ตรวจสอบว่ามีผู้ใช้นี้ใน MySQL หรือยัง (ค้นหาจาก sEmail หรือ nUserId)
            $stmt = null;
            if ($email) {
                $stmt = $conn->prepare("SELECT nUserId FROM TbUsers WHERE sEmail = :email LIMIT 1");
                $stmt->execute([':email' => $email]);
            } else {
                $stmt = $conn->prepare("SELECT nUserId FROM TbUsers WHERE nUserId = :userId LIMIT 1");
                $stmt->execute([':userId' => $userId]);
            }
            $existingUser = $stmt->fetch();

            if ($existingUser) {
                // มีอยู่แล้ว -> ทำการ UPDATE ข้อมูลโปรไฟล์
                $targetUserId = $existingUser['nUserId'];
                $updateFields = [];
                $params = [':userId' => $targetUserId];

                if ($firstName !== null) { $updateFields[] = "sFirstName = :firstName"; $params[':firstName'] = $firstName; }
                if ($lastName !== null) { $updateFields[] = "sLastName = :lastName"; $params[':lastName'] = $lastName; }
                if (!empty($passwordHash)) { $updateFields[] = "sPasswordHash = :passwordHash"; $params[':passwordHash'] = $passwordHash; }
                if (isset($data['nAge'])) { $updateFields[] = "nAge = :age"; $params[':age'] = $age; }
                if (isset($data['nHeight'])) { $updateFields[] = "nHeight = :height"; $params[':height'] = $height; }
                if (isset($data['nWeight'])) { $updateFields[] = "nWeight = :weight"; $params[':weight'] = $weight; }
                if (isset($data['sGender'])) { $updateFields[] = "sGender = :gender"; $params[':gender'] = $gender; }
                if (isset($data['sActivityLevel'])) { $updateFields[] = "sActivityLevel = :activityLevel"; $params[':activityLevel'] = $activityLevel; }
                if (isset($data['sProfileImagePath'])) { $updateFields[] = "sProfileImagePath = :profileImagePath"; $params[':profileImagePath'] = $profileImagePath; }

                $updateFields[] = "isSynced = 1";
                $updateFields[] = "dtUpdatedAt = NOW()";

                $sql = "UPDATE TbUsers SET " . implode(", ", $updateFields) . " WHERE nUserId = :userId";
                $updateStmt = $conn->prepare($sql);
                $updateStmt->execute($params);

                echo json_encode([
                    "status" => "success",
                    "message" => "User profile updated successfully",
                    "nUserId" => $targetUserId
                ], JSON_UNESCAPED_UNICODE);
            } else {
                // ยังไม่มีในเซิร์ฟเวอร์ -> ทำการ INSERT ผู้ใช้ใหม่ (สมัครสมาชิกใหม่)
                $insertStmt = $conn->prepare("
                    INSERT INTO TbUsers (sEmail, sPasswordHash, sFirstName, sLastName, nAge, nHeight, nWeight, sGender, sActivityLevel, sProfileImagePath, isSynced, dtUpdatedAt, dtCreatedAt)
                    VALUES (:email, :passwordHash, :firstName, :lastName, :age, :height, :weight, :gender, :activityLevel, :profileImagePath, 1, NOW(), NOW())
                ");
                $insertStmt->execute([
                    ':email' => $email,
                    ':passwordHash' => $passwordHash,
                    ':firstName' => $firstName ?: 'ผู้ใช้งาน',
                    ':lastName' => $lastName,
                    ':age' => $age,
                    ':height' => $height,
                    ':weight' => $weight,
                    ':gender' => $gender,
                    ':activityLevel' => $activityLevel,
                    ':profileImagePath' => $profileImagePath
                ]);

                $newUserId = $conn->lastInsertId();

                echo json_encode([
                    "status" => "success",
                    "message" => "User registered and synced successfully",
                    "nUserId" => $newUserId
                ], JSON_UNESCAPED_UNICODE);
            }
        } catch (PDOException $e) {
            echo json_encode([
                "status" => "error",
                "message" => $e->getMessage()
            ]);
        }
        break;

    default:
        http_response_code(405);
        echo json_encode([
            "status" => "error",
            "message" => "Method not allowed"
        ]);
        break;
}
?>

