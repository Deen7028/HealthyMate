<?php
require_once "db_connect.php";

$method = $_SERVER['REQUEST_METHOD'];

switch ($method) {

    // 1. GET: ดึงกิจวัตรทั้งหมดของ user + สถานะ log ของวันนี้
    case 'GET':
        require __DIR__ . '/routines_get.php';
        break;

    case 'POST':
        require __DIR__ . '/routines_post.php';
        break;

    case 'PUT':
        require __DIR__ . '/routines_put.php';
        break;

    case 'DELETE':
        require __DIR__ . '/routines_delete.php';
        break;

    default:
        http_response_code(405);
        echo json_encode(["status" => "error", "message" => "Method not allowed"]);
        break;
}
