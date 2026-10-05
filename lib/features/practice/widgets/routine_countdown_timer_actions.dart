// ส่วนนี้อธิบายบทบาทของไฟล์: วิดเจ็ตย่อยของ UI ในฟีเจอร์กิจวัตรและเป้าหมายประจำวัน (routine countdown timer actions)
// คอมเมนท์ภาษาไทยถูกใส่ไว้เป็นส่วนๆ เพื่อช่วยไล่ flow โดยไม่เปลี่ยนพฤติกรรมเดิมของโค้ด

part of 'routine_countdown_timer_modal.dart';

extension RoutineCountdownTimerActions on _RoutineCountdownTimerModalState {
  void _startTimer() {
    _timer?.cancel();
    _timerEndTime = DateTime.now().add(Duration(seconds: _secondsRemaining));
    setState(() => _isRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _timerEndTime == null) return;
      final remaining = _timerEndTime!.difference(DateTime.now()).inSeconds;
      if (remaining > 0) {
        setState(() {
          _secondsRemaining = remaining;
        });
      } else {
        _timer?.cancel();
        setState(() {
          _secondsRemaining = 0;
          _isRunning = false;
        });
        AudioService.instance.playTimerComplete();
        if (mounted) {
          Navigator.of(context).pop();
          widget.onTimerCompleted();
        }
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    _timerEndTime = null;
    setState(() => _isRunning = false);
  }
}
