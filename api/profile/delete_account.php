<?php
// ส่วนนี้เป็น API endpoint สำหรับลบบัญชีและข้อมูลผู้ใช้

header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
header('Content-Type: application/json; charset=utf-8');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once __DIR__ . '/db_connect.php';

$rawInput = file_get_contents('php://input');
$data = json_decode($rawInput, true);

$nUserId = requireAuth();

if ($nUserId <= 0) {
    http_response_code(400);
    echo json_encode([
        'status' => 'error',
        'message' => 'ไม่พบบัญชีผู้ใช้ที่ต้องการลบ'
    ], JSON_UNESCAPED_UNICODE);
    exit();
}

try {
    // 2. ลบไฟล์รูปภาพของผู้ใช้ในโฟลเดอร์ uploads/ ป้องกัน Storage Leak
    // 2.1 รูปโปรไฟล์
    $stmtProfile = $conn->prepare("SELECT sProfileImagePath FROM TbUsers WHERE nUserId = :userId LIMIT 1");
    $stmtProfile->execute([':userId' => $nUserId]);
    $userRow = $stmtProfile->fetch();
    if ($userRow && !empty($userRow['sProfileImagePath'])) {
        $imgPath = __DIR__ . '/' . ltrim($userRow['sProfileImagePath'], '/');
        if (file_exists($imgPath) && is_file($imgPath)) {
            @unlink($imgPath);
        }
    }

    // 2.2 รูปอาหารใน TbNutritionLogs
    $stmtNutrition = $conn->prepare("SELECT sImagePath FROM TbNutritionLogs WHERE nUserId = :userId AND sImagePath IS NOT NULL AND sImagePath != ''");
    $stmtNutrition->execute([':userId' => $nUserId]);
    $foodRows = $stmtNutrition->fetchAll();
    foreach ($foodRows as $food) {
        if (!empty($food['sImagePath'])) {
            $imgPath = __DIR__ . '/' . ltrim($food['sImagePath'], '/');
            if (file_exists($imgPath) && is_file($imgPath)) {
                @unlink($imgPath);
            }
        }
    }

    $conn->beginTransaction();

    // 3. ลบข้อมูลจากตารางที่เกี่ยวข้องตามลำดับ (Cascade Cleanup)
    $tablesToDelete = [
        'TbRoutineLogs' => 'nRoutineId IN (SELECT nRoutineId FROM TbRoutines WHERE nUserId = :id)',
        'TbRoutines' => 'nUserId = :id',
        'TbHealthRecords' => 'nUserId = :id',
        'TbNutritionLogs' => 'nUserId = :id',
        'TbWorkouts' => 'nUserId = :id',
        'TbHealthIntegrations' => 'nUserId = :id',
        'TbUserBadges' => 'nUserId = :id',
        'TbGoals' => 'nUserId = :id',
        'TbUserPreferences' => 'nUserId = :id',
        'TbUsers' => 'nUserId = :id'
    ];

    foreach ($tablesToDelete as $table => $whereClause) {
        $sql = "DELETE FROM $table WHERE $whereClause";
        $stmt = $conn->prepare($sql);
        $stmt->execute([':id' => $nUserId]);
    }

    $conn->commit();

    echo json_encode([
        'status' => 'success',
        'message' => 'ลบบัญชีผู้ใช้ ข้อมูล และไฟล์รูปภาพทั้งหมดสำเร็จเรียบร้อยแล้ว'
    ], JSON_UNESCAPED_UNICODE);
} catch (Exception $e) {
    if ($conn->inTransaction()) {
        $conn->rollBack();
    }
    echo json_encode([
        'status' => 'error',
        'message' => 'เกิดข้อผิดพลาดในการลบบัญชี: ' . $e->getMessage()
    ], JSON_UNESCAPED_UNICODE);
}
