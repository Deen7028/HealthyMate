<?php
// ส่วนนี้เป็น API endpoint สำหรับจัดการเป้าหมายหลักและเป้าหมายย่อย
// คอมเมนท์ภาษาไทยช่วยแยกหน้าที่หลักของไฟล์โดยไม่แก้ logic เดิม

require_once "db_connect.php";

$method = $_SERVER['REQUEST_METHOD'];

switch ($method) {
    // 1. GET: ดึงเป้าหมายหลักของผู้ใช้
    case 'GET':
        $userId = requireAuth();

        try {
            $stmt = $conn->prepare("SELECT * FROM TbGoals WHERE nUserId = :userId ORDER BY nGoalId DESC LIMIT 1");
            $stmt->execute([':userId' => $userId]);
            $goal = $stmt->fetch();

            echo json_encode([
                "status" => "success",
                "data" => $goal ?: null
            ], JSON_UNESCAPED_UNICODE);
        } catch (PDOException $e) {
            echo json_encode([
                "status" => "error",
                "message" => $e->getMessage()
            ], JSON_UNESCAPED_UNICODE);
        }
        break;

    // 2. POST / PUT: บันทึกหรืออัปเดตเป้าหมายหลัก (UPSERT)
    case 'POST':
    case 'PUT':
        $userId = requireAuth();
        $data = json_decode(file_get_contents("php://input"), true);
        if (!$data) $data = $_POST;

        $action = isset($data['action']) ? $data['action'] : 'save';
        if ($action === 'clear_goal') {
            try {
                $stmt = $conn->prepare("DELETE FROM TbGoals WHERE nUserId = :userId");
                $stmt->execute([':userId' => $userId]);
                echo json_encode([
                    "status" => "success",
                    "message" => "ลบเป้าหมายหลักเรียบร้อยแล้ว"
                ], JSON_UNESCAPED_UNICODE);
            } catch (PDOException $e) {
                echo json_encode(["status" => "error", "message" => $e->getMessage()]);
            }
            break;
        }

        $routineId = isset($data['nRoutineId']) ? intval($data['nRoutineId']) : 0;
        $title = isset($data['sTitle']) ? trim($data['sTitle']) : 'เป้าหมายหลัก';
        $progress = isset($data['nProgress']) ? floatval($data['nProgress']) : 0.0;
        $remainingText = isset($data['sRemainingText']) ? trim($data['sRemainingText']) : '';

        try {
            // ตรวจสอบเป้าหมายล่าสุดของผู้ใช้
            $stmtCheck = $conn->prepare("SELECT nGoalId, sTitle, nRoutineId, nProgress, sRemainingText FROM TbGoals WHERE nUserId = :userId ORDER BY nGoalId DESC LIMIT 1");
            $stmtCheck->execute([':userId' => $userId]);
            $existing = $stmtCheck->fetch();

            $isExistingCompleted = false;
            $isSameGoal = false;

            if ($existing) {
                $existingProgress = floatval($existing['nProgress']);
                $existingRemaining = strval($existing['sRemainingText']);
                $isExistingCompleted = ($existingProgress >= 1.0 || strpos($existingRemaining, '100%') !== false);
                $isSameGoal = ($existing['sTitle'] === $title && intval($existing['nRoutineId']) === $routineId);
            }

            if ($existing && ($isSameGoal || !$isExistingCompleted)) {
                $stmtUpdate = $conn->prepare("
                    UPDATE TbGoals 
                    SET nRoutineId = :rid, sTitle = :title, nProgress = :progress, sRemainingText = :remainingText, dtUpdatedAt = NOW()
                    WHERE nGoalId = :gid
                ");
                $stmtUpdate->execute([
                    ':rid' => $routineId,
                    ':title' => $title,
                    ':progress' => $progress,
                    ':remainingText' => $remainingText,
                    ':gid' => $existing['nGoalId']
                ]);
                $goalId = $existing['nGoalId'];
            } else {
                $stmtInsert = $conn->prepare("
                    INSERT INTO TbGoals (nUserId, nRoutineId, sTitle, nProgress, sRemainingText, dtCreatedAt, dtUpdatedAt)
                    VALUES (:userId, :rid, :title, :progress, :remainingText, NOW(), NOW())
                ");
                $stmtInsert->execute([
                    ':userId' => $userId,
                    ':rid' => $routineId,
                    ':title' => $title,
                    ':progress' => $progress,
                    ':remainingText' => $remainingText
                ]);
                $goalId = $conn->lastInsertId();
            }

            echo json_encode([
                "status" => "success",
                "message" => "บันทึกเป้าหมายหลักเรียบร้อยแล้ว",
                "nGoalId" => intval($goalId)
            ], JSON_UNESCAPED_UNICODE);
        } catch (PDOException $e) {
            echo json_encode([
                "status" => "error",
                "message" => $e->getMessage()
            ], JSON_UNESCAPED_UNICODE);
        }
        break;

    // 3. DELETE: ลบเป้าหมายหลัก
    case 'DELETE':
        $userId = requireAuth();
        try {
            $stmt = $conn->prepare("DELETE FROM TbGoals WHERE nUserId = :userId");
            $stmt->execute([':userId' => $userId]);
            echo json_encode([
                "status" => "success",
                "message" => "ลบเป้าหมายหลักเรียบร้อยแล้ว"
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
