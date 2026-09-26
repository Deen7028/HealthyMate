<?php
require_once "db_connect.php";

$method = $_SERVER['REQUEST_METHOD'];

switch ($method) {

    // 1. GET: ดึงกิจวัตรทั้งหมดของ user + สถานะ log ของวันนี้
    case 'GET':
        $userId = requireAuth();
        $date = isset($_GET['date']) ? trim($_GET['date']) : date('Y-m-d');

        try {
            // ดึงกิจวัตรทั้งหมด
            $stmt = $conn->prepare("SELECT * FROM TbRoutines WHERE nUserId = :userId ORDER BY nRoutineId ASC");
            $stmt->execute([':userId' => $userId]);
            $routines = $stmt->fetchAll();

            // ดึง log ของวันที่ระบุสำหรับแต่ละ routine (รวม nProgressValue)
            $stmtLog = $conn->prepare("
                SELECT nRoutineId, isCompleted, COALESCE(nProgressValue, 0) as nProgressValue FROM TbRoutineLogs 
                WHERE nRoutineId = :routineId AND dtLogDate = :logDate
                LIMIT 1
            ");

            $result = [];
            foreach ($routines as $r) {
                $stmtLog->execute([
                    ':routineId' => $r['nRoutineId'],
                    ':logDate' => $date
                ]);
                $log = $stmtLog->fetch();
                $r['todayCompleted'] = $log ? intval($log['isCompleted']) : 0;
                $r['todayProgressValue'] = $log ? floatval($log['nProgressValue']) : 0.0;
                $result[] = $r;
            }

            // นับจำนวนที่เสร็จ
            $stmtCount = $conn->prepare("
                SELECT COUNT(*) as cnt FROM TbRoutineLogs rl
                INNER JOIN TbRoutines r ON rl.nRoutineId = r.nRoutineId
                WHERE r.nUserId = :userId AND rl.dtLogDate = :logDate AND rl.isCompleted = 1
            ");
            $stmtCount->execute([':userId' => $userId, ':logDate' => $date]);
            $completedCount = intval($stmtCount->fetch()['cnt']);

            echo json_encode([
                "status" => "success",
                "data" => $result,
                "completedCount" => $completedCount,
                "totalCount" => count($routines),
                "date" => $date,
                "serverTime" => date('Y-m-d H:i:s')
            ], JSON_UNESCAPED_UNICODE);
        } catch (PDOException $e) {
            echo json_encode([
                "status" => "error",
                "message" => $e->getMessage()
            ]);
        }
        break;

    // 2. POST: เพิ่มกิจวัตรใหม่ หรือ toggle log
    case 'POST':
        $data = json_decode(file_get_contents("php://input"), true);
        if (!$data) $data = $_POST;

        $authUserId = requireAuth();
        $action = isset($data['action']) ? $data['action'] : 'insert';

        if ($action === 'toggle_log' || $action === 'update_progress') {
            // สลับสถานะเช็ค/ยกเลิกเช็ค หรืออัปเดตความคืบหน้าย่อย (Atomic UPSERT)
            $routineId = isset($data['nRoutineId']) ? intval($data['nRoutineId']) : 0;
            $dateStr = isset($data['dtLogDate']) ? trim($data['dtLogDate']) : date('Y-m-d');
            $progressVal = isset($data['nProgressValue']) ? floatval($data['nProgressValue']) : null;

            try {
                // ตรวจสอบ Ownership ของ Routine
                $stmtCheckOwner = $conn->prepare("SELECT nUserId FROM TbRoutines WHERE nRoutineId = :rid LIMIT 1");
                $stmtCheckOwner->execute([':rid' => $routineId]);
                $owner = $stmtCheckOwner->fetch();
                if ($owner && intval($owner['nUserId']) !== $authUserId) {
                    echo json_encode(["status" => "error", "message" => "ไม่อนุญาตให้แก้ไขข้อมูลผู้อื่น (Access Denied)"]);
                    exit();
                }

                // อ่านสถานะเดิมกรณี toggle
                $stmtCheck = $conn->prepare("SELECT isCompleted, COALESCE(nProgressValue, 0) as nProgressValue FROM TbRoutineLogs WHERE nRoutineId = :rid AND dtLogDate = :d LIMIT 1");
                $stmtCheck->execute([':rid' => $routineId, ':d' => $dateStr]);
                $existing = $stmtCheck->fetch();

                if ($action === 'update_progress' && $progressVal !== null) {
                    $pVal = $progressVal;
                    $defaultState = 0; // หากเป็นการส่ง progress ย่อยครั้งแรกของวัน ให้ถือว่ายังไม่เสร็จ (0) จนกว่าจะส่ง isCompleted ยืนยัน
                    $newState = isset($data['isCompleted']) ? (intval($data['isCompleted']) ? 1 : 0) : ($existing ? intval($existing['isCompleted']) : $defaultState);
                } else {
                    $newState = isset($data['isCompleted']) ? (intval($data['isCompleted']) ? 1 : 0) : ($existing ? (intval($existing['isCompleted']) === 1 ? 0 : 1) : 1);
                    $pVal = $progressVal !== null ? $progressVal : ($existing ? floatval($existing['nProgressValue']) : 0.0);
                }

                // สั่ง UPSERT แบบ Atomic ในคำสั่งเดียว ป้องกัน Race Condition เมื่อกดรัวๆ
                $stmtUpsert = $conn->prepare("
                    INSERT INTO TbRoutineLogs (nRoutineId, isCompleted, nProgressValue, dtLogDate)
                    VALUES (:rid, :isComp, :pVal, :d)
                    ON DUPLICATE KEY UPDATE 
                        isCompleted = VALUES(isCompleted),
                        nProgressValue = VALUES(nProgressValue)
                ");
                $stmtUpsert->execute([
                    ':rid' => $routineId,
                    ':isComp' => $newState,
                    ':pVal' => $pVal,
                    ':d' => $dateStr
                ]);

                echo json_encode([
                    "status" => "success",
                    "isCompleted" => $newState,
                    "nProgressValue" => $pVal,
                    "message" => "อัปเดตสถานะกิจวัตรสำเร็จ"
                ], JSON_UNESCAPED_UNICODE);
            } catch (PDOException $e) {
                echo json_encode(["status" => "error", "message" => $e->getMessage()]);
            }
        } else {
            // เพิ่มกิจวัตรใหม่
            $userId = $authUserId;
            $title = isset($data['sTitle']) ? trim($data['sTitle']) : '';
            $time = isset($data['sTime']) ? trim($data['sTime']) : '';
            $isNotif = isset($data['isNotificationActive']) ? intval($data['isNotificationActive']) : 1;

            if (empty($title)) {
                echo json_encode(["status" => "error", "message" => "กรุณาระบุชื่อกิจวัตร"]);
                break;
            }

            try {
                $stmt = $conn->prepare("
                    INSERT INTO TbRoutines (nUserId, sTitle, sTime, isNotificationActive, dtCreatedAt) 
                    VALUES (:userId, :title, :time, :isNotif, NOW())
                ");
                $stmt->execute([
                    ':userId' => $userId,
                    ':title' => $title,
                    ':time' => $time,
                    ':isNotif' => $isNotif
                ]);

                $newId = $conn->lastInsertId();

                echo json_encode([
                    "status" => "success",
                    "message" => "เพิ่มกิจวัตรสำเร็จ",
                    "nRoutineId" => intval($newId)
                ], JSON_UNESCAPED_UNICODE);
            } catch (PDOException $e) {
                echo json_encode(["status" => "error", "message" => $e->getMessage()]);
            }
        }
        break;

    // 3. PUT: แก้ไขกิจวัตร
    case 'PUT':
        $data = json_decode(file_get_contents("php://input"), true);
        $authUserId = requireAuth();

        $routineId = isset($data['nRoutineId']) ? intval($data['nRoutineId']) : 0;
        $title = isset($data['sTitle']) ? trim($data['sTitle']) : '';
        $time = isset($data['sTime']) ? trim($data['sTime']) : '';
        $isNotif = isset($data['isNotificationActive']) ? intval($data['isNotificationActive']) : 1;

        if ($routineId <= 0 || empty($title)) {
            echo json_encode(["status" => "error", "message" => "ข้อมูลไม่ครบ"]);
            break;
        }

        try {
            $stmtCheckOwner = $conn->prepare("SELECT nUserId FROM TbRoutines WHERE nRoutineId = :rid LIMIT 1");
            $stmtCheckOwner->execute([':rid' => $routineId]);
            $owner = $stmtCheckOwner->fetch();
            if ($owner && intval($owner['nUserId']) !== $authUserId) {
                echo json_encode(["status" => "error", "message" => "ไม่อนุญาตให้แก้ไขข้อมูลผู้อื่น (Access Denied)"]);
                exit();
            }

            $stmt = $conn->prepare("
                UPDATE TbRoutines SET sTitle = :title, sTime = :time, isNotificationActive = :isNotif 
                WHERE nRoutineId = :rid
            ");
            $stmt->execute([
                ':title' => $title,
                ':time' => $time,
                ':isNotif' => $isNotif,
                ':rid' => $routineId
            ]);

            echo json_encode([
                "status" => "success",
                "message" => "แก้ไขกิจวัตรสำเร็จ"
            ], JSON_UNESCAPED_UNICODE);
        } catch (PDOException $e) {
            echo json_encode(["status" => "error", "message" => $e->getMessage()]);
        }
        break;

    // 4. DELETE: ลบกิจวัตร
    case 'DELETE':
        $data = json_decode(file_get_contents("php://input"), true);
        $authUserId = requireAuth();
        $routineId = isset($data['nRoutineId']) ? intval($data['nRoutineId']) : 0;

        if ($routineId <= 0) {
            echo json_encode(["status" => "error", "message" => "กรุณาระบุ nRoutineId"]);
            break;
        }

        try {
            $stmtCheckOwner = $conn->prepare("SELECT nUserId FROM TbRoutines WHERE nRoutineId = :rid LIMIT 1");
            $stmtCheckOwner->execute([':rid' => $routineId]);
            $owner = $stmtCheckOwner->fetch();
            if ($owner && intval($owner['nUserId']) !== $authUserId) {
                echo json_encode(["status" => "error", "message" => "ไม่อนุญาตให้ลบข้อมูลผู้อื่น (Access Denied)"]);
                exit();
            }

            // ลบ logs ก่อน
            $stmt = $conn->prepare("DELETE FROM TbRoutineLogs WHERE nRoutineId = :rid");
            $stmt->execute([':rid' => $routineId]);

            // ลบ routine
            $stmt = $conn->prepare("DELETE FROM TbRoutines WHERE nRoutineId = :rid");
            $stmt->execute([':rid' => $routineId]);

            echo json_encode([
                "status" => "success",
                "message" => "ลบกิจวัตรสำเร็จ"
            ], JSON_UNESCAPED_UNICODE);
        } catch (PDOException $e) {
            echo json_encode(["status" => "error", "message" => $e->getMessage()]);
        }
        break;

    default:
        http_response_code(405);
        echo json_encode(["status" => "error", "message" => "Method not allowed"]);
        break;
}
