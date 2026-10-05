<?php
// ส่วนนี้เป็น API endpoint สำหรับตรวจสอบรหัส OTP ของอีเมล
// คอมเมนท์ภาษาไทยช่วยแยกหน้าที่หลักของไฟล์โดยไม่แก้ logic เดิม

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
$otpCode = isset($data['sOtpCode']) ? trim($data['sOtpCode']) : '';

if (empty($email) || empty($otpCode)) {
    echo json_encode(["status" => "error", "message" => "กรุณาระบุอีเมลและรหัส OTP"], JSON_UNESCAPED_UNICODE);
    exit();
}

try {
    // 1. ค้นหารหัส OTP ล่าสุดที่ยังไม่ถูกใช้ และยังไม่หมดอายุ
    $stmt = $conn->prepare("
        SELECT * FROM TbEmailOtps 
        WHERE sEmail = :email AND isUsed = 0 AND dtExpiresAt >= NOW()
        ORDER BY nOtpId DESC LIMIT 1
    ");
    $stmt->execute([':email' => $email]);
    $otpRecord = $stmt->fetch();

    if (!$otpRecord) {
        echo json_encode([
            "status" => "invalid",
            "message" => "รหัส OTP หมดอายุหรือไม่ถูกต้อง กรุณากดขอรหัสใหม่"
        ], JSON_UNESCAPED_UNICODE);
        exit();
    }

    // 2. ป้องกัน Brute Force: หากกรอกผิดเกิน 5 ครั้ง ให้ยกเลิกรหัสทันที
    if (intval($otpRecord['nAttempts']) >= 5) {
        $stmtCancel = $conn->prepare("UPDATE TbEmailOtps SET isUsed = 1 WHERE nOtpId = :id");
        $stmtCancel->execute([':id' => $otpRecord['nOtpId']]);

        echo json_encode([
            "status" => "locked",
            "message" => "คุณกรอกรหัสผิดเกิน 5 ครั้ง กรุณากดขอรหัสใหม่"
        ], JSON_UNESCAPED_UNICODE);
        exit();
    }

    // 3. ตรวจสอบความถูกต้องของรหัส
    if ($otpRecord['sOtpCode'] === $otpCode) {
        // ถูกต้อง -> อัปเดตสถานะเป็นใช้งานแล้ว (isUsed = 1)
        $stmtSuccess = $conn->prepare("UPDATE TbEmailOtps SET isUsed = 1 WHERE nOtpId = :id");
        $stmtSuccess->execute([':id' => $otpRecord['nOtpId']]);

        echo json_encode([
            "status" => "success",
            "message" => "ยืนยันรหัส OTP สำเร็จ"
        ], JSON_UNESCAPED_UNICODE);
    } else {
        // รหัสผิด -> บวกจำนวน nAttempts เพิ่ม 1
        $stmtFail = $conn->prepare("UPDATE TbEmailOtps SET nAttempts = nAttempts + 1 WHERE nOtpId = :id");
        $stmtFail->execute([':id' => $otpRecord['nOtpId']]);

        $nRemaining = 5 - (intval($otpRecord['nAttempts']) + 1);
        echo json_encode([
            "status" => "incorrect",
            "message" => "รหัส OTP ไม่ถูกต้อง (เหลือโอกาสอีก $nRemaining ครั้ง)"
        ], JSON_UNESCAPED_UNICODE);
    }

} catch (PDOException $e) {
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}
?>