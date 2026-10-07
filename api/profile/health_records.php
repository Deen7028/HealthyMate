<?php
// ส่วนนี้เป็น API endpoint สำหรับจัดการประวัติสุขภาพและค่าการคำนวณ

require_once __DIR__ . "/../db_connect.php";

$method = $_SERVER['REQUEST_METHOD'];

switch ($method) {
    // 1. GET: ดึงรายการประวัติการคำนวณทั้งหมด
    case 'GET':
        $userId = requireAuth();

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

        $userId = requireAuth();
        $weight = isset($data['nWeight']) ? floatval($data['nWeight']) : null;
        $height = isset($data['nHeight']) ? floatval($data['nHeight']) : null;
        $bmi = isset($data['nBmi']) ? floatval($data['nBmi']) : null;
        $tdee = isset($data['nTdee']) ? floatval($data['nTdee']) : null;
        $recordedAt = isset($data['dtRecordedAt']) ? $data['dtRecordedAt'] : date('Y-m-d H:i:s');
        $computedBmr = isset($data['computedBmr']) ? floatval($data['computedBmr']) : null;
        $activityLevelTitle = isset($data['activityLevelTitle']) ? trim($data['activityLevelTitle']) : null;

        if ($weight === null || $height === null) {
            echo json_encode([
                "status" => "error",
                "message" => "Missing required fields (nWeight, nHeight)"
            ]);
            exit();
        }

        try {
            // Check if columns exist, if not, create them
            try {
                $conn->exec("ALTER TABLE TbHealthRecords ADD COLUMN IF NOT EXISTS computedBmr FLOAT");
                $conn->exec("ALTER TABLE TbHealthRecords ADD COLUMN IF NOT EXISTS activityLevelTitle VARCHAR(255)");
            } catch (Exception $e) {}

            $stmt = $conn->prepare("
                INSERT INTO TbHealthRecords (nUserId, nWeight, nHeight, nBmi, nTdee, computedBmr, activityLevelTitle, isSynced, dtUpdatedAt, dtRecordedAt)
                VALUES (:userId, :weight, :height, :bmi, :tdee, :computedBmr, :activityLevelTitle, 1, NOW(), :recordedAt)
            ");
            $stmt->execute([
                ':userId' => $userId,
                ':weight' => $weight,
                ':height' => $height,
                ':bmi' => $bmi,
                ':tdee' => $tdee,
                ':computedBmr' => $computedBmr,
                ':activityLevelTitle' => $activityLevelTitle,
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
        $userId = requireAuth();
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
            // ตรวจสอบ Ownership ของ Record
            $stmtCheck = $conn->prepare("SELECT nUserId FROM TbHealthRecords WHERE nRecordId = :recordId LIMIT 1");
            $stmtCheck->execute([':recordId' => $recordId]);
            $owner = $stmtCheck->fetch();

            if ($owner && intval($owner['nUserId']) !== $userId) {
                http_response_code(403);
                echo json_encode([
                    "status" => "error",
                    "message" => "ไม่อนุญาตให้ลบข้อมูลสุขภาพของผู้อื่น (Access Denied)"
                ], JSON_UNESCAPED_UNICODE);
                exit();
            }

            $stmt = $conn->prepare("DELETE FROM TbHealthRecords WHERE nRecordId = :recordId AND nUserId = :userId");
            $stmt->execute([':recordId' => $recordId, ':userId' => $userId]);

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

