<?php
// ส่วนนี้เป็น API endpoint สำหรับดึงข้อมูลเหรียญรางวัล/ความสำเร็จ

require_once __DIR__ . "/../db_connect.php";

$method = $_SERVER['REQUEST_METHOD'];

switch ($method) {
    // 1. GET: ดึงรายการเหรียญรางวัลทั้งหมด และเหรียญที่ผู้ใช้ได้รับ
    case 'GET':
        $userId = requireAuth();

        try {
            // ดึงเหรียญรางวัลทั้งหมดที่มีในระบบ
            $stmtAll = $conn->query("SELECT * FROM TbBadges ORDER BY nBadgeId ASC");
            $allBadges = $stmtAll->fetchAll();

            // หากยังไม่มีเหรียญเริ่มต้นในระบบ ให้สร้าง Seed Data อัตโนมัติ
            if (empty($allBadges)) {
                $seedBadges = [
                    ['sBadgeName' => 'ผู้เริ่มต้นก้าวแรก', 'sDescription' => 'ออกกำลังกายครั้งแรกสำเร็จ', 'sIconUrl' => 'directions_run'],
                    ['sBadgeName' => 'วิ่งสะสม 5 กิโลเมตร', 'sDescription' => 'สะสมระยะทางครบ 5 กม.', 'sIconUrl' => 'trending_up'],
                    ['sBadgeName' => 'วิ่งสะสม 10 กิโลเมตร', 'sDescription' => 'สะสมระยะทางครบ 10 กม.', 'sIconUrl' => 'military_tech'],
                    ['sBadgeName' => 'นักเบิร์นไฟแรง', 'sDescription' => 'เผาผลาญพลังงานครบ 1,000 แคลอรี', 'sIconUrl' => 'local_fire_department'],
                    ['sBadgeName' => 'มีวินัยต่อเนื่อง 7 วัน', 'sDescription' => 'ทำกิจวัตรสำเร็จติดต่อกัน 7 วัน', 'sIconUrl' => 'emoji_events'],
                ];
                $stmtInsertSeed = $conn->prepare("INSERT INTO TbBadges (sBadgeName, sDescription, sIconUrl) VALUES (:name, :desc, :icon)");
                foreach ($seedBadges as $b) {
                    $stmtInsertSeed->execute([':name' => $b['sBadgeName'], ':desc' => $b['sDescription'], ':icon' => $b['sIconUrl']]);
                }
                $allBadges = $conn->query("SELECT * FROM TbBadges ORDER BY nBadgeId ASC")->fetchAll();
            }

            // ดึงเหรียญที่ผู้ใช้คนนี้ได้รับแล้ว
            $stmtUser = $conn->prepare("
                SELECT ub.nUserBadgeId, ub.nBadgeId, ub.dtEarnedAt, b.sBadgeName, b.sDescription, b.sIconUrl
                FROM TbUserBadges ub
                INNER JOIN TbBadges b ON ub.nBadgeId = b.nBadgeId
                WHERE ub.nUserId = :userId
                ORDER BY ub.dtEarnedAt DESC
            ");
            $stmtUser->execute([':userId' => $userId]);
            $userBadges = $stmtUser->fetchAll();

            echo json_encode([
                "status" => "success",
                "allBadges" => $allBadges,
                "userBadges" => $userBadges
            ], JSON_UNESCAPED_UNICODE);
        } catch (PDOException $e) {
            echo json_encode([
                "status" => "error",
                "message" => $e->getMessage()
            ], JSON_UNESCAPED_UNICODE);
        }
        break;

    // 2. POST: ปลดล็อกเหรียญรางวัลใหม่ให้ผู้ใช้
    case 'POST':
        $userId = requireAuth();
        $data = json_decode(file_get_contents("php://input"), true);
        if (!$data) $data = $_POST;

        $badgeId = isset($data['nBadgeId']) ? intval($data['nBadgeId']) : 0;
        $badgeName = isset($data['sBadgeName']) ? trim($data['sBadgeName']) : '';

        if ($badgeId <= 0 && empty($badgeName)) {
            echo json_encode(["status" => "error", "message" => "กรุณาระบุ nBadgeId หรือ sBadgeName"]);
            break;
        }

        try {
            // หากส่งเป็นชื่อเหรียญ ให้ค้นหา nBadgeId
            if ($badgeId <= 0 && !empty($badgeName)) {
                $stmtFind = $conn->prepare("SELECT nBadgeId FROM TbBadges WHERE sBadgeName = :name LIMIT 1");
                $stmtFind->execute([':name' => $badgeName]);
                $found = $stmtFind->fetch();
                if ($found) {
                    $badgeId = intval($found['nBadgeId']);
                } else {
                    // สร้าง Badge ใหม่ถ้ายังไม่มี
                    $stmtCreateBadge = $conn->prepare("INSERT INTO TbBadges (sBadgeName, sDescription, sIconUrl) VALUES (:name, 'เหรียญรางวัลพิเศษ', 'emoji_events')");
                    $stmtCreateBadge->execute([':name' => $badgeName]);
                    $badgeId = intval($conn->lastInsertId());
                }
            }

            // ตรวจสอบว่าเคยได้เหรียญนี้ไปแล้วหรือยัง
            $stmtCheck = $conn->prepare("SELECT nUserBadgeId FROM TbUserBadges WHERE nUserId = :userId AND nBadgeId = :badgeId LIMIT 1");
            $stmtCheck->execute([':userId' => $userId, ':badgeId' => $badgeId]);
            $alreadyEarned = $stmtCheck->fetch();

            if (!$alreadyEarned) {
                $stmtEarn = $conn->prepare("INSERT INTO TbUserBadges (nUserId, nBadgeId, dtEarnedAt) VALUES (:userId, :badgeId, NOW())");
                $stmtEarn->execute([':userId' => $userId, ':badgeId' => $badgeId]);
                $newId = $conn->lastInsertId();

                echo json_encode([
                    "status" => "success",
                    "message" => "ปลดล็อกเหรียญรางวัลสำเร็จ",
                    "nUserBadgeId" => intval($newId),
                    "nBadgeId" => $badgeId
                ], JSON_UNESCAPED_UNICODE);
            } else {
                echo json_encode([
                    "status" => "already_earned",
                    "message" => "ผู้ใช้ได้รับเหรียญรางวัลนี้แล้ว",
                    "nUserBadgeId" => intval($alreadyEarned['nUserBadgeId']),
                    "nBadgeId" => $badgeId
                ], JSON_UNESCAPED_UNICODE);
            }
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
