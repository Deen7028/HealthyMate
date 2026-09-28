<?php
/**
 * ฟังก์ชันสำหรับส่งอีเมลผ่าน Resend HTTPS API (Port 443)
 * แก้ปัญหา Cloud / PaaS เช่น Render บล็อก Outbound SMTP Ports (25, 465, 587)
 */
function sendEmailViaResend($toEmail, $subject, $htmlContent, &$errorMessage = '') {
    $apiKey = getenv('RESEND_API_KEY');
    if (empty($apiKey)) {
        return false;
    }

    $fromEmail = getenv('RESEND_FROM_EMAIL') ?: 'HealthyMate <onboarding@resend.dev>';

    $postData = [
        'from'    => $fromEmail,
        'to'      => [$toEmail],
        'subject' => $subject,
        'html'    => $htmlContent,
    ];

    $ch = curl_init('https://api.resend.com/emails');
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        'Authorization: Bearer ' . trim($apiKey),
        'Content-Type: application/json'
    ]);
    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($postData));
    curl_setopt($ch, CURLOPT_TIMEOUT, 15);

    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $curlError = curl_error($ch);
    curl_close($ch);

    if ($curlError) {
        $errorMessage = "cURL error: " . $curlError;
        return false;
    }

    $resData = json_decode($response, true);
    if ($httpCode >= 200 && $httpCode < 300) {
        return true;
    } else {
        $errMsg = isset($resData['message']) ? $resData['message'] : ($resData['name'] ?? "HTTP $httpCode");
        $errorMessage = "Resend API Error: " . $errMsg;
        return false;
    }
}
