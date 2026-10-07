<?php
// ส่วนนี้เป็น API endpoint สำหรับบันทึกและอ่านข้อมูลโภชนาการ

require_once __DIR__ . "/../db_connect.php";

$method = $_SERVER['REQUEST_METHOD'];

switch ($method) {
    // 1. GET: ดึงประวัติการบันทึกอาหาร
    case 'GET':
        $userId = requireAuth();

        try {
            $stmt = $conn->prepare("SELECT * FROM TbNutritionLogs WHERE nUserId = :userId ORDER BY dtLoggedAt DESC");
            $stmt->execute([':userId' => $userId]);
            $logs = $stmt->fetchAll();

            echo json_encode([
                "status" => "success",
                "data" => $logs
            ], JSON_UNESCAPED_UNICODE);
        } catch (PDOException $e) {
            echo json_encode([
                "status" => "error",
                "message" => $e->getMessage()
            ]);
        }
        break;

    // 2. POST: บันทึกข้อมูลมื้ออาหาร (Sync จากเครื่องขึ้นเซิร์ฟเวอร์)
    case 'POST':
        $data = json_decode(file_get_contents("php://input"), true);

        if (!$data) {
            $data = $_POST;
        }

        $userId = requireAuth();
        $mealType = isset($data['sMealType']) ? trim($data['sMealType']) : 'breakfast';
        $foodName = isset($data['sFoodName']) ? trim($data['sFoodName']) : 'อาหารทั่วไป';
        $calories = isset($data['nCalories']) ? intval($data['nCalories']) : 0;
        $protein = isset($data['nProtein']) ? floatval($data['nProtein']) : 0.0;
        $carbs = isset($data['nCarbs']) ? floatval($data['nCarbs']) : 0.0;
        $fat = isset($data['nFat']) ? floatval($data['nFat']) : 0.0;
        $servingSize = isset($data['sServingSize']) ? trim($data['sServingSize']) : '';
        $imagePath = isset($data['sImagePath']) ? trim($data['sImagePath']) : '';
        $loggedAt = isset($data['dtLoggedAt']) ? $data['dtLoggedAt'] : date('Y-m-d H:i:s');

        try {
            $stmt = $conn->prepare("
                INSERT INTO TbNutritionLogs (nUserId, sMealType, sFoodName, nCalories, nProtein, nCarbs, nFat, sServingSize, sImagePath, isSynced, dtUpdatedAt, dtLoggedAt)
                VALUES (:userId, :mealType, :foodName, :calories, :protein, :carbs, :fat, :servingSize, :imagePath, 1, NOW(), :loggedAt)
            ");
            $stmt->execute([
                ':userId' => $userId,
                ':mealType' => $mealType,
                ':foodName' => $foodName,
                ':calories' => $calories,
                ':protein' => $protein,
                ':carbs' => $carbs,
                ':fat' => $fat,
                ':servingSize' => $servingSize,
                ':imagePath' => $imagePath,
                ':loggedAt' => $loggedAt
            ]);

            $newNutritionId = $conn->lastInsertId();

            echo json_encode([
                "status" => "success",
                "message" => "Nutrition log saved successfully",
                "nNutritionId" => $newNutritionId
            ], JSON_UNESCAPED_UNICODE);
        } catch (PDOException $e) {
            echo json_encode([
                "status" => "error",
                "message" => $e->getMessage()
            ]);
        }
        break;

    // 3. DELETE: ลบรายการมื้ออาหารตาม nNutritionId
    case 'DELETE':
        $userId = requireAuth();
        $nutritionId = isset($_GET['nNutritionId']) ? intval($_GET['nNutritionId']) : null;

        if (!$nutritionId) {
            $data = json_decode(file_get_contents("php://input"), true);
            $nutritionId = isset($data['nNutritionId']) ? intval($data['nNutritionId']) : null;
        }

        if (!$nutritionId) {
            http_response_code(400);
            echo json_encode([
                "status" => "error",
                "message" => "Missing nNutritionId"
            ]);
            exit();
        }

        try {
            $stmt = $conn->prepare("DELETE FROM TbNutritionLogs WHERE nNutritionId = :nutritionId AND nUserId = :userId");
            $stmt->execute([
                ':nutritionId' => $nutritionId,
                ':userId' => $userId
            ]);

            echo json_encode([
                "status" => "success",
                "message" => "ลบรายการอาหารสำเร็จ"
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
