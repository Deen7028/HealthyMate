<?php
require_once "db_connect.php";

// นำเข้า PHPMailer
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
    // 1. ตรวจสอบว่ามีอีเมลนี้ในระบบหรือไม่ (สำคัญมากสำหรับ Forgot Password)
    $stmtUser = $conn->prepare("SELECT nUserId FROM TbUsers WHERE LOWER(sEmail) = :email LIMIT 1");
    $stmtUser->execute([':email' => $email]);
    if (!$stmtUser->fetch()) {
        echo json_encode(["status" => "not_found", "message" => "ไม่พบบัญชีผู้ใช้งานนี้ในระบบ"], JSON_UNESCAPED_UNICODE);
        exit();
    }

    // 2. ตรวจสอบ Rate Limit (กันสแปม)
    $stmtCheck = $conn->prepare("SELECT dtCreatedAt FROM TbEmailOtps WHERE sEmail = :email AND dtCreatedAt > DATE_SUB(NOW(), INTERVAL 60 SECOND) ORDER BY nOtpId DESC LIMIT 1");
    $stmtCheck->execute([':email' => $email]);
    if ($stmtCheck->fetch()) {
        echo json_encode(["status" => "rate_limited", "message" => "กรุณารอ 60 วินาทีก่อนขอ OTP ใหม่"], JSON_UNESCAPED_UNICODE);
        exit();
    }

    // 3. ยกเลิกรหัสเดิม และสุ่ม OTP ใหม่
    $conn->prepare("UPDATE TbEmailOtps SET isUsed = 1 WHERE sEmail = :email AND isUsed = 0")->execute([':email' => $email]);
    $otpCode = str_pad(strval(random_int(100000, 999999)), 6, '0', STR_PAD_LEFT);
    $expiresAt = date('Y-m-d H:i:s', strtotime('+5 minutes'));

    $conn->prepare("INSERT INTO TbEmailOtps (sEmail, sOtpCode, isUsed, dtExpiresAt, dtCreatedAt) VALUES (:email, :otp, 0, :expires, NOW())")->execute([
        ':email' => $email, ':otp' => $otpCode, ':expires' => $expiresAt
    ]);

    // 4. ส่งอีเมล
    $htmlBody = "
        <div style='font-family: Arial, sans-serif; background-color: #F4F8F3; padding: 24px;'>
            <div style='max-width: 480px; margin: auto; background-color: #ffffff; padding: 32px; border-radius: 16px; box-shadow: 0 4px 12px rgba(0,0,0,0.06);'>
                <h2 style='color: #2E5327; margin-bottom: 8px;'>รีเซ็ตรหัสผ่าน HealthyMate</h2>
                <p style='color: #555555; font-size: 14px;'>เราได้รับคำขอให้รีเซ็ตรหัสผ่านสำหรับบัญชีของคุณ กรุณาใช้รหัส OTP นี้เพื่อตั้งรหัสผ่านใหม่:</p>
                <div style='text-align: center; margin: 24px 0;'>
                    <span style='display: inline-block; font-size: 32px; font-weight: 800; color: #2E5327; letter-spacing: 6px; background-color: #EBF3EA; padding: 12px 24px; border-radius: 12px;'>$otpCode</span>
                </div>
                <p style='color: #888888; font-size: 12.5px; text-align: center;'>รหัสนี้มีอายุ 5 นาที หากคุณไม่ได้ขอรีเซ็ตรหัสผ่าน โปรดเพิกเฉยต่ออีเมลฉบับนี้</p>
            </div>
        </div>
    ";

    $isSent = false;
    $errorMessage = '';

    // 1. ลองส่งผ่าน Resend REST API ก่อน (HTTPS Port 443 ทำงานได้ 100% บน Render/Cloud)
    require_once __DIR__ . '/resend_helper.php';
    if (getenv('RESEND_API_KEY')) {
        $subject = "รหัสรีเซ็ตรหัสผ่าน HealthyMate: $otpCode";
        $isSent = sendEmailViaResend($email, $subject, $htmlBody, $errorMessage);
    }

    // 2. หากไม่ได้ตั้งค่า Resend หรือส่งไม่ผ่าน ให้ลอง PHPMailer (SMTP)
    if (!$isSent && $hasPHPMailer) {
        try {
            $mailClass = '\PHPMailer\PHPMailer\PHPMailer';
            $mail = new $mailClass(true);
            $smtpUser = getenv('SMTP_USER') ?: 'kamaruding7028@gmail.com';
            $smtpPass = getenv('SMTP_PASS') ?: 'mhpg aeqh plii ptas';

            $mail->isSMTP();
            $smtpHost = getenv('SMTP_HOST') ?: 'smtp.gmail.com';
            $smtpPort = (int)(getenv('SMTP_PORT') ?: 465);
            $mail->Host       = $smtpHost;
            $mail->SMTPAuth   = true;
            $mail->Username   = $smtpUser;
            $mail->Password   = $smtpPass;
            $mail->SMTPSecure = ($smtpPort === 465) ? 'ssl' : 'tls';
            $mail->Port       = $smtpPort;
            $mail->Timeout    = 10;
            $mail->CharSet    = 'UTF-8';
            $mail->SMTPOptions = [
                'ssl' => [
                    'verify_peer' => false,
                    'verify_peer_name' => false,
                    'allow_self_signed' => true
                ]
            ];

            $mail->setFrom($smtpUser, 'HealthyMate');
            $mail->addAddress($email);
            $mail->isHTML(true);
            $mail->Subject = "รหัสรีเซ็ตรหัสผ่าน HealthyMate: $otpCode";
            $mail->Body    = $htmlBody;
            $mail->send();
            $isSent = true;
        } catch (\Throwable $e) {
            $errorMessage = isset($mail) && isset($mail->ErrorInfo) ? $mail->ErrorInfo : $e->getMessage();
        }
    }

    // 3. Fallback ใช้ mail() มาตรฐานของ PHP หากไม่มีตัวเลือกอื่น
    if (!$isSent && !$hasPHPMailer && !getenv('RESEND_API_KEY')) {
        $subject = "=?UTF-8?B?" . base64_encode("รหัสรีเซ็ตรหัสผ่าน HealthyMate: $otpCode") . "?=";
        $headers = "MIME-Version: 1.0\r\n";
        $headers .= "Content-type: text/html; charset=UTF-8\r\n";
        $headers .= "From: HealthyMate <kamaruding7028@gmail.com>\r\n";
        $headers .= "X-Mailer: PHP/" . phpversion();

        $isSent = @mail($email, $subject, $htmlBody, $headers);
        if (!$isSent) {
            $errorMessage = 'ระบบส่งอีเมลพื้นฐานยังไม่พร้อมใช้งาน กรุณาตั้งค่า RESEND_API_KEY หรือ SMTP';
        }
    }

    if ($isSent) {
        echo json_encode(["status" => "success", "message" => "ส่งรหัส OTP สำหรับรีเซ็ตรหัสผ่านแล้ว"], JSON_UNESCAPED_UNICODE);
    } else {
        echo json_encode(["status" => "error", "message" => "ส่งอีเมลไม่สำเร็จ: $errorMessage"], JSON_UNESCAPED_UNICODE);
    }

} catch (\Throwable $e) {
    error_log("send_forgot_password_otp.php Throwable: " . $e->getMessage());
    echo json_encode(["status" => "error", "message" => "เกิดข้อผิดพลาดของระบบ"], JSON_UNESCAPED_UNICODE);
}
?>