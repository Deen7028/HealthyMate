<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With, X-App-Key, Accept");
header("Content-Type: application/json; charset=UTF-8");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// โหลดไฟล์ .env สำหรับ PHP Backend (ดึงจาก Root Project .env หรือ api/.env)
$envFile = file_exists(__DIR__ . '/../.env') ? __DIR__ . '/../.env' : __DIR__ . '/.env';
if (file_exists($envFile)) {
    $lines = file($envFile, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
    foreach ($lines as $line) {
        $line = trim($line);
        if (empty($line) || strpos($line, '#') === 0) continue;
        if (strpos($line, '=') !== false) {
            list($key, $val) = explode('=', $line, 2);
            $key = trim($key);
            $val = trim($val, "\"' \t\n\r\0\x0B");
            putenv("$key=$val");
            $_ENV[$key] = $val;
            $_SERVER[$key] = $val;
        }
    }
}

// ป้องกันการเข้าถึงไฟล์ API ตรงๆ ผ่าน Web Browser (Direct Browser Access)
$headers = getallheaders();
$normalizedHeaders = [];
foreach ($headers as $key => $val) {
    $normalizedHeaders[strtolower($key)] = $val;
}

$expectedAppKey = getenv('APP_KEY') ?: 'HealthyMate_Secure_App_2026';
$appKey = isset($normalizedHeaders['x-app-key']) ? $normalizedHeaders['x-app-key'] : '';
$userAgent = isset($_SERVER['HTTP_USER_AGENT']) ? $_SERVER['HTTP_USER_AGENT'] : '';

// ตรวจจับเบราว์เซอร์ทั่วไป (Chrome, Firefox, Safari, Edge ฯลฯ) ที่เปิดเข้ามาดู URL ตรงๆ
$isBrowser = preg_match('/(Mozilla|Chrome|Safari|Firefox|Edge|Opera)/i', $userAgent) && !preg_match('/Dart/i', $userAgent);

// ถือว่าเป็นการเข้าตรงๆ หากไม่มี App Key ที่ถูกต้อง และเข้าผ่าน Web Browser
if ($appKey !== $expectedAppKey && $isBrowser) {
    http_response_code(403);
    echo json_encode([
        "status" => "error",
        "message" => "ไม่อนุญาตให้เข้าถึง API โดยตรง (Direct Access Denied)"
    ], JSON_UNESCAPED_UNICODE);
    exit();
}


$host = getenv('DB_HOST') ?: "172.18.111.42";   
$port = getenv('DB_PORT') ?: "3306";
$db_name = getenv('DB_NAME') ?: "6620310001_HealthMateDB";
$username = getenv('DB_USER') ?: "6620310001";
$password = getenv('DB_PASS') ?: "6620310001";        

try {
    $conn = new PDO("mysql:host={$host};port={$port};dbname={$db_name};charset=utf8mb4", $username, $password, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        PDO::ATTR_EMULATE_PREPARES => false,
    ]);
} catch (PDOException $e) {
    error_log("db_connect.php Connection error: " . $e->getMessage());
    echo json_encode([
        "status" => "error",
        "message" => "เกิดข้อผิดพลาดในการเชื่อมต่อฐานข้อมูลระบบ"
    ], JSON_UNESCAPED_UNICODE);
    exit();
}
?>

