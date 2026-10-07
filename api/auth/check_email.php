<?php
// ส่วนนี้เป็น API endpoint สำหรับตรวจสอบว่าอีเมลมีอยู่ในระบบหรือไม่
// คอมเมนท์ภาษาไทยช่วยแยกหน้าที่หลักของไฟล์โดยไม่แก้ logic เดิม

require_once __DIR__ . "/../db_connect.php";

$method = $_SERVER['REQUEST_METHOD'];

if ($method !== 'POST' && $method !== 'GET') {
    http_response_code(405);
    echo json_encode(["status" => "error", "message" => "Method not allowed"]);
    exit();
}

$data = json_decode(file_get_contents("php://input"), true);
if (!$data) $data = $_REQUEST;

$email = isset($data['sEmail']) ? trim(strtolower($data['sEmail'])) : '';

if (empty($email) || !filter_var($email, FILTER_VALIDATE_EMAIL)) {
    echo json_encode(["status" => "error", "message" => "กรุณาระบุอีเมลที่ถูกต้อง"], JSON_UNESCAPED_UNICODE);
    exit();
}

try {
    $stmt = $conn->prepare("SELECT nUserId FROM TbUsers WHERE LOWER(sEmail) = :email LIMIT 1");
    $stmt->execute([':email' => $email]);
    $user = $stmt->fetch();

    if ($user) {
        echo json_encode([
            "status" => "exists",
            "exists" => true,
            "message" => "อีเมลนี้ถูกลงทะเบียนไว้ในระบบแล้ว"
        ], JSON_UNESCAPED_UNICODE);
    } else {
        echo json_encode([
            "status" => "available",
            "exists" => false,
            "message" => "อีเมลนี้สามารถใช้งานได้"
        ], JSON_UNESCAPED_UNICODE);
    }
} catch (PDOException $e) {
    error_log("check_email.php Error: " . $e->getMessage());
    echo json_encode(["status" => "error", "message" => "เกิดข้อผิดพลาดของฐานข้อมูล"], JSON_UNESCAPED_UNICODE);
}
?>
