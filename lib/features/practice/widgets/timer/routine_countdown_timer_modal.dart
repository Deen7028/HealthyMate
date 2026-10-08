import 'dart:async';
import 'package:flutter/material.dart';
import 'package:healthymate/core/services/device/audio_service.dart';
import 'package:healthymate/shared/theme/app_theme.dart';

// Modal หลักสำหรับนับเวลาถอยหลังการทำกิจวัตร (Countdown Timer Modal)
part 'routine_countdown_timer_actions.dart';
part 'routine_countdown_timer_content.dart';
class RoutineCountdownTimerModal extends StatefulWidget {
  final String title;
  final int durationMinutes;
  final VoidCallback onTimerCompleted;

  const RoutineCountdownTimerModal({
    super.key,
    required this.title,
    required this.durationMinutes,
    required this.onTimerCompleted,
  });

  @override
  State<RoutineCountdownTimerModal> createState() =>
      _RoutineCountdownTimerModalState();
}
// ตรรกะการทำงานภายใน (Stateful Logic)
class _RoutineCountdownTimerModalState
    extends State<RoutineCountdownTimerModal> {
  late int _secondsRemaining;
  late int _totalSeconds;
  Timer? _timer;
  bool _isRunning = false;
  DateTime? _timerEndTime;
// วงจรชีวิตของ widget (State Lifecycle)
  @override
  void initState() {
    super.initState();
    _totalSeconds = widget.durationMinutes * 60;
    if (_totalSeconds <= 0) _totalSeconds = 60;
    _secondsRemaining = _totalSeconds;
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _formattedTime {
    final minutes = (_secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsRemaining % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) => _buildCountdownModal(context);
}
