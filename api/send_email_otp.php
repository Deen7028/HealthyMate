<?php
require_once "db_connect.php";

use PHPMailer\PHPMailer\PHPMailer;
use PHPMailer\PHPMailer\Exception;

// นำเข้าไฟล์ PHPMailer หากมีติดตั้งไว้ (Composer หรือ โฟลเดอร์ PHPMailer)
$hasPHPMailer = false;
if (file_exists(__DIR__ . '/vendor/autoload.php')) {
    require_once __DIR__ . '/vendor/autoload.php';
    $hasPHPMailer = class_exists('PHPMailer\PHPMailer\PHPMailer');
} elseif (file_exists(__DIR__ . '/PHPMailer/src/PHPMailer.php')) {
    require_once __DIR__ . '/PHPMailer/src/Exception.php';
    require_once __DIR__ . '/PHPMailer/src/PHPMailer.php';
    require_once __DIR__ . '/PHPMailer/src/SMTP.php';
    $hasPHPMailer = class_exists('PHPMailer\PHPMailer\PHPMailer');
}

$method = $_SERVER['REQUEST_METHOD'];

if ($method !== 'POST') {
    http_response_code(405);
    echo json_encode(["status" => "error", "message" => "Method not allowed"]);
    exit();
}

$data = json_decode(file_get_contents("php://input"), true);
if (!$data) $data = $_POST;

$email = isset($data['sEmail']) ? trim(strtolower($data['sEmail'])) : '';

if (empty($email) || !filter_var($email, FILTER_VALIDATE_EMAIL)) {
    echo json_encode(["status" => "error", "message" => "กรุณากรอกอีเมลที่ถูกต้อง"], JSON_UNESCAPED_UNICODE);
    exit();
}

try {
    $clientIp = $_SERVER['HTTP_CLIENT_IP'] ?? $_SERVER['HTTP_X_FORWARDED_FOR'] ?? $_SERVER['REMOTE_ADDR'] ?? '0.0.0.0';
    if (strpos($clientIp, ',') !== false) {
        $clientIp = trim(explode(',', $clientIp)[0]);
    }

    // 1. ตรวจสอบ Rate Limit รายบุคคล (ห้ามขอ OTP ซ้ำในอีเมลเดิมภายใน 60 วินาที)
    $stmtCheck = $conn->prepare("
        SELECT dtCreatedAt FROM TbEmailOtps 
        WHERE sEmail = :email AND dtCreatedAt > DATE_SUB(NOW(), INTERVAL 60 SECOND)
        ORDER BY nOtpId DESC LIMIT 1
    ");
    $stmtCheck->execute([':email' => $email]);
    if ($stmtCheck->fetch()) {
        echo json_encode([
            "status" => "rate_limited",
            "message" => "กรุณารอ 60 วินาทีก่อนกดขอรหัส OTP ใหม่อีกครั้ง"
        ], JSON_UNESCAPED_UNICODE);
        exit();
    }

    // 2. ตรวจสอบ Rate Limit ป้องกัน Spam / Email Bombing ตาม IP (สูงสุดไม่เกิน 5 ครั้ง ต่อ 10 นาที)
    try {
        $conn->exec("ALTER TABLE TbEmailOtps ADD COLUMN sIpAddress VARCHAR(45) DEFAULT NULL");
    } catch (\Throwable $e) {
        // มี column sIpAddress อยู่แล้ว
    }

    $stmtIpCheck = $conn->prepare("
        SELECT COUNT(*) as cnt FROM TbEmailOtps 
        WHERE sIpAddress = :ip AND dtCreatedAt > DATE_SUB(NOW(), INTERVAL 10 MINUTE)
    ");
    $stmtIpCheck->execute([':ip' => $clientIp]);
    $ipReqCount = intval($stmtIpCheck->fetch()['cnt'] ?? 0);
    if ($ipReqCount >= 5) {
        echo json_encode([
            "status" => "rate_limited",
            "message" => "มีการขอ OTP จาก IP ของคุณถี่เกินไป (จำกัดไม่เกิน 5 ครั้ง ต่อ 10 นาที)"
        ], JSON_UNESCAPED_UNICODE);
        exit();
    }

    // 3. ยกเลิก (Invalidate) รหัสเดิมที่ยังไม่หมดอายุของอีเมลนี้
    $stmtExpireOld = $conn->prepare("
        UPDATE TbEmailOtps SET isUsed = 1 
        WHERE sEmail = :email AND isUsed = 0
    ");
    $stmtExpireOld->execute([':email' => $email]);

    // 4. สุ่มรหัส OTP 6 หลัก และกำหนดวันหมดอายุ (5 นาที)
    $otpCode = str_pad(strval(random_int(100000, 999999)), 6, '0', STR_PAD_LEFT);
    $expiresAt = date('Y-m-d H:i:s', strtotime('+5 minutes'));

    // 5. บันทึกรหัส OTP ลงตาราง TbEmailOtps พร้อมบันทึก IP
    $stmtInsert = $conn->prepare("
        INSERT INTO TbEmailOtps (sEmail, sOtpCode, isUsed, dtExpiresAt, dtCreatedAt, sIpAddress)
        VALUES (:email, :otp, 0, :expires, NOW(), :ip)
    ");
    $stmtInsert->execute([
        ':email' => $email,
        ':otp' => $otpCode,
        ':expires' => $expiresAt,
        ':ip' => $clientIp
    ]);

    // 5. ส่งอีเมลผ่าน PHPMailer (Gmail SMTP) หรือ PHP mail() fallback
    $htmlBody = "
        <div style='font-family: Arial, sans-serif; background-color: #F4F8F3; padding: 24px;'>
            <div style='max-width: 480px; margin: auto; background-color: #ffffff; padding: 32px; border-radius: 16px; box-shadow: 0 4px 12px rgba(0,0,0,0.06);'>
                <h2 style='color: #2E5327; margin-bottom: 8px;'>ยืนยันที่อยู่อีเมลของคุณ</h2>
                <p style='color: #555555; font-size: 14px;'>ขอบคุณที่สมัครใช้งาน HealthyMate กรุณาใช้รหัสยืนยันตัวตนด้านล่างนี้เพื่อดำเนินการสมัครสมาชิกให้เสร็จสมบูรณ์:</p>
                <div style='text-align: center; margin: 24px 0;'>
                    <span style='display: inline-block; font-size: 32px; font-weight: 800; color: #2E5327; letter-spacing: 6px; background-color: #EBF3EA; padding: 12px 24px; border-radius: 12px;'>$otpCode</span>
                </div>
                <p style='color: #888888; font-size: 12.5px; text-align: center;'>รหัสนี้มีอายุการใช้งาน 5 นาที (ห้ามเปิดเผยรหัสนี้แก่ผู้อื่น)</p>
            </div>
        </div>
    ";

    $isSent = false;
    $errorMessage = '';

    if ($hasPHPMailer) {
        $mailClass = '\PHPMailer\PHPMailer\PHPMailer';
        $mail = new $mailClass(true);
        try {
            $mail->isSMTP();
            $mail->Host       = getenv('SMTP_HOST') ?: 'smtp.gmail.com';
            $mail->SMTPAuth   = true;
            $mail->Username   = getenv('SMTP_USER') ?: 'kamaruding7028@gmail.com';
            $mail->Password   = getenv('SMTP_PASS') ?: 'mhpg aeqh plii ptas';
            $mail->SMTPSecure = 'tls';
            $mail->Port       = (int)(getenv('SMTP_PORT') ?: 587);
            $mail->CharSet    = 'UTF-8';

            $mail->setFrom('noreply.healthymate@gmail.com', 'HealthyMate');
            $mail->addAddress($email);

            $mail->isHTML(true);
            $mail->Subject = "รหัสยืนยันการลงทะเบียน HealthyMate: $otpCode";
            $mail->Body    = $htmlBody;

            $mail->send();
            $isSent = true;
        } catch (\Throwable $e) {
            $errorMessage = isset($mail) && isset($mail->ErrorInfo) ? $mail->ErrorInfo : $e->getMessage();
        }
    } else {
        // Fallback ใช้ mail() มาตรฐานของ PHP หากไม่มี PHPMailer ในเครื่อง
        $subject = "=?UTF-8?B?" . base64_encode("รหัสยืนยันการลงทะเบียน HealthyMate: $otpCode") . "?=";
        $headers = "MIME-Version: 1.0\r\n";
        $headers .= "Content-type: text/html; charset=UTF-8\r\n";
        $headers .= "From: HealthyMate <noreply.healthymate@gmail.com>\r\n";
        $headers .= "X-Mailer: PHP/" . phpversion();

        $isSent = @mail($email, $subject, $htmlBody, $headers);
        if (!$isSent) {
            $errorMessage = 'ระบบส่งอีเมลพื้นฐานยังไม่พร้อมใช้งาน กรุณาติดตั้ง PHPMailer หรือตรวจสอบการตั้งค่า SMTP';
        }
    }

    if ($isSent) {
        echo json_encode([
            "status" => "success",
            "message" => "ส่งรหัส OTP ไปยังอีเมลเรียบร้อยแล้ว"
        ], JSON_UNESCAPED_UNICODE);
    } else {
        echo json_encode([
            "status" => "error",
            "message" => "ไม่สามารถส่งอีเมลได้ กรุณาลองใหม่อีกครั้ง"
        ], JSON_UNESCAPED_UNICODE);
    }

} catch (PDOException $e) {
    error_log("send_email_otp.php Error: " . $e->getMessage());
    echo json_encode(["status" => "error", "message" => "เกิดข้อผิดพลาดในการเชื่อมต่อฐานข้อมูลระบบ"], JSON_UNESCAPED_UNICODE);
} catch (\Throwable $e) {
    error_log("send_email_otp.php Throwable: " . $e->getMessage());
    echo json_encode(["status" => "error", "message" => "เกิดข้อผิดพลาดในระบบ"], JSON_UNESCAPED_UNICODE);
}
?>