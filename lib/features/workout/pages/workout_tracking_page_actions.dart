// ส่วนนี้อธิบายบทบาทของไฟล์: หน้าจอหลัก ในฟีเจอร์การติดตามและประวัติการออกกำลังกาย (workout tracking page actions)
// คอมเมนท์ภาษาไทยถูกใส่ไว้เป็นส่วนๆ เพื่อช่วยไล่ flow โดยไม่เปลี่ยนพฤติกรรมเดิมของโค้ด

part of 'workout_tracking_page.dart';

/// ส่วนขยายจัดการ Event และ Action ปุ่มกดของหน้าจอออกกำลังกาย (Workout UI Event Handlers)
extension WorkoutTrackingPageActions on _WorkoutTrackingPageState {
  /// จัดการการกดปุ่มเริ่มต้นออกกำลังกาย (ตรวจสิทธิ์ User และ GPS พร้อมรัน)
  Future<void> _handleStartWorkout() async {
    // 1. ยืนยันว่าโหลดข้อมูลโปรไฟล์ผู้ใช้เสร็จสมบูรณ์แล้ว
    await _state.ensureUserDataLoaded();

    // 2. ตรวจสอบว่าผู้ใช้ล็อกอินเข้าสู่ระบบแล้วหรือยัง
    if (!_state.hasAuthenticatedUser) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('กรุณาเข้าสู่ระบบก่อนบันทึกการออกกำลังกาย'),
          ),
        );
      }
      return;
    }

    // 3. ตรวจสอบความพร้อมของสัญญาณและสิทธิ์ GPS
    if (!_state.isGpsEnabled) {
      final hasGps = await this._initCurrentLocation();
      if (!hasGps) {
        return; // หากผู้ใช้ปฏิเสธสิทธิ์ GPS ไม่เริ่มกิจกรรม
      }
    }

    // 4. เริ่มต้นนับเวลา บันทึกพิกัด และรัน Background Service
    _state.startWorkout();
  }

  /// จัดการการกดปุ่มหยุดกิจกรรม (แสดง ActionSheet ให้เลือก บันทึก / ละทิ้ง / เล่นต่อ)
  void _handleStopWorkout() {
    // 1. สั่ง Pause หยุดเวลาและสตรีมพิกัดชั่วคราว
    _state.pauseWorkout();

    // 2. แสดง Modal Bottom Sheet สรุปเวลา ระยะทาง แคลอรี
    WorkoutStopActionSheet.showStopActionSheet(
      context: context,
      timeFormatted: _state.formatTime(_state.secondsElapsed),
      distanceKm: _state.distanceKm,
      caloriesBurned: _state.caloriesBurned,

      // กรณีผู้ใช้เลือกกด "บันทึกกิจกรรม" (Save Workout)
      onSave: () async {
        final calBurned = _state.caloriesBurned;

        // แสดงแจ้งเตือนกำลังประมวลผล Map Matching & Polyline Compression หากมีจุดพิกัดเกิน 3 จุด
        if (mounted && _state.routePoints.length >= 3) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('กำลังปรับเทียบพิกัดถนน (Map Matching) และบีบอัดเส้นทาง...'),
                ],
              ),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }

        // ประมวลผลและบันทึกลง SQLite / Cloud
        await _state.saveWorkout();

        // แจ้งเตือนบันทึกสำเร็จ
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'บันทึกกิจกรรมเรียบร้อย! เผาผลาญ ${calBurned.toStringAsFixed(0)} kcal',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF2E5327),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      },

      // กรณีผู้ใช้เลือกกด "ละทิ้งกิจกรรม" (Discard Workout)
      onDiscard: () {
        _state.discardWorkout();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.delete_sweep_rounded, color: Colors.white),
                SizedBox(width: 10),
                Text('ละทิ้งกิจกรรมการออกกำลังกายแล้ว'),
              ],
            ),
            backgroundColor: Colors.grey.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      },

      // กรณีผู้ใช้เลือกกด "ออกกำลังกายต่อ" (Resume Workout)
      onResume: () => this._handleStartWorkout(),
    );
  }
}
