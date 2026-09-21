<?php
require_once "db_connect.php";

$method = $_SERVER['REQUEST_METHOD'];

if ($method !== 'POST') {
    http_response_code(405);
    echo json_encode([
        "status" => "error",
        "message" => "Method not allowed"
    ]);
    exit();
}

// รับข้อมูล JSON หรือ POST Body
$data = json_decode(file_get_contents("php://input"), true);
if (!$data) {
    $data = $_POST;
}

$email = isset($data['sEmail']) ? trim(strtolower($data['sEmail'])) : '';
$password = isset($data['sPassword']) ? $data['sPassword'] : '';
$passwordHash = isset($data['sPasswordHash']) ? trim($data['sPasswordHash']) : '';

if (empty($email) || (empty($password) && empty($passwordHash))) {
    echo json_encode([
        "status" => "error",
        "message" => "กรุณากรอกอีเมลและรหัสผ่าน"
    ], JSON_UNESCAPED_UNICODE);
    exit();
}

// หากไม่ได้ส่ง passwordHash มา ให้คำนวณด้วย SHA-256
if (empty($passwordHash)) {
    $passwordHash = hash('sha256', $password);
}

try {
    // 1. ค้นหาผู้ใช้จากตาราง TbUsers บน MySQL Server
    $stmt = $conn->prepare("
        SELECT nUserId, sEmail, sPasswordHash, sFirstName, sLastName, 
               nAge, nHeight, nWeight, sGender, sActivityLevel, 
               isDarkMode, sProfileImagePath, dtCreatedAt
        FROM TbUsers 
        WHERE LOWER(sEmail) = :email 
        LIMIT 1
    ");
    $stmt->execute([':email' => $email]);
    $user = $stmt->fetch();

    if (!$user) {
        echo json_encode([
            "status" => "not_found",
            "message" => "ไม่พบบัญชีผู้ใช้นี้ในระบบ กรุณาตรวจสอบอีเมลหรือสมัครสมาชิก"
        ], JSON_UNESCAPED_UNICODE);
        exit();
    }

    // 2. ตรวจสอบความถูกต้องของรหัสผ่าน
    $storedHash = $user['sPasswordHash'];
    $isValidPassword = ($storedHash === $passwordHash) || (!empty($password) && $storedHash === $password);

    if (!$isValidPassword) {
        echo json_encode([
            "status" => "invalid_password",
            "message" => "รหัสผ่านไม่ถูกต้อง กรุณาลองใหม่อีกครั้ง"
        ], JSON_UNESCAPED_UNICODE);
        exit();
    }

    // 3. เข้าสู่ระบบสำเร็จ -> ส่งข้อมูลผู้ใช้กลับไปให้แอปเพื่อ Hydrate ลง SQLite
    echo json_encode([
        "status" => "success",
        "message" => "เข้าสู่ระบบสำเร็จ",
        "user" => $user
    ], JSON_UNESCAPED_UNICODE);

} catch (PDOException $e) {
    echo json_encode([
        "status" => "error",
        "message" => "Database error: " . $e->getMessage()
    ]);
}
?>
