part of 'health_calculator_controller.dart';

extension HealthCalculatorCalculation on HealthCalculatorController {
  Future<void> calculate({
    bool recordHistory = false,
    bool syncToDb = false,
  }) async {
    final calculatedBmi = HealthCalculator.calculateBMI(
      weightKg: _weight,
      heightCm: _height,
    );

    final calculatedBmr = HealthCalculator.calculateBMR(
      gender: _gender,
      weightKg: _weight,
      heightCm: _height,
      age: _age,
    );

    final calculatedTdee = HealthCalculator.calculateTDEE(
      bmr: calculatedBmr,
      activityMultiplier: _activityLevel.multiplier,
    );

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

      _historyList.insert(0, newRecord);

      // บันทึกลง Local Database (isSynced = 0) แล้วซิงค์ขึ้น Cloud
      try {
        final savedRecord = await _db.insertHealthRecord(newRecord);
        if (!_isDisposed) {
          final index = _historyList.indexOf(newRecord);
          if (index != -1) {
            _historyList[index] = savedRecord;
            notifyListeners();
          }
        }
        // ซิงค์ขึ้น Cloud ในเบื้องหลังทันที
        await SyncService.instance.updatePendingCount();
        unawaited(SyncService.instance.syncPendingData());
      } catch (e) {
        debugPrint('Error saving health record to local db: $e');
      }
    }

    if (syncToDb) {
      _currentUser = TbUser(
        nUserId: activeUserId,
        sEmail: _currentUser?.sEmail ?? AuthService.instance.currentUserEmail,
        sPasswordHash: _currentUser?.sPasswordHash ?? '',
        sFirstName: _currentUser?.sFirstName ?? 'ผู้ใช้งาน',
        sLastName: _currentUser?.sLastName ?? '',
        nAge: _age,
        nHeight: _height,
        nWeight: _weight,
        sGender: _gender.name,
        sActivityLevel: _activityLevel.id,
        isDarkMode: _currentUser?.isDarkMode ?? false,
      );

      // อัปเดตลง Local Database & ส่งไปอัปเดตบน PHP Database Server
      final userToUpdate = _currentUser!;
      try {
        await _db.updateUser(userToUpdate);
      } catch (e) {
        debugPrint('Error updating user locally: $e');
      }
      try {
        await ProfileApiService.updateUserProfile(userToUpdate);
      } catch (e) {
        debugPrint('Error updating user profile to API: $e');
      }
    }

    _safeNotifyListeners();
  }
}
