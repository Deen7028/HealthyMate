<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With, X-App-Key, Accept");
header("Content-Type: application/json; charset=UTF-8");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// =========================================================================
// ป้องกันการเข้าถึงไฟล์ API ตรงๆ ผ่าน Web Browser (Direct Browser Access)
// =========================================================================
$headers = getallheaders();
$normalizedHeaders = [];
foreach ($headers as $key => $val) {
    $normalizedHeaders[strtolower($key)] = $val;
}

$appKey = isset($normalizedHeaders['x-app-key']) ? $normalizedHeaders['x-app-key'] : '';
$userAgent = isset($_SERVER['HTTP_USER_AGENT']) ? $_SERVER['HTTP_USER_AGENT'] : '';

// ตรวจจับเบราว์เซอร์ทั่วไป (Chrome, Firefox, Safari, Edge ฯลฯ) ที่เปิดเข้ามาดู URL ตรงๆ
$isBrowser = preg_match('/(Mozilla|Chrome|Safari|Firefox|Edge|Opera)/i', $userAgent) && !preg_match('/Dart/i', $userAgent);

// ถือว่าเป็นการเข้าตรงๆ หากไม่มี App Key ที่ถูกต้อง และเข้าผ่าน Web Browser
if ($appKey !== 'HealthyMate_Secure_App_2026' && $isBrowser) {
    http_response_code(403);
    echo json_encode([
        "status" => "error",
        "message" => "ไม่อนุญาตให้เข้าถึง API โดยตรง (Direct Access Denied)"
    ], JSON_UNESCAPED_UNICODE);
    exit();
}

// ข้อมูลการเชื่อมต่อฐานข้อมูล MySQL/MariaDB ตามไฟล์ 6620310001_HealthMateDB.sql
$host = "172.18.111.42";   
$port = "3306";
$db_name = "6620310001_HealthMateDB";
$username = "6620310001";
$password = "6620310001";        

try {
    $conn = new PDO("mysql:host={$host};port={$port};dbname={$db_name};charset=utf8mb4", $username, $password, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        PDO::ATTR_EMULATE_PREPARES => false,
    ]);
} catch (PDOException $e) {
    echo json_encode([
        "status" => "error",
        "message" => "Database connection failed: " . $e->getMessage()
    ]);
    exit();
}
?>

