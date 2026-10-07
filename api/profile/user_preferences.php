<?php
// ส่วนนี้เป็น API endpoint สำหรับจัดการค่าความชอบและการตั้งค่าผู้ใช้

require_once __DIR__ . "/../db_connect.php";

$method = $_SERVER['REQUEST_METHOD'];

switch ($method) {
    // 1. GET: ดึงค่าตั้งค่าของผู้ใช้
    case 'GET':
        $userId = requireAuth();

        try {
            $stmt = $conn->prepare("SELECT * FROM TbUserPreferences WHERE nUserId = :userId LIMIT 1");
            $stmt->execute([':userId' => $userId]);
            $prefs = $stmt->fetch();

            echo json_encode([
                "status" => "success",
                "data" => $prefs ?: null
            ], JSON_UNESCAPED_UNICODE);
        } catch (PDOException $e) {
            echo json_encode([
                "status" => "error",
                "message" => $e->getMessage()
            ], JSON_UNESCAPED_UNICODE);
        }
        break;

    // 2. POST / PUT: บันทึกหรืออัปเดตการตั้งค่า (UPSERT)
    case 'POST':
    case 'PUT':
        $userId = requireAuth();
        $data = json_decode(file_get_contents("php://input"), true);
        if (!$data) $data = $_POST;

        $unitSystem = isset($data['sUnitSystem']) ? trim($data['sUnitSystem']) : 'metric';
        $unitLabel = isset($data['sUnitLabel']) ? trim($data['sUnitLabel']) : 'Kilometers, Kilograms';
        $geminiApiKey = isset($data['sGeminiApiKey']) ? trim($data['sGeminiApiKey']) : null;

        try {
            // ตรวจสอบว่ามีแถวของ nUserId อยู่แล้วหรือไม่
            $stmtCheck = $conn->prepare("SELECT nUserId, sGeminiApiKey FROM TbUserPreferences WHERE nUserId = :userId LIMIT 1");
            $stmtCheck->execute([':userId' => $userId]);
            $existing = $stmtCheck->fetch();

            if ($existing) {
                $finalKey = ($geminiApiKey !== null) ? $geminiApiKey : ($existing['sGeminiApiKey'] ?? '');
                $stmtUpdate = $conn->prepare("
                    UPDATE TbUserPreferences 
                    SET sUnitSystem = :unitSystem, sUnitLabel = :unitLabel, sGeminiApiKey = :geminiApiKey
                    WHERE nUserId = :userId
                ");
                $stmtUpdate->execute([
                    ':unitSystem' => $unitSystem,
                    ':unitLabel' => $unitLabel,
                    ':geminiApiKey' => $finalKey,
                    ':userId' => $userId
                ]);
            } else {
                $stmtInsert = $conn->prepare("
                    INSERT INTO TbUserPreferences (nUserId, sUnitSystem, sUnitLabel, sGeminiApiKey)
                    VALUES (:userId, :unitSystem, :unitLabel, :geminiApiKey)
                ");
                $stmtInsert->execute([
                    ':userId' => $userId,
                    ':unitSystem' => $unitSystem,
                    ':unitLabel' => $unitLabel,
                    ':geminiApiKey' => $geminiApiKey ?: ''
                ]);
            }

            echo json_encode([
                "status" => "success",
                "message" => "บันทึกการตั้งค่าสำเร็จ"
            ], JSON_UNESCAPED_UNICODE);
        } catch (PDOException $e) {
            echo json_encode([
                "status" => "error",
                "message" => $e->getMessage()
            ], JSON_UNESCAPED_UNICODE);
        }
        break;

    default:
        http_response_code(405);
        echo json_encode(["status" => "error", "message" => "Method not allowed"]);
        break;
}
?>
