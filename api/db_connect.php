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

// ตรวจสอบ APP_KEY บังคับสำหรับทุก Request ป้องกันการ Bypass
$headers = function_exists('getallheaders') ? getallheaders() : [];
$normalizedHeaders = [];
if (is_array($headers)) {
    foreach ($headers as $key => $val) {
        $normalizedHeaders[strtolower($key)] = $val;
    }
}

// Fallback สำหรับ $_SERVER ใน Serverless Environment (เช่น HTTP_X_APP_KEY)
foreach ($_SERVER as $key => $val) {
    if (strpos($key, 'HTTP_') === 0) {
        $headerName = strtolower(str_replace('_', '-', substr($key, 5)));
        if (!isset($normalizedHeaders[$headerName])) {
            $normalizedHeaders[$headerName] = $val;
        }
    }
}

$expectedAppKey = getenv('APP_KEY') ?: 'HealthyMate_Secure_App_2026';
$appKey = isset($normalizedHeaders['x-app-key']) ? $normalizedHeaders['x-app-key'] : '';

// บังคับเช็ค App Key เสมอ ไม่ว่า User-Agent จะเป็นอะไรก็ตาม
if ($appKey !== $expectedAppKey) {
    http_response_code(403);
    echo json_encode([
        "status" => "error",
        "message" => "ไม่อนุญาตให้เข้าถึง API (Access Denied: Invalid APP_KEY)"
    ], JSON_UNESCAPED_UNICODE);
    exit();
}

/**
 * สร้าง Auth Token สำหรับยืนยันตัวตน User
 */
function generateAuthToken(int|string $userId) {
    global $expectedAppKey;
    $payload = $userId . ':' . time();
    $sig = hash_hmac('sha256', $payload, $expectedAppKey);
    return base64_encode($payload . ':' . $sig);
}

/**
 * ดึงและยืนยัน userId จาก Bearer Token ใน Authorization Header
 */
function getAuthenticatedUserId() {
    global $expectedAppKey;
    $headers = getallheaders();
    $authHeader = '';
    foreach ($headers as $key => $val) {
        if (strtolower($key) === 'authorization') {
            $authHeader = $val;
            break;
        }
    }
    if (empty($authHeader) && isset($_SERVER['HTTP_AUTHORIZATION'])) {
        $authHeader = $_SERVER['HTTP_AUTHORIZATION'];
    }
    if (preg_match('/Bearer\s+(.*)$/i', $authHeader, $matches)) {
        $token = trim($matches[1]);
        $decoded = base64_decode($token);
        if ($decoded) {
            $parts = explode(':', $decoded);
            if (count($parts) === 3) {
                list($userId, $timestamp, $sig) = $parts;
                $expectedSig = hash_hmac('sha256', $userId . ':' . $timestamp, $expectedAppKey);
                if (hash_equals($expectedSig, $sig)) {
                    // ตรวจสอบเวลาหมดอายุของ Token (30 วัน = 2592000 วินาที)
                    if (time() - (int)$timestamp > 2592000) {
                        return null; // Token Expired
                    }
                    return (int)$userId;
                }
            }
        }
    }
    return null;
}

/**
 * บังคับ Authentication ผ่าน Bearer Token หากพบปัญหาให้ Return 401 Unauthorized ทันที
 * ป้องกันช่องโหว่ IDOR และ Token Bypass
 */
function requireAuth(): int {
    $userId = getAuthenticatedUserId();
    if ($userId === null) {
        http_response_code(401);
        echo json_encode([
            "status" => "error",
            "message" => "Unauthenticated: Token ไม่ถูกต้อง หรือหมดอายุ (Access Denied)"
        ], JSON_UNESCAPED_UNICODE);
        exit();
    }
    return $userId;
}


$host = getenv('DB_HOST') ?: "127.0.0.1";   
$port = getenv('DB_PORT') ?: "3306";
$db_name = getenv('DB_NAME') ?: "HealthyMate";
$username = getenv('DB_USER') ?: "root";
$password = getenv('DB_PASS') ?: "";        

$options = [
    PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
    PDO::ATTR_EMULATE_PREPARES => false,
];

// รองรับ SSL สำหรับ Aiven MySQL / Cloud Databases
$caCertPath = __DIR__ . '/ca.pem';
if (file_exists($caCertPath)) {
    $options[PDO::MYSQL_ATTR_SSL_CA] = $caCertPath;
} elseif (getenv('DB_SSL_CA')) {
    // รองรับการส่ง CA Cert ผ่าน Environment Variable
    $tempCa = sys_get_temp_dir() . '/aiven_ca.pem';
    if (!file_exists($tempCa)) {
        file_put_contents($tempCa, getenv('DB_SSL_CA'));
    }
    $options[PDO::MYSQL_ATTR_SSL_CA] = $tempCa;
}

try {
    $conn = new PDO("mysql:host={$host};port={$port};dbname={$db_name};charset=utf8mb4", $username, $password, $options);
} catch (PDOException $e) {
    error_log("db_connect.php Connection error: " . $e->getMessage());
    echo json_encode([
        "status" => "error",
        "message" => "เกิดข้อผิดพลาดในการเชื่อมต่อฐานข้อมูลระบบ: " . $e->getMessage()
    ], JSON_UNESCAPED_UNICODE);
    exit();
}
?>

