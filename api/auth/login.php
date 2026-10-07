<?php
// ส่วนนี้เป็น API endpoint สำหรับตรวจสอบอีเมลและรหัสผ่านสำหรับเข้าสู่ระบบ
// คอมเมนท์ภาษาไทยช่วยแยกหน้าที่หลักของไฟล์โดยไม่แก้ logic เดิม

require_once __DIR__ . "/../db_connect.php";

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

if (empty($email) || empty($password)) {
    echo json_encode([
        "status" => "error",
        "message" => "กรุณากรอกอีเมลและรหัสผ่าน"
    ], JSON_UNESCAPED_UNICODE);
    exit();
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

    // 2. ตรวจสอบความถูกต้องของรหัสผ่าน (ใช้ password_verify หรือ Upgrade จาก Legacy Hash)
    $storedHash = $user['sPasswordHash'];
    $isValidPassword = false;

    if (password_verify($password, $storedHash)) {
        $isValidPassword = true;
    } elseif (password_verify(hash('sha256', $password), $storedHash)) {
        $isValidPassword = true;
        $newHash = password_hash($password, PASSWORD_DEFAULT);
        $rehashStmt = $conn->prepare("UPDATE TbUsers SET sPasswordHash = :h WHERE nUserId = :id");
        $rehashStmt->execute([':h' => $newHash, ':id' => $user['nUserId']]);
        $user['sPasswordHash'] = $newHash;
    } elseif ($storedHash === hash('sha256', $password) || $storedHash === $password) {
        $isValidPassword = true;
        // Re-hash เป็น BCRYPT มาตรฐานเพื่อความปลอดภัยในอนาคต
        $newHash = password_hash($password, PASSWORD_DEFAULT);
        $rehashStmt = $conn->prepare("UPDATE TbUsers SET sPasswordHash = :h WHERE nUserId = :id");
        $rehashStmt->execute([':h' => $newHash, ':id' => $user['nUserId']]);
        $user['sPasswordHash'] = $newHash;
    }

    if (!$isValidPassword) {
        echo json_encode([
            "status" => "invalid_password",
            "message" => "รหัสผ่านไม่ถูกต้อง กรุณาลองใหม่อีกครั้ง"
        ], JSON_UNESCAPED_UNICODE);
        exit();
    }

    // 3. เข้าสู่ระบบสำเร็จ -> สร้าง Auth Token และส่งข้อมูลผู้ใช้กลับ
    $authToken = generateAuthToken($user['nUserId']);
    $user['token'] = $authToken;

    // บันทึก Session ลง tbsession บน Database Server
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
    } catch (Exception $e) {
        error_log("Failed to insert tbsession: " . $e->getMessage());
    }

    echo json_encode([
        "status" => "success",
        "message" => "เข้าสู่ระบบสำเร็จ",
        "token" => $authToken,
        "user" => $user
    ], JSON_UNESCAPED_UNICODE);

} catch (PDOException $e) {
    error_log("login.php PDOError: " . $e->getMessage());
    echo json_encode([
        "status" => "error",
        "message" => "เกิดข้อผิดพลาดในการเชื่อมต่อฐานข้อมูลระบบ"
    ], JSON_UNESCAPED_UNICODE);
}
?>
