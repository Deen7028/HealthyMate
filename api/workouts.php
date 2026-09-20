<?php
require_once "db_connect.php";

$method = $_SERVER['REQUEST_METHOD'];

switch ($method) {
    // 1. GET: ดึงประวัติการออกกำลังกาย
    case 'GET':
        $userId = isset($_GET['nUserId']) ? intval($_GET['nUserId']) : 1;

        try {
            $stmt = $conn->prepare("SELECT * FROM TbWorkouts WHERE nUserId = :userId ORDER BY dtWorkoutDate DESC");
            $stmt->execute([':userId' => $userId]);
            $workouts = $stmt->fetchAll();

            echo json_encode([
                "status" => "success",
                "data" => $workouts
            ], JSON_UNESCAPED_UNICODE);
        } catch (PDOException $e) {
            echo json_encode([
                "status" => "error",
                "message" => $e->getMessage()
            ]);
        }
        break;

    // 2. POST: บันทึกประวัติการออกกำลังกาย (Sync จากเครื่องขึ้นเซิร์ฟเวอร์)
    case 'POST':
        $data = json_decode(file_get_contents("php://input"), true);

        if (!$data) {
            $data = $_POST;
        }

        $userId = isset($data['nUserId']) ? intval($data['nUserId']) : 1;
        $type = isset($data['sType']) ? trim($data['sType']) : 'วิ่ง';
        $distance = isset($data['nDistance']) ? floatval($data['nDistance']) : 0.0;
        $duration = isset($data['nDuration']) ? intval($data['nDuration']) : 0;
        $calories = isset($data['nCaloriesBurned']) ? floatval($data['nCaloriesBurned']) : 0.0;
        $routePoints = isset($data['sRoutePoints']) ? (is_string($data['sRoutePoints']) ? $data['sRoutePoints'] : json_encode($data['sRoutePoints'])) : '';
        $workoutDate = isset($data['dtWorkoutDate']) ? $data['dtWorkoutDate'] : date('Y-m-d H:i:s');

        try {
            $stmt = $conn->prepare("
                INSERT INTO TbWorkouts (nUserId, sType, nDistance, nDuration, nCaloriesBurned, sRoutePoints, isSynced, dtUpdatedAt, dtWorkoutDate)
                VALUES (:userId, :type, :distance, :duration, :calories, :routePoints, 1, NOW(), :workoutDate)
            ");
            $stmt->execute([
                ':userId' => $userId,
                ':type' => $type,
                ':distance' => $distance,
                ':duration' => $duration,
                ':calories' => $calories,
                ':routePoints' => $routePoints,
                ':workoutDate' => $workoutDate
            ]);

            $newWorkoutId = $conn->lastInsertId();

            echo json_encode([
                "status" => "success",
                "message" => "Workout saved successfully",
                "nWorkoutId" => $newWorkoutId
            ], JSON_UNESCAPED_UNICODE);
        } catch (PDOException $e) {
            echo json_encode([
                "status" => "error",
                "message" => $e->getMessage()
            ]);
        }
        break;

    default:
        http_response_code(405);
        echo json_encode([
            "status" => "error",
            "message" => "Method not allowed"
        ]);
        break;
}
?>
