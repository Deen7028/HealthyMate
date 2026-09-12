<?php
require_once "db_connect.php";

$method = $_SERVER['REQUEST_METHOD'];

switch ($method) {
    // 1. GET: ดึงรายการประวัติการคำนวณทั้งหมด
    case 'GET':
        $userId = isset($_GET['nUserId']) ? intval($_GET['nUserId']) : 1;

        try {
            $stmt = $conn->prepare("SELECT * FROM TbHealthRecords WHERE nUserId = :userId ORDER BY dtRecordedAt DESC");
            $stmt->execute([':userId' => $userId]);
            $records = $stmt->fetchAll();

            echo json_encode([
                "status" => "success",
                "data" => $records
            ], JSON_UNESCAPED_UNICODE);
        } catch (PDOException $e) {
            echo json_encode([
                "status" => "error",
                "message" => $e->getMessage()
            ]);
        }
        break;

    // 2. POST: บันทึกข้อมูลสุขภาพใหม่ลง TbHealthRecords
    case 'POST':
        $data = json_decode(file_get_contents("php://input"), true);

        if (!$data) {
            $data = $_POST;
        }

        $userId = isset($data['nUserId']) ? intval($data['nUserId']) : 1;
        $weight = isset($data['nWeight']) ? floatval($data['nWeight']) : null;
        $height = isset($data['nHeight']) ? floatval($data['nHeight']) : null;
        $bmi = isset($data['nBmi']) ? floatval($data['nBmi']) : null;
        $tdee = isset($data['nTdee']) ? floatval($data['nTdee']) : null;
        $recordedAt = isset($data['dtRecordedAt']) ? $data['dtRecordedAt'] : date('Y-m-d H:i:s');

        if ($weight === null || $height === null) {
            echo json_encode([
                "status" => "error",
                "message" => "Missing required fields (nWeight, nHeight)"
            ]);
            exit();
        }

        try {
            $stmt = $conn->prepare("
                INSERT INTO TbHealthRecords (nUserId, nWeight, nHeight, nBmi, nTdee, dtRecordedAt)
                VALUES (:userId, :weight, :height, :bmi, :tdee, :recordedAt)
            ");
            $stmt->execute([
                ':userId' => $userId,
                ':weight' => $weight,
                ':height' => $height,
                ':bmi' => $bmi,
                ':tdee' => $tdee,
                ':recordedAt' => $recordedAt
            ]);

            $newRecordId = $conn->lastInsertId();

            echo json_encode([
                "status" => "success",
                "message" => "Health record saved successfully",
                "nRecordId" => $newRecordId
            ], JSON_UNESCAPED_UNICODE);
        } catch (PDOException $e) {
            echo json_encode([
                "status" => "error",
                "message" => $e->getMessage()
            ]);
        }
        break;

    // 3. DELETE: ลบประวัติการคำนวณตาม nRecordId
    case 'DELETE':
        $recordId = isset($_GET['nRecordId']) ? intval($_GET['nRecordId']) : null;

        if (!$recordId) {
            $data = json_decode(file_get_contents("php://input"), true);
            $recordId = isset($data['nRecordId']) ? intval($data['nRecordId']) : null;
        }

        if (!$recordId) {
            echo json_encode([
                "status" => "error",
                "message" => "Missing nRecordId"
            ]);
            exit();
        }

        try {
            $stmt = $conn->prepare("DELETE FROM TbHealthRecords WHERE nRecordId = :recordId");
            $stmt->execute([':recordId' => $recordId]);

            echo json_encode([
                "status" => "success",
                "message" => "Record deleted successfully"
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

