<?php
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

$nUserId = isset($data['nUserId']) ? intval($data['nUserId']) : 0;
$sEmail = isset($data['sEmail']) ? trim($data['sEmail']) : '';

if ($nUserId <= 0 && empty($sEmail)) {
    echo json_encode([
        'status' => 'error',
        'message' => 'กรุณาระบุ nUserId หรือ sEmail เพื่อยืนยันการลบบัญชี'
    ], JSON_UNESCAPED_UNICODE);
    exit();
}

try {
    $conn->begin_transaction();

    // 1. ดึง nUserId หากส่งมาแค่อีเมล
    if ($nUserId <= 0 && !empty($sEmail)) {
        $stmtUser = $conn->prepare("SELECT nUserId FROM TbUsers WHERE sEmail = ?");
        $stmtUser->bind_param("s", $sEmail);
        $stmtUser->execute();
        $resUser = $stmtUser->get_result();
        if ($row = $resUser->fetch_assoc()) {
            $nUserId = intval($row['nUserId']);
        }
        $stmtUser->close();
    }

    if ($nUserId <= 0) {
        $conn->rollback();
        echo json_encode([
            'status' => 'error',
            'message' => 'ไม่พบบัญชีผู้ใช้ที่ต้องการลบ'
        ], JSON_UNESCAPED_UNICODE);
        exit();
    }

    // 2. ลบข้อมูลจากตารางที่เกี่ยวข้องตามลำดับ (Cascade Cleanup)
    $tablesToDelete = [
        'TbRoutineLogs' => 'nRoutineId IN (SELECT nRoutineId FROM TbRoutines WHERE nUserId = ?)',
        'TbRoutines' => 'nUserId = ?',
        'TbHealthRecords' => 'nUserId = ?',
        'TbNutritionLogs' => 'nUserId = ?',
        'TbWorkouts' => 'nUserId = ?',
        'TbHealthIntegrations' => 'nUserId = ?',
        'TbUserBadges' => 'nUserId = ?',
        'TbGoals' => 'nUserId = ?',
        'TbUserPreferences' => 'nUserId = ?',
        'TbUsers' => 'nUserId = ?'
    ];

    foreach ($tablesToDelete as $table => $whereClause) {
        $sql = "DELETE FROM $table WHERE $whereClause";
        $stmt = $conn->prepare($sql);
        if ($stmt) {
            $stmt->bind_param("i", $nUserId);
            $stmt->execute();
            $stmt->close();
        }
    }

    $conn->commit();

    echo json_encode([
        'status' => 'success',
        'message' => 'ลบบัญชีผู้ใช้และข้อมูลทั้งหมดสำเร็จเรียบร้อยแล้ว (PDPA/GDPR Compliant)'
    ], JSON_UNESCAPED_UNICODE);

} catch (Exception $e) {
    $conn->rollback();
    echo json_encode([
        'status' => 'error',
        'message' => 'เกิดข้อผิดพลาดในการลบบัญชี: ' . $e->getMessage()
    ], JSON_UNESCAPED_UNICODE);
}
