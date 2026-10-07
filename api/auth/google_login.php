<?php
// ส่วนนี้เป็น API endpoint สำหรับเข้าสู่ระบบด้วย Google และเชื่อมข้อมูลผู้ใช้
// คอมเมนท์ภาษาไทยช่วยแยกหน้าที่หลักของไฟล์โดยไม่แก้ logic เดิม

require_once __DIR__ . "/../db_connect.php";

$method = $_SERVER['REQUEST_METHOD'];
if ($method !== 'POST') {
    http_response_code(405);
    echo json_encode(["status" => "error", "message" => "Method not allowed"]);
    exit();
}

$data = json_decode(file_get_contents("php://input"), true);
if (!$data) $data = $_POST;

$email = isset($data['sEmail']) ? trim(strtolower($data['sEmail'])) : '';
$firstName = isset($data['sFirstName']) ? trim($data['sFirstName']) : 'Google User';
$lastName = isset($data['sLastName']) ? trim($data['sLastName']) : '';
$profileImage = isset($data['sProfileImagePath']) ? trim($data['sProfileImagePath']) : '';
$googleId = isset($data['sGoogleId']) ? trim($data['sGoogleId']) : '';

if (empty($email)) {
    echo json_encode(["status" => "error", "message" => "ไม่พบข้อมูลอีเมลจาก Google"], JSON_UNESCAPED_UNICODE);
    exit();
}

try {
    // 1. ค้นหาว่ามีอีเมลนี้ในระบบแล้วหรือไม่
    $stmt = $conn->prepare("SELECT * FROM TbUsers WHERE LOWER(sEmail) = :email LIMIT 1");
    $stmt->execute([':email' => $email]);
    $user = $stmt->fetch();

    if ($user) {
        // มีบัญชีอยู่แล้ว -> อัปเดตรูปโปรไฟล์เผื่อมีการเปลี่ยนแปลง
        if (!empty($profileImage) && $user['sProfileImagePath'] !== $profileImage) {
            // ลบรูปภาพเก่าจากดิสก์เซิร์ฟเวอร์ หากเป็นไฟล์ท้องถิ่นในโฟลเดอร์ uploads/
            $oldImg = $user['sProfileImagePath'] ?? '';
            if (!empty($oldImg) && strpos($oldImg, 'http') !== 0) {
                $oldPath = __DIR__ . '/../' . ltrim($oldImg, '/');
                if (file_exists($oldPath) && is_file($oldPath)) {
                    @unlink($oldPath);
                }
            }

            $updateStmt = $conn->prepare("UPDATE TbUsers SET sProfileImagePath = :img WHERE nUserId = :id");
            $updateStmt->execute([':img' => $profileImage, ':id' => $user['nUserId']]);
            $user['sProfileImagePath'] = $profileImage;
        }
        
        $authToken = generateAuthToken($user['nUserId']);
        $user['token'] = $authToken;

        try {
            $stmtSession = $conn->prepare("
                INSERT INTO tbsession (nUserId, sToken, dtExpiresAt, dtCreatedAt)
                VALUES (:userId, :token, DATE_ADD(NOW(), INTERVAL 30 DAY), NOW())
                ON DUPLICATE KEY UPDATE sToken = VALUES(sToken), dtExpiresAt = VALUES(dtExpiresAt)
            ");
            $stmtSession->execute([
                ':userId' => $user['nUserId'],
                ':token' => $authToken
            ]);
        } catch (Exception $e) {}
        
        echo json_encode([
            "status" => "success",
            "message" => "เข้าสู่ระบบด้วย Google สำเร็จ",
            "token" => $authToken,
            "user" => $user
        ], JSON_UNESCAPED_UNICODE);
    } else {
        // ยังไม่มีบัญชี -> สร้างบัญชีใหม่ให้ทันที (Auto-Registration)
        $dummyPassword = password_hash('GOOGLE_OAUTH_' . bin2hex(random_bytes(8)), PASSWORD_BCRYPT);
        
        $insertStmt = $conn->prepare("
            INSERT INTO TbUsers (sEmail, sPasswordHash, sFirstName, sLastName, sProfileImagePath, isSynced, dtUpdatedAt, dtCreatedAt)
            VALUES (:email, :passwordHash, :firstName, :lastName, :profileImage, 1, NOW(), NOW())
        ");
        $insertStmt->execute([
            ':email' => $email,
            ':passwordHash' => $dummyPassword,
            ':firstName' => $firstName,
            ':lastName' => $lastName,
            ':profileImage' => $profileImage
        ]);

        $newUserId = $conn->lastInsertId();

        // ดึงข้อมูลบัญชีที่เพิ่งสร้างส่งกลับไป
        $stmt->execute([':email' => $email]);
        $newUser = $stmt->fetch();
        $authToken = generateAuthToken($newUser['nUserId']);
        $newUser['token'] = $authToken;

        try {
            $stmtSession = $conn->prepare("
                INSERT INTO tbsession (nUserId, sToken, dtExpiresAt, dtCreatedAt)
                VALUES (:userId, :token, DATE_ADD(NOW(), INTERVAL 30 DAY), NOW())
                ON DUPLICATE KEY UPDATE sToken = VALUES(sToken), dtExpiresAt = VALUES(dtExpiresAt)
            ");
            $stmtSession->execute([
                ':userId' => $newUser['nUserId'],
                ':token' => $authToken
            ]);
        } catch (Exception $e) {}

        echo json_encode([
            "status" => "success",
            "message" => "สร้างบัญชีใหม่ด้วย Google สำเร็จ",
            "token" => $authToken,
            "user" => $newUser
        ], JSON_UNESCAPED_UNICODE);
    }
} catch (PDOException $e) {
    error_log("google_login.php Error: " . $e->getMessage());
    echo json_encode(["status" => "error", "message" => "เกิดข้อผิดพลาดของฐานข้อมูล"], JSON_UNESCAPED_UNICODE);
}
?>