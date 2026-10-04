<?php
// ส่วนนี้เป็น API endpoint สำหรับแก้ไขกิจวัตร
// คอมเมนท์ภาษาไทยช่วยแยกหน้าที่หลักของไฟล์โดยไม่แก้ logic เดิม

        $data = json_decode(file_get_contents("php://input"), true);
        $authUserId = requireAuth();

        $routineId = isset($data['nRoutineId']) ? intval($data['nRoutineId']) : 0;
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
            if ($cVal > 2147483647) {
                $color = (int)($cVal - 4294967296);
            } else {
                $color = (int)$cVal;
            }
        }
        $iconData = isset($data['nIconData']) ? intval($data['nIconData']) : (isset($data['iconData']) ? intval($data['iconData']) : null);

        if ($routineId <= 0 || empty($title)) {
            echo json_encode(["status" => "error", "message" => "ข้อมูลไม่ครบ"]);
            return;
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
                "message" => "แก้ไขกิจวัตรสำเร็จ"
            ], JSON_UNESCAPED_UNICODE);
        } catch (PDOException $e) {
            echo json_encode(["status" => "error", "message" => $e->getMessage()]);
        }
