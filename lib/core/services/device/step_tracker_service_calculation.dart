part of 'step_tracker_service.dart';

// ส่วนคำนวณระยะทาง แคลอรี และหักลบก้าวที่ทับซ้อนกับการออกกำลังกาย (Step Tracker Calculation Extension)
extension StepTrackerCalculation on StepTrackerService {
  // คำนวณความยาวก้าว (Stride Length) เป็นเมตรตามส่วนสูงและเพศ
  double calculateStrideMeters(double nHeightCm, String sGender) {
    final double nValidHeight = nHeightCm > 0 ? nHeightCm : 170.0;
    final String sLowerGender = sGender.toLowerCase();
    final double nFactor = (sLowerGender.contains('female') ||
            sLowerGender.contains('หญิง') ||
            sLowerGender == 'f')
        ? 0.413
        : 0.415;
    return (nValidHeight * nFactor) / 100.0;
  }

  // คำนวณระยะทางเป็นกิโลเมตรจากจำนวนก้าว
  double calculateDistanceKm(
    int nSteps,
    double nHeightCm,
    String sGender,
  ) {
    if (nSteps <= 0) return 0.0;
    final double nStrideMeters = calculateStrideMeters(nHeightCm, sGender);
    final double nDistanceMeters = nSteps * nStrideMeters;
    return double.parse((nDistanceMeters / 1000.0).toStringAsFixed(2));
  }

  // คำนวณแคลอรีที่เผาผลาญจากการเดิน
  double calculateCaloriesBurned(int nSteps, double nWeightKg) {
    if (nSteps <= 0) return 0.0;
    final double nValidWeight = nWeightKg > 0 ? nWeightKg : 65.0;
    // สูตรอ้างอิง: การเดินทั่วไป 1 ก้าวเผาผลาญประมาณ 0.04 - 0.05 kcal ตามน้ำหนักตัวมาตรฐาน 65-70 กก.
    final double nCalPerStep = 0.04 * (nValidWeight / 65.0);
    final double nCalories = nSteps * nCalPerStep;
    return double.parse(nCalories.toStringAsFixed(1));
  }

  // หักลบจำนวนก้าวที่เกิดขึ้นระหว่างช่วงเวลาที่ผู้ใช้กดจับเวลาเองในแอป (Smart Time-Window Deduplication)
  int filterOverlappingSteps({
    required List<HealthDataPoint> lstPoints,
    required List<Map<String, dynamic>> lstWorkouts,
  }) {
    // 1. รวบรวมช่วงเวลาเริ่มต้นและสิ้นสุดของกิจกรรมเดิน/วิ่งที่มีการจับเวลาจริง (nDuration > 0)
    final List<Map<String, DateTime>> lstExcludedWindows = [];

    for (final objWorkout in lstWorkouts) {
      final int nDuration = (objWorkout['nDuration'] as num?)?.toInt() ?? 0;
      if (nDuration <= 0) continue; // ข้ามรายการที่ไม่มีเวลา เช่น รายการสรุปก้าวสะสมเดิม

      final String sDateStr = objWorkout['dtWorkoutDate']?.toString() ?? '';
      final DateTime? dtEnd = DateTime.tryParse(sDateStr);
      if (dtEnd == null) continue;

      final DateTime dtStart = dtEnd.subtract(Duration(seconds: nDuration));
      lstExcludedWindows.add({
        'start': dtStart,
        'end': dtEnd,
      });
    }

    // 2. คัดกรองข้อมูลก้าวจากเซ็นเซอร์ โดยตัดจุดที่ตกอยู่ในช่วงเวลาที่ทับซ้อนออก
    int nTotalNetSteps = 0;

    for (final objPoint in lstPoints) {
      if (objPoint.type != HealthDataType.STEPS) continue;

      final dynamic rawVal = objPoint.value;
      int nStepVal = 0;
      if (rawVal is NumericHealthValue) {
        nStepVal = rawVal.numericValue.toInt();
      } else {
        nStepVal = int.tryParse(rawVal.toString()) ?? 0;
      }

      if (nStepVal <= 0) continue;

      final DateTime dtPointFrom = objPoint.dateFrom;
      final DateTime dtPointTo = objPoint.dateTo;

      // ตรวจสอบว่าช่วงเวลานี้ทับซ้อนกับกิจกรรมที่จับเวลาเองหรือไม่
      bool isOverlapping = false;
      for (final objWindow in lstExcludedWindows) {
        final DateTime dtStart = objWindow['start']!;
        final DateTime dtEnd = objWindow['end']!;

        // หากเวลาคร่อมกัน ถือว่าทับซ้อน
        final bool isBeforeEnd = dtPointFrom.isBefore(dtEnd);
        final bool isAfterStart = dtPointTo.isAfter(dtStart);

        if (isBeforeEnd && isAfterStart) {
          isOverlapping = true;
          break;
        }
      }

      if (!isOverlapping) {
        nTotalNetSteps += nStepVal;
      }
    }

    return nTotalNetSteps;
  }
}
