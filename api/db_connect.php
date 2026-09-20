<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With");
header("Content-Type: application/json; charset=UTF-8");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// ข้อมูลการเชื่อมต่อฐานข้อมูล MySQL/MariaDB ตามไฟล์ 6620310001_HealthMateDB.sql
$host = "172.18.115.39";   // หรือ "localhost" / IP ของ Database Server
$port = "3306";
$db_name = "6620310001_HealthMateDB";
$username = "6620310001";       // ปรับตาม Username ของคุณ
$password = "6620310001";           // ปรับตาม Password ของคุณ

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

