<?php
// ส่วนนี้เป็น API endpoint สำหรับลบกิจวัตร
// คอมเมนท์ภาษาไทยช่วยแยกหน้าที่หลักของไฟล์โดยไม่แก้ logic เดิม

$data = json_decode(file_get_contents("php://input"), true);
        $authUserId = requireAuth();
        $routineId = isset($data['nRoutineId']) ? intval($data['nRoutineId']) : 0;

        if ($routineId <= 0) {
            echo json_encode(["status" => "error", "message" => "กรุณาระบุ nRoutineId"]);
            return;
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
