<?php
// ส่วนนี้เป็น API endpoint สำหรับดึงข้อมูลกิจวัตร
// คอมเมนท์ภาษาไทยช่วยแยกหน้าที่หลักของไฟล์โดยไม่แก้ logic เดิม

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
