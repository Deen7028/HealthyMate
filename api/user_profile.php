<?php
require_once "db_connect.php";

$method = $_SERVER['REQUEST_METHOD'];

switch ($method) {
    // 1. GET: ดึงข้อมูลโปรไฟล์ผู้ใช้จาก TbUsers
    case 'GET':
        $userId = isset($_GET['nUserId']) ? intval($_GET['nUserId']) : 1;

        try {
            $stmt = $conn->prepare("SELECT nUserId, sEmail, sFullName, nAge, nHeight, nWeight, sGender, sActivityLevel, isDarkMode, dtCreatedAt FROM TbUsers WHERE nUserId = :userId");
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

    // 2. POST / PUT: อัปเดตข้อมูลสุขภาพของผู้ใช้ใน TbUsers
    case 'POST':
    case 'PUT':
        $data = json_decode(file_get_contents("php://input"), true);

        if (!$data) {
            $data = $_POST;
        }

        $userId = isset($data['nUserId']) ? intval($data['nUserId']) : 1;
        $age = isset($data['nAge']) ? intval($data['nAge']) : null;
        $height = isset($data['nHeight']) ? floatval($data['nHeight']) : null;
        $weight = isset($data['nWeight']) ? floatval($data['nWeight']) : null;
        $gender = isset($data['sGender']) ? $data['sGender'] : null;
        $activityLevel = isset($data['sActivityLevel']) ? $data['sActivityLevel'] : null;

        try {
            $stmt = $conn->prepare("
                UPDATE TbUsers 
                SET nAge = :age, nHeight = :height, nWeight = :weight, sGender = :gender, sActivityLevel = :activityLevel
                WHERE nUserId = :userId
            ");
            $stmt->execute([
                ':userId' => $userId,
                ':age' => $age,
                ':height' => $height,
                ':weight' => $weight,
                ':gender' => $gender,
                ':activityLevel' => $activityLevel
            ]);

            echo json_encode([
                "status" => "success",
                "message" => "User profile updated successfully"
            ], JSON_UNESCAPED_UNICODE);
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

