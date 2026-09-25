<?php
require_once "db_connect.php";

// dashboard.php: รวมข้อมูลสำหรับหน้า Dashboard ทั้งหมดในคำขอเดียว
// เพื่อลดจำนวน HTTP requests

$method = $_SERVER['REQUEST_METHOD'];

if ($method !== 'GET') {
    http_response_code(405);
    echo json_encode(["status" => "error", "message" => "Method not allowed"]);
    exit();
}

$authUserId = getAuthenticatedUserId();
$userId = $authUserId !== null ? $authUserId : (isset($_GET['nUserId']) ? intval($_GET['nUserId']) : 1);
$today = date('Y-m-d');

try {
    // 1. ข้อมูลผู้ใช้
    $stmtUser = $conn->prepare("SELECT * FROM TbUsers WHERE nUserId = :userId LIMIT 1");
    $stmtUser->execute([':userId' => $userId]);
    $user = $stmtUser->fetch();

    // 2. Health Record ล่าสุด และ Goal ล่าสุด
    $stmtHR = $conn->prepare("SELECT * FROM TbHealthRecords WHERE nUserId = :userId ORDER BY dtRecordedAt DESC LIMIT 1");
    $stmtHR->execute([':userId' => $userId]);
    $latestHealthRecord = $stmtHR->fetch();

    $stmtGoal = $conn->prepare("SELECT * FROM TbGoals WHERE nUserId = :userId ORDER BY nGoalId DESC LIMIT 1");
    $stmtGoal->execute([':userId' => $userId]);
    $goal = $stmtGoal->fetch();

    // 3. รวมสถิติ Workouts, Nutrition, Routines ใน Query เดียว (Combined Query Optimization)
    $stmtCombined = $conn->prepare("
        SELECT 
            (SELECT COUNT(*) FROM TbWorkouts WHERE nUserId = :u1) as totalWorkoutCount,
            (SELECT COALESCE(SUM(nDistance), 0) FROM TbWorkouts WHERE nUserId = :u2) as totalWorkoutDistance,
            (SELECT COALESCE(SUM(nCaloriesBurned), 0) FROM TbWorkouts WHERE nUserId = :u3) as totalWorkoutCalories,
            (SELECT COALESCE(SUM(nDuration), 0) FROM TbWorkouts WHERE nUserId = :u4) as totalWorkoutDuration,
            (SELECT COALESCE(SUM(nCalories), 0) FROM TbNutritionLogs WHERE nUserId = :u5 AND dtLoggedAt LIKE :t1) as totalNutritionCalories,
            (SELECT COUNT(*) FROM TbNutritionLogs WHERE nUserId = :u6 AND dtLoggedAt LIKE :t2) as nutritionLogCount,
            (SELECT COUNT(*) FROM TbRoutines WHERE nUserId = :u7) as totalRoutines,
            (SELECT COUNT(*) FROM TbRoutineLogs rl INNER JOIN TbRoutines r ON rl.nRoutineId = r.nRoutineId WHERE r.nUserId = :u8 AND rl.dtLogDate = :t3 AND rl.isCompleted = 1) as completedRoutines
    ");
    $todayLike = "$today%";
    $stmtCombined->execute([
        ':u1' => $userId, ':u2' => $userId, ':u3' => $userId, ':u4' => $userId,
        ':u5' => $userId, ':t1' => $todayLike,
        ':u6' => $userId, ':t2' => $todayLike,
        ':u7' => $userId,
        ':u8' => $userId, ':t3' => $today
    ]);
    $stats = $stmtCombined->fetch();

    $workoutStats = [
        'totalCount' => intval($stats['totalWorkoutCount']),
        'totalDistance' => floatval($stats['totalWorkoutDistance']),
        'totalCalories' => floatval($stats['totalWorkoutCalories']),
        'totalDuration' => intval($stats['totalWorkoutDuration']),
    ];
    $nutritionToday = [
        'totalCalories' => intval($stats['totalNutritionCalories']),
        'logCount' => intval($stats['nutritionLogCount']),
    ];
    $routineTotal = intval($stats['totalRoutines']);
    $routineCompleted = intval($stats['completedRoutines']);

    echo json_encode([
        "status" => "success",
        "data" => [
            "user" => $user ?: null,
            "latestHealthRecord" => $latestHealthRecord ?: null,
            "workoutStats" => [
                "totalCount" => intval($workoutStats['totalCount']),
                "totalDistance" => floatval($workoutStats['totalDistance']),
                "totalCalories" => floatval($workoutStats['totalCalories']),
                "totalDuration" => intval($workoutStats['totalDuration']),
            ],
            "nutritionToday" => [
                "totalCalories" => intval($nutritionToday['totalCalories']),
                "logCount" => intval($nutritionToday['logCount']),
            ],
            "goal" => $goal ?: null,
            "routines" => [
                "totalCount" => $routineTotal,
                "completedCount" => $routineCompleted,
            ],
        ],
        "serverTime" => date('Y-m-d H:i:s')
    ], JSON_UNESCAPED_UNICODE);

} catch (PDOException $e) {
    echo json_encode([
        "status" => "error",
        "message" => $e->getMessage()
    ]);
}
?>
