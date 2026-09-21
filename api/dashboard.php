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

$userId = isset($_GET['nUserId']) ? intval($_GET['nUserId']) : 1;
$today = date('Y-m-d');

try {
    // 1. ข้อมูลผู้ใช้
    $stmtUser = $conn->prepare("SELECT * FROM TbUsers WHERE nUserId = :userId LIMIT 1");
    $stmtUser->execute([':userId' => $userId]);
    $user = $stmtUser->fetch();

    // 2. Health Record ล่าสุด
    $stmtHR = $conn->prepare("
        SELECT * FROM TbHealthRecords 
        WHERE nUserId = :userId 
        ORDER BY dtRecordedAt DESC 
        LIMIT 1
    ");
    $stmtHR->execute([':userId' => $userId]);
    $latestHealthRecord = $stmtHR->fetch();

    // 3. สถิติ Workouts
    $stmtWorkout = $conn->prepare("
        SELECT 
            COUNT(*) as totalCount,
            COALESCE(SUM(nDistance), 0) as totalDistance,
            COALESCE(SUM(nCaloriesBurned), 0) as totalCalories,
            COALESCE(SUM(nDuration), 0) as totalDuration
        FROM TbWorkouts 
        WHERE nUserId = :userId
    ");
    $stmtWorkout->execute([':userId' => $userId]);
    $workoutStats = $stmtWorkout->fetch();

    // 4. Nutrition วันนี้
    $stmtNutrition = $conn->prepare("
        SELECT COALESCE(SUM(nCalories), 0) as totalCalories, COUNT(*) as logCount
        FROM TbNutritionLogs 
        WHERE nUserId = :userId AND dtLoggedAt LIKE :today
    ");
    $stmtNutrition->execute([':userId' => $userId, ':today' => "$today%"]);
    $nutritionToday = $stmtNutrition->fetch();

    // 5. เป้าหมายหลัก
    $stmtGoal = $conn->prepare("
        SELECT * FROM TbGoals 
        WHERE nUserId = :userId 
        ORDER BY nGoalId DESC 
        LIMIT 1
    ");
    $stmtGoal->execute([':userId' => $userId]);
    $goal = $stmtGoal->fetch();

    // 6. กิจวัตรสำเร็จวันนี้
    $stmtRoutineCount = $conn->prepare("
        SELECT COUNT(*) as totalRoutines FROM TbRoutines WHERE nUserId = :userId
    ");
    $stmtRoutineCount->execute([':userId' => $userId]);
    $routineTotal = intval($stmtRoutineCount->fetch()['totalRoutines']);

    $stmtRoutineCompleted = $conn->prepare("
        SELECT COUNT(*) as completedRoutines FROM TbRoutineLogs rl
        INNER JOIN TbRoutines r ON rl.nRoutineId = r.nRoutineId
        WHERE r.nUserId = :userId AND rl.dtLogDate = :today AND rl.isCompleted = 1
    ");
    $stmtRoutineCompleted->execute([':userId' => $userId, ':today' => $today]);
    $routineCompleted = intval($stmtRoutineCompleted->fetch()['completedRoutines']);

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
