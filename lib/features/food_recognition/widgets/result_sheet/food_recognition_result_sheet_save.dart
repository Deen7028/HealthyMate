part of 'food_recognition_result_sheet.dart';

// ส่วนขยายการบันทึกข้อมูลมื้ออาหารและซิงค์กิจวัตร (Result Sheet Save & Routine Sync Extension)
extension _FoodRecognitionResultSheetSave on _FoodRecognitionResultSheetState {
  // ฟังก์ชัน: บันทึกข้อมูลโภชนาการลง SQLite และซิงค์กับกิจวัตรอัตโนมัติ (Save Meal To Database)
  Future<void> _saveMealToDatabase() async {
    // 1. ตรวจสอบว่ามีรายการอาหารอย่างน้อย 1 รายการ
    if (_result.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ไม่มีรายการอาหารในมื้อนี้ กรุณาเพิ่มรายการอาหาร'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // 2. ดึงข้อมูล User ID ปัจจุบัน
      final user = await AppDatabase.instance.getCurrentUser();
      final userId = user?.nUserId;
      if (userId == null) return;

      // 3. บันทึกข้อมูลอาหารแต่ละรายการลงตาราง Nutrition Logs
      for (final item in _result.items) {
        await AppDatabase.instance.insertNutritionLog(
          userId: userId,
          mealType: _result.category.key,
          foodName: item.name,
          calories: item.calories,
          protein: item.protein,
          carbs: item.carbs,
          fat: item.fat,
          servingSize: item.servingSize,
          imagePath: _result.imagePath,
        );
      }

      // 4. Auto-Routine Sync: ตรวจจับและอัปเดตเป้าหมายกิจวัตรให้อัตโนมัติ (Protein & Meals)
      final autoSyncedRoutines = <String>[];
      final routines = await AppDatabase.instance.getRoutines(userId: userId);
      final todayStr = DateTime.now().toIso8601String().substring(0, 10);

      for (final r in routines) {
        final routineId = (r['nRoutineId'] as num?)?.toInt() ?? 0;
        final title = (r['sTitle']?.toString() ?? '').toLowerCase();
        final unit = (r['unit']?.toString() ?? (r['sUnit']?.toString() ?? ''))
            .toLowerCase();

        if (routineId <= 0) continue;

        // 1. ซิงค์โปรตีน
        if (title.contains('โปรตีน') ||
            unit.contains('g') ||
            unit.contains('กรัม') ||
            unit.contains('โปรตีน')) {
          if (_result.totalProtein > 0) {
            final targetVal = (r['targetValue'] as num?)?.toDouble() ?? 1.0;
            final existingLogs = await AppDatabase.instance
                .getRoutineLogsForDate(userId: userId, dateStr: todayStr);
            final currentLog = existingLogs.firstWhere(
              (l) => (l['nRoutineId'] as num?)?.toInt() == routineId,
              orElse: () => {},
            );
            final currentProgress =
                (currentLog['nProgressValue'] as num?)?.toDouble() ?? 0.0;
            final newProgress = currentProgress + _result.totalProtein;
            final isDone = newProgress >= targetVal;

            await AppDatabase.instance.insertOrUpdateRoutineLog(
              routineId: routineId,
              dateStr: todayStr,
              progressValue: newProgress,
              isCompleted: isDone,
            );
            // ซิงค์ขึ้น Server
            GoalApiService.updateRoutineProgressRemote(
              routineId: routineId,
              date: todayStr,
              progressValue: newProgress,
              isCompleted: isDone,
            );
            autoSyncedRoutines.add(
              'โปรตีน (+${_result.totalProtein.toStringAsFixed(1)}g)',
            );
          }
        }
        // 2. ซิงค์มื้ออาหาร / ผัก / ผลไม้
        else if (title.contains('มื้อ') ||
            title.contains('อาหาร') ||
            title.contains('ผัก') ||
            title.contains('สลัด') ||
            title.contains('ผลไม้')) {
          await AppDatabase.instance.insertOrUpdateRoutineLog(
            routineId: routineId,
            dateStr: todayStr,
            progressValue: 1.0,
            isCompleted: true,
          );
          // ซิงค์ขึ้น Server
          GoalApiService.updateRoutineProgressRemote(
            routineId: routineId,
            date: todayStr,
            progressValue: 1.0,
            isCompleted: true,
          );
          autoSyncedRoutines.add('${r['sTitle']} (เสร็จแล้ว)');
        }
      }

      // Notify RoutineStateNotifier to reload state across the app
      RoutineStateNotifier.instance.loadData(userId: userId);

      // ส่งสัญญาณให้อัปเดตสถานะค้างซิงค์ และซิงค์ขึ้น Cloud ในเบื้องหลังทันที
      SyncService.instance.updatePendingCount();
      SyncService.instance.syncPendingData();

      if (mounted) {
        Navigator.pop(context);
        final String syncMsg = autoSyncedRoutines.isNotEmpty
            ? '\n🎯 ซิงค์กิจวัตรสำเร็จ: ${autoSyncedRoutines.join(', ')}'
            : '';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'บันทึกมื้อ${_result.category.label} (${_result.totalCalories} kcal) สำเร็จ!$syncMsg',
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.primaryGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
        widget.onSavedSuccessfully?.call();
      }
    } catch (e) {
      debugPrint('Error saving nutrition log: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาดในการบันทึก: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
