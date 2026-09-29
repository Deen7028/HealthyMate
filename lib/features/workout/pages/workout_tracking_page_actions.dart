part of 'workout_tracking_page.dart';

extension WorkoutTrackingPageActions on _WorkoutTrackingPageState {
  Future<void> _handleStartWorkout() async {
    await _state.ensureUserDataLoaded();
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
    if (!_state.isGpsEnabled) {
      final hasGps = await this._initCurrentLocation();
      if (!hasGps) {
        return;
      }
    }
    _state.startWorkout();
  }

  void _handleStopWorkout() {
    _state.pauseWorkout();
    WorkoutStopActionSheet.showStopActionSheet(
      context: context,
      timeFormatted: _state.formatTime(_state.secondsElapsed),
      distanceKm: _state.distanceKm,
      caloriesBurned: _state.caloriesBurned,
      onSave: () async {
        final calBurned = _state.caloriesBurned;
        await _state.saveWorkout();
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
      onResume: () => this._handleStartWorkout(),
    );
  }
}
