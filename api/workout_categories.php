<?php
require_once "db_connect.php";

$method = $_SERVER['REQUEST_METHOD'];

switch ($method) {
    case 'GET':
        try {
            $stmt = $conn->query("SELECT * FROM TbWorkoutCategories ORDER BY nCategoryId ASC");
            $categories = $stmt->fetchAll();

            echo json_encode([
                "status" => "success",
                "data" => $categories
            ], JSON_UNESCAPED_UNICODE);
        } catch (PDOException $e) {
            echo json_encode([
                "status" => "error",
                "message" => $e->getMessage()
            ]);
        }
        break;

    default:
        http_response_code(405);
        echo json_encode([
            "status" => "error",
            "message" => "Method not allowed"
        ]);
        break;
}
?>
