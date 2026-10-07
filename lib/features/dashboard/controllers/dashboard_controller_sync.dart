part of 'dashboard_controller.dart';

/// Extension สำหรับการซิงค์ข้อมูล Dashboard จาก Remote Server
extension DashboardControllerSync on DashboardController {
  /// ดึงข้อมูลสรุปสุขภาพและเป้าหมายจากเซิร์ฟเวอร์มาอัปเดตลงในหน่วยความจำ local
  Future<void> _syncFromServer(int userId) async {
    try {
      // 1. เรียก API ดึงข้อมูล Dashboard รวม
      final serverData = await DashboardApiService.fetchDashboardData(
        userId: userId,
      );
      if (serverData != null) {
        final dataMap = serverData['data'] is Map<String, dynamic>
            ? serverData['data'] as Map<String, dynamic>
            : serverData;

        // 2. อัปเดตสถิติการออกกำลังกายรวม
        final wsMap = dataMap['workoutStats'] as Map<String, dynamic>?;
        if (wsMap != null) {
          workoutCount = (wsMap['totalCount'] as num?)?.toInt() ?? workoutCount;
          totalDistanceKm =
              (wsMap['totalDistance'] as num?)?.toDouble() ?? totalDistanceKm;
          totalCaloriesBurned =
              (wsMap['totalCalories'] as num?)?.toDouble() ??
              totalCaloriesBurned;
          totalWorkoutDurationSec =
              (wsMap['totalDuration'] as num?)?.toInt() ??
              totalWorkoutDurationSec;
        }

        // 3. อัปเดตแคลอรี่อาหารของวันนี้
        final ntMap = dataMap['nutritionToday'] as Map<String, dynamic>?;
        final serverCalories = (ntMap?['totalCalories'] as num?)?.toInt() ?? 0;
        // อัปเดตเฉพาะเมื่อ server มีค่ามากกว่า (ป้องกันการเขียนทับข้อมูลจาก AI Food Scanner ในเครื่อง)
        if (serverCalories > todayNutritionCalories) {
          todayNutritionCalories = serverCalories;
        }

        // 4. อัปเดตเป้าหมายหลัก
        final goalMap = dataMap['goal'] as Map<String, dynamic>?;
        if (goalMap != null) userGoal = goalMap;

        // 5. อัปเดตค่าวัดสุขภาพล่าสุด
        final hrMap = dataMap['latestHealthRecord'] as Map<String, dynamic>?;
        if (hrMap != null) latestRecord = TbHealthRecord.fromMap(hrMap);

        // 6. อัปเดตข้อมูลผู้ใช้
        final userMap = dataMap['user'] as Map<String, dynamic>?;
        if (userMap != null) user = TbUser.fromMap(userMap);

        // 7. แจ้งเตือน UI ให้รีเฟรชค่าใหม่
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Sync Error: $e');
    }
  }
}
