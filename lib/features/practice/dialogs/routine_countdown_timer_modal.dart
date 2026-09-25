import 'dart:async';
import 'package:flutter/material.dart';

/// Mini Countdown Timer Dialog Widget
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

class _RoutineCountdownTimerModalState
    extends State<RoutineCountdownTimerModal> {
  late int _secondsRemaining;
  late int _totalSeconds;
  Timer? _timer;
  bool _isRunning = false;
  DateTime? _timerEndTime;

  @override
  void initState() {
    super.initState();
    _totalSeconds = widget.durationMinutes * 60;
    if (_totalSeconds <= 0) _totalSeconds = 60;
    _secondsRemaining = _totalSeconds;
    _startTimer();
  }

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
  Widget build(BuildContext context) {
    final double progress = _totalSeconds > 0
        ? (1.0 - (_secondsRemaining / _totalSeconds))
        : 1.0;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8F3EB),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.timer_rounded,
                    color: Color(0xFF2E5327),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'จับเวลาโฟกัส',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E281F),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Circular Countdown Display
            SizedBox(
              width: 180,
              height: 180,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 180,
                    height: 180,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 10,
                      backgroundColor: const Color(0xFFE2E9E0),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF2E5327),
                      ),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _formattedTime,
                        style: const TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF2E5327),
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isRunning ? 'กำลังจับเวลา...' : 'พักชั่วคราว',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _isRunning
                              ? const Color(0xFF2E5327)
                              : Colors.orange.shade800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Play / Pause Button
                ElevatedButton.icon(
                  onPressed: _isRunning ? _pauseTimer : _startTimer,
                  icon: Icon(
                    _isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: Colors.white,
                  ),
                  label: Text(
                    _isRunning ? 'พักชั่วคราว' : 'เริ่มต่อ',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E5327),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),

                // Finish early button
                OutlinedButton.icon(
                  onPressed: () {
                    _timer?.cancel();
                    Navigator.of(context).pop();
                    widget.onTimerCompleted();
                  },
                  icon: const Icon(
                    Icons.check_circle_outline,
                    color: Color(0xFF2E5327),
                  ),
                  label: const Text(
                    'เสร็จแล้ว',
                    style: TextStyle(
                      color: Color(0xFF2E5327),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    side: const BorderSide(
                      color: Color(0xFF2E5327),
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
