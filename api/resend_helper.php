<?php
/**
 * ฟังก์ชันสำหรับส่งอีเมลผ่าน Resend HTTPS API (Port 443)
 * แก้ปัญหา Cloud / PaaS เช่น Render บล็อก Outbound SMTP Ports (25, 465, 587)
 */
function sendEmailViaResend(string $toEmail, string $subject, string $htmlContent, string &$errorMessage = ''): bool {
    $apiKey = getenv('RESEND_API_KEY');
    if (empty($apiKey)) {
        return false;
    }

    $fromEmail = getenv('RESEND_FROM_EMAIL') ?: 'HealthyMate <onboarding@resend.dev>';
    $replyTo = getenv('SMTP_USER') ?: 'kamaruding7028@gmail.com';

    // แปลง HTML เป็น Plain Text สละสลวย เพื่อส่งคู่กันแบบ Multipart (ลดคะแนน Spam Score ใน Gmail)
    $plainText = strip_tags(str_replace(['<br>', '</div>', '</p>', '</h2>'], "\n", $htmlContent));
    $plainText = preg_replace("/\n\s+\n/", "\n\n", trim($plainText));

    $postData = [
        'from'     => $fromEmail,
        'to'       => [$toEmail],
        'reply_to' => $replyTo,
        'subject'  => $subject,
        'html'     => $htmlContent,
        'text'     => $plainText,
        'headers'  => [
            'X-Entity-Ref-ID' => uniqid('hm_', true),
            'List-Unsubscribe' => '<mailto:' . $replyTo . '?subject=unsubscribe>',
        ]
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
