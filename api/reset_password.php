<?php
require_once "db_connect.php";

$method = $_SERVER['REQUEST_METHOD'];
if ($method !== 'POST') {
    http_response_code(405);
    echo json_encode(["status" => "error", "message" => "Method not allowed"]);
    exit();
}

$data = json_decode(file_get_contents("php://input"), true);
if (!$data) $data = $_POST;

$email = isset($data['sEmail']) ? trim(strtolower($data['sEmail'])) : '';
$newPassword = isset($data['sNewPassword']) ? $data['sNewPassword'] : '';

if (empty($email) || empty($newPassword)) {
    echo json_encode(["status" => "error", "message" => "ข้อมูลไม่ครบถ้วน"], JSON_UNESCAPED_UNICODE);
    exit();
}

try {
    // แฮชรหัสผ่านใหม่ด้วย BCRYPT (Best Practice)
    $passwordHash = password_hash($newPassword, PASSWORD_BCRYPT);

    $stmt = $conn->prepare("UPDATE TbUsers SET sPasswordHash = :hash, dtUpdatedAt = NOW(), isSynced = 1 WHERE LOWER(sEmail) = :email");
    $stmt->execute([
        ':hash' => $passwordHash,
        ':email' => $email
    ]);

    if ($stmt->rowCount() > 0) {
        echo json_encode(["status" => "success", "message" => "เปลี่ยนรหัสผ่านสำเร็จ"], JSON_UNESCAPED_UNICODE);
    } else {
        echo json_encode(["status" => "error", "message" => "เปลี่ยนรหัสผ่านไม่สำเร็จ หรือรหัสผ่านเหมือนเดิม"], JSON_UNESCAPED_UNICODE);
    }
} catch (PDOException $e) {
    error_log("reset_password.php Error: " . $e->getMessage());
    echo json_encode(["status" => "error", "message" => "เกิดข้อผิดพลาดในการอัปเดตฐานข้อมูล"], JSON_UNESCAPED_UNICODE);
}
?>