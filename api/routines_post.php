<?php
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
            $title = isset($data['sTitle']) ? trim($data['sTitle']) : (isset($data['title']) ? trim($data['title']) : '');
            $rawTime = isset($data['sTime']) ? trim($data['sTime']) : (isset($data['notificationTime']) ? trim($data['notificationTime']) : '');
            // ป้องกัน SQL Error: Data too long for column 'sTime'
            $time = mb_substr($rawTime, 0, 50);
            $isNotif = isset($data['isNotificationActive']) ? intval($data['isNotificationActive']) : 1;
            $targetVal = isset($data['nTargetValue']) ? floatval($data['nTargetValue']) : (isset($data['targetValue']) ? floatval($data['targetValue']) : 1.0);
            $unit = isset($data['sUnit']) ? trim($data['sUnit']) : (isset($data['unit']) ? trim($data['unit']) : 'ครั้ง');
            $linkedWorkout = isset($data['sLinkedWorkout']) ? trim($data['sLinkedWorkout']) : (isset($data['linkedWorkoutType']) ? trim($data['linkedWorkoutType']) : null);
            
            // ป้องกัน SQL Error: Out of range value for column 'nColor' (0xFFxxxxxx เกินค่า MySQL SIGNED INT 2147483647)
            $rawColor = isset($data['nColor']) ? $data['nColor'] : (isset($data['color']) ? $data['color'] : null);
            $color = null;
            if ($rawColor !== null) {
                $cVal = (float)$rawColor;
                if ($cVal > 2147483647) {
                    $color = (int)($cVal - 4294967296);
                } else {
                    $color = (int)$cVal;
                }
            }
            $iconData = isset($data['nIconData']) ? intval($data['nIconData']) : (isset($data['iconData']) ? intval($data['iconData']) : null);

            if (empty($title)) {
                echo json_encode(["status" => "error", "message" => "กรุณาระบุชื่อกิจวัตร"]);
                return;
            }

            try {
                // พยายามขยาย column ใน MySQL อัตโนมัติถ้ายังเป็น VARCHAR แคบๆ
                try {
                    $conn->exec("ALTER TABLE TbRoutines MODIFY COLUMN sTime VARCHAR(255)");
                    $conn->exec("ALTER TABLE TbRoutines MODIFY COLUMN nColor BIGINT");
                } catch (Exception $e) {}

                // 🛡️ ตรวจสอบก่อนว่ามีกิจวัตรชื่อนี้ของ user อยู่แล้วหรือไม่ เพื่อป้องกันการสร้างซ้ำซ้อน
                $stmtCheckExist = $conn->prepare("SELECT nRoutineId FROM TbRoutines WHERE nUserId = :userId AND LOWER(TRIM(sTitle)) = LOWER(TRIM(:title)) ORDER BY nRoutineId ASC LIMIT 1");
                $stmtCheckExist->execute([':userId' => $userId, ':title' => $title]);
                $existingRoutine = $stmtCheckExist->fetch();

                if ($existingRoutine) {
                    $existingId = intval($existingRoutine['nRoutineId']);
                    $stmtUpdate = $conn->prepare("
                        UPDATE TbRoutines 
                        SET sTime = :time, isNotificationActive = :isNotif, nTargetValue = :targetVal, sUnit = :unit, sLinkedWorkout = :linkedWorkout, nColor = :color, nIconData = :iconData
                        WHERE nRoutineId = :rid
                    ");
                    $stmtUpdate->execute([
                        ':time' => $time,
                        ':isNotif' => $isNotif,
                        ':targetVal' => $targetVal,
                        ':unit' => $unit,
                        ':linkedWorkout' => $linkedWorkout,
                        ':color' => $color,
                        ':iconData' => $iconData,
                        ':rid' => $existingId
                    ]);

                    echo json_encode([
                        "status" => "success",
                        "message" => "อัปเดตกิจวัตรเดิมสำเร็จ",
                        "nRoutineId" => $existingId
                    ], JSON_UNESCAPED_UNICODE);
                    return;
                }

                $stmt = $conn->prepare("
                    INSERT INTO TbRoutines (nUserId, sTitle, sTime, isNotificationActive, nTargetValue, sUnit, sLinkedWorkout, nColor, nIconData, dtCreatedAt) 
                    VALUES (:userId, :title, :time, :isNotif, :targetVal, :unit, :linkedWorkout, :color, :iconData, NOW())
                ");
                $stmt->execute([
                    ':userId' => $userId,
                    ':title' => $title,
                    ':time' => $time,
                    ':isNotif' => $isNotif,
                    ':targetVal' => $targetVal,
                    ':unit' => $unit,
                    ':linkedWorkout' => $linkedWorkout,
                    ':color' => $color,
                    ':iconData' => $iconData
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
