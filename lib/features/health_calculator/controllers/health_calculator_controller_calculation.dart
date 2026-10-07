part of 'health_calculator_controller.dart';

/// Extension จัดการการคำนวณและประมวลผลดัชนีสุขภาพ (BMI, BMR, TDEE, Calorie Targets)
extension HealthCalculatorCalculation on HealthCalculatorController {
  /// ดำเนินการคำนวณ BMI, BMR, TDEE และบันทึกลงประวัติสุขภาพ
  Future<void> calculate({
    bool recordHistory = false,
    bool syncToDb = false,
  }) async {
    // 1. คำนวณค่า BMI (ดัชนีมวลกาย)
    final calculatedBmi = HealthCalculator.calculateBMI(
      weightKg: _weight,
      heightCm: _height,
    );

    // 2. คำนวณค่า BMR (อัตราการเผาผลาญพลังงานพื้นฐาน)
    final calculatedBmr = HealthCalculator.calculateBMR(
      gender: _gender,
      weightKg: _weight,
      heightCm: _height,
      age: _age,
    );

    // 3. คำนวณค่า TDEE (อัตราการใช้พลังงานรวมในแต่ละวันตามระดับกิจกรรม)
    final calculatedTdee = HealthCalculator.calculateTDEE(
      bmr: calculatedBmr,
      activityMultiplier: _activityLevel.multiplier,
    );

    // 4. บันทึกผลลัพธ์ลงตัวแปรและจัดหมวดหมู่เกณฑ์ BMI
    _bmi = double.parse(calculatedBmi.toStringAsFixed(1));
    _bmr = calculatedBmr.roundToDouble();
    _tdee = calculatedTdee.roundToDouble();
    _bmiCategory = HealthCalculator.getBMICategory(_bmi);
    _targets = HealthCalculator.calculateTargets(_tdee);

    final activeUserId = _currentUser?.nUserId;
    if (activeUserId == null) {
      _safeNotifyListeners();
      return;
    }

    // 5. หากต้องการบันทึกลงประวัติการคำนวณ (History)
    if (recordHistory) {
      final newRecord = TbHealthRecord(
        nRecordId: 0,
        nUserId: activeUserId,
        nWeight: _weight,
        nHeight: _height,
        nBmi: _bmi,
        nTdee: _tdee,
        dtRecordedAt: DateTime.now(),
        computedBmr: _bmr,
        activityLevelTitle: _activityLevel.title,
      );

      // แทรกรายการใหม่ไว้บนสุดของประวัติ
      _historyList.insert(0, newRecord);

      // 6. บันทึกลง Local Database (isSynced = 0) แล้วสั่งซิงค์ขึ้น Cloud
      try {
        final savedRecord = await _db.insertHealthRecord(newRecord);
        if (!_isDisposed) {
          final index = _historyList.indexOf(newRecord);
          if (index != -1) {
            _historyList[index] = savedRecord;
            notifyListeners();
          }
        }
      } catch (e) {
        debugPrint('HealthCalculator: Failed to save record to DB: $e');
      }
    }

    // 7. แจ้งเตือนผู้ฟัง (Listeners)
    _safeNotifyListeners();
  }
}
