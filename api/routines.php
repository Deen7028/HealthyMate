<?php
// API endpoint แบบ All-in-One จัดการกิจวัตรประจำวัน (CRUD Routines + Toggle / Progress Logs)
require_once __DIR__ . "/db_connect.php";

$method = $_SERVER['REQUEST_METHOD'];
$authUserId = requireAuth();

switch ($method) {
    // 1. GET: ดึงกิจวัตรทั้งหมดของ user + สถานะ log ประจำวัน
    case 'GET':
        $date = isset($_GET['date']) ? trim($_GET['date']) : date('Y-m-d');
        try {
            $stmt = $conn->prepare("SELECT * FROM TbRoutines WHERE nUserId = :userId ORDER BY nRoutineId ASC");
            $stmt->execute([':userId' => $authUserId]);
            $routines = $stmt->fetchAll();

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

            $stmtCount = $conn->prepare("
                SELECT COUNT(*) as cnt FROM TbRoutineLogs rl
                INNER JOIN TbRoutines r ON rl.nRoutineId = r.nRoutineId
                WHERE r.nUserId = :userId AND rl.dtLogDate = :logDate AND rl.isCompleted = 1
            ");
            $stmtCount->execute([':userId' => $authUserId, ':logDate' => $date]);
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
            echo json_encode(["status" => "error", "message" => $e->getMessage()]);
        }
        break;

    // 2. POST / PUT: รองรับทั้ง Insert, Update และ Toggle / Progress (ตรวจสอบ nRoutineId & action อัตโนมัติ)
    case 'POST':
    case 'PUT':
        $data = json_decode(file_get_contents("php://input"), true);
        if (!$data) $data = $_POST;

        $action = isset($data['action']) ? $data['action'] : '';
        $routineId = isset($data['nRoutineId']) ? intval($data['nRoutineId']) : 0;

        // 2.1 สลับสถานะเช็ค/ยกเลิก หรืออัปเดตความคืบหน้า (Toggle / Progress)
        if ($action === 'toggle_log' || $action === 'update_progress') {
            $dateStr = isset($data['dtLogDate']) ? trim($data['dtLogDate']) : date('Y-m-d');
            $progressVal = isset($data['nProgressValue']) ? floatval($data['nProgressValue']) : null;

            try {
                $stmtCheckOwner = $conn->prepare("SELECT nUserId FROM TbRoutines WHERE nRoutineId = :rid LIMIT 1");
                $stmtCheckOwner->execute([':rid' => $routineId]);
                $owner = $stmtCheckOwner->fetch();
                if ($owner && intval($owner['nUserId']) !== $authUserId) {
                    echo json_encode(["status" => "error", "message" => "ไม่อนุญาตให้แก้ไขข้อมูลผู้อื่น (Access Denied)"]);
                    exit();
                }

                $stmtCheck = $conn->prepare("SELECT isCompleted, COALESCE(nProgressValue, 0) as nProgressValue FROM TbRoutineLogs WHERE nRoutineId = :rid AND dtLogDate = :d LIMIT 1");
                $stmtCheck->execute([':rid' => $routineId, ':d' => $dateStr]);
                $existing = $stmtCheck->fetch();

                if ($action === 'update_progress' && $progressVal !== null) {
                    $pVal = $progressVal;
                    $defaultState = 0;
                    $newState = isset($data['isCompleted']) ? (intval($data['isCompleted']) ? 1 : 0) : ($existing ? intval($existing['isCompleted']) : $defaultState);
                } else {
                    $newState = isset($data['isCompleted']) ? (intval($data['isCompleted']) ? 1 : 0) : ($existing ? (intval($existing['isCompleted']) === 1 ? 0 : 1) : 1);
                    $pVal = $progressVal !== null ? $progressVal : ($existing ? floatval($existing['nProgressValue']) : 0.0);
                }

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
            break;
        }

        // 2.2 บันทึกข้อมูล Routine (ถ้ามี nRoutineId > 0 ทำ UPDATE, ถ้าไม่มีทำ INSERT)
        $title = isset($data['sTitle']) ? trim($data['sTitle']) : (isset($data['title']) ? trim($data['title']) : '');
        $rawTime = isset($data['sTime']) ? trim($data['sTime']) : (isset($data['notificationTime']) ? trim($data['notificationTime']) : '');
        $time = mb_substr($rawTime, 0, 50);
        $isNotif = isset($data['isNotificationActive']) ? intval($data['isNotificationActive']) : 1;
        $targetVal = isset($data['nTargetValue']) ? floatval($data['nTargetValue']) : (isset($data['targetValue']) ? floatval($data['targetValue']) : 1.0);
        $unit = isset($data['sUnit']) ? trim($data['sUnit']) : (isset($data['unit']) ? trim($data['unit']) : 'ครั้ง');
        $linkedWorkout = isset($data['sLinkedWorkout']) ? trim($data['sLinkedWorkout']) : (isset($data['linkedWorkoutType']) ? trim($data['linkedWorkoutType']) : null);
        
        $rawColor = isset($data['nColor']) ? $data['nColor'] : (isset($data['color']) ? $data['color'] : null);
        $color = null;
        if ($rawColor !== null) {
            $cVal = (float)$rawColor;
            $color = ($cVal > 2147483647) ? (int)($cVal - 4294967296) : (int)$cVal;
        }
        $iconData = isset($data['nIconData']) ? intval($data['nIconData']) : (isset($data['iconData']) ? intval($data['iconData']) : null);

        if (empty($title)) {
            echo json_encode(["status" => "error", "message" => "กรุณาระบุชื่อกิจวัตร"]);
            break;
        }

        try {
            if ($routineId > 0) {
                // UPDATE
                $stmtCheckOwner = $conn->prepare("SELECT nUserId FROM TbRoutines WHERE nRoutineId = :rid LIMIT 1");
                $stmtCheckOwner->execute([':rid' => $routineId]);
                $owner = $stmtCheckOwner->fetch();
                if ($owner && intval($owner['nUserId']) !== $authUserId) {
                    echo json_encode(["status" => "error", "message" => "ไม่อนุญาตให้แก้ไขข้อมูลผู้อื่น (Access Denied)"]);
                    exit();
                }

                $stmt = $conn->prepare("
                    UPDATE TbRoutines SET 
                        sTitle = :title, 
                        sTime = :time, 
                        isNotificationActive = :isNotif,
                        nTargetValue = :targetVal,
                        sUnit = :unit,
                        sLinkedWorkout = :linkedWorkout,
                        nColor = :color,
                        nIconData = :iconData
                    WHERE nRoutineId = :rid
                ");
                $stmt->execute([
                    ':title' => $title,
                    ':time' => $time,
                    ':isNotif' => $isNotif,
                    ':targetVal' => $targetVal,
                    ':unit' => $unit,
                    ':linkedWorkout' => $linkedWorkout,
                    ':color' => $color,
                    ':iconData' => $iconData,
                    ':rid' => $routineId
                ]);

                echo json_encode([
                    "status" => "success",
                    "nRoutineId" => $routineId,
                    "message" => "แก้ไขกิจวัตรสำเร็จ"
                ], JSON_UNESCAPED_UNICODE);
            } else {
                // INSERT
                $stmt = $conn->prepare("
                    INSERT INTO TbRoutines (nUserId, sTitle, sTime, isNotificationActive, nTargetValue, sUnit, sLinkedWorkout, nColor, nIconData)
                    VALUES (:userId, :title, :time, :isNotif, :targetVal, :unit, :linkedWorkout, :color, :iconData)
                ");
                $stmt->execute([
                    ':userId' => $authUserId,
                    ':title' => $title,
                    ':time' => $time,
                    ':isNotif' => $isNotif,
                    ':targetVal' => $targetVal,
                    ':unit' => $unit,
                    ':linkedWorkout' => $linkedWorkout,
                    ':color' => $color,
                    ':iconData' => $iconData
                ]);
                $newId = intval($conn->lastInsertId());

                echo json_encode([
                    "status" => "success",
                    "nRoutineId" => $newId,
                    "message" => "สร้างกิจวัตรสำเร็จ"
                ], JSON_UNESCAPED_UNICODE);
            }
        } catch (PDOException $e) {
            echo json_encode(["status" => "error", "message" => $e->getMessage()]);
        }
        break;

    // 3. DELETE: ลบกิจวัตรตาม nRoutineId
    case 'DELETE':
        $data = json_decode(file_get_contents("php://input"), true);
        $routineId = isset($data['nRoutineId']) ? intval($data['nRoutineId']) : (isset($_GET['nRoutineId']) ? intval($_GET['nRoutineId']) : 0);

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

            $conn->prepare("DELETE FROM TbRoutineLogs WHERE nRoutineId = :rid")->execute([':rid' => $routineId]);
            $conn->prepare("DELETE FROM TbRoutines WHERE nRoutineId = :rid")->execute([':rid' => $routineId]);

            echo json_encode(["status" => "success", "message" => "ลบกิจวัตรสำเร็จ"], JSON_UNESCAPED_UNICODE);
        } catch (PDOException $e) {
            echo json_encode(["status" => "error", "message" => $e->getMessage()]);
        }
        break;

    default:
        http_response_code(405);
        echo json_encode(["status" => "error", "message" => "Method not allowed"]);
        break;
}
