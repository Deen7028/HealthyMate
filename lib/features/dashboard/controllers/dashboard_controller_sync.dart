// ส่วนนี้อธิบายบทบาทของไฟล์: คอนโทรลเลอร์และ state ของหน้าจอ ในฟีเจอร์แดชบอร์ดสรุปสุขภาพและเป้าหมาย (dashboard controller sync)
// คอมเมนท์ภาษาไทยถูกใส่ไว้เป็นส่วนๆ เพื่อช่วยไล่ flow โดยไม่เปลี่ยนพฤติกรรมเดิมของโค้ด

part of 'dashboard_controller.dart';

/// Extension สำหรับการซิงค์ข้อมูล Dashboard จาก Remote Server
extension DashboardControllerSync on DashboardController {
  /// ดึงข้อมูลสรุปสุขภาพและเป้าหมายจากเซิร์ฟเวอร์มาอัปเดตลงในหน่วยความจำ local
  Future<void> _syncFromServer(int userId) async {
    try {
      final serverData = await DashboardApiService.fetchDashboardData(
        userId: userId,
      );
      if (serverData != null) {
        final dataMap = serverData['data'] is Map<String, dynamic>
            ? serverData['data'] as Map<String, dynamic>
            : serverData;

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

        final ntMap = dataMap['nutritionToday'] as Map<String, dynamic>?;
        final serverCalories = (ntMap?['totalCalories'] as num?)?.toInt() ?? 0;
        // อัปเดตแคลอรี่จาก server เฉพาะเมื่อ server มีค่ามากกว่า (ป้องกันการเขียนทับข้อมูลจาก AI Food Scanner ในเครื่อง)
        if (serverCalories > todayNutritionCalories) {
          todayNutritionCalories = serverCalories;
        }

        final goalMap = dataMap['goal'] as Map<String, dynamic>?;
        if (goalMap != null) userGoal = goalMap;

        final hrMap = dataMap['latestHealthRecord'] as Map<String, dynamic>?;
        if (hrMap != null) latestRecord = TbHealthRecord.fromMap(hrMap);

        final userMap = dataMap['user'] as Map<String, dynamic>?;
        if (userMap != null) user = TbUser.fromMap(userMap);

        notifyListeners();
      }
    } catch (e) {
      debugPrint('Sync Error: $e');
    }
  }
}
