import 'package:flutter/material.dart';

class WorkoutBottomControls extends StatefulWidget {
  final bool isRunning;
  final bool isPaused;
  final bool canStop;
  final VoidCallback onStartOrResume;
  final VoidCallback onPause;
  final VoidCallback onStop;

  const WorkoutBottomControls({
    super.key,
    required this.isRunning,
    required this.isPaused,
    required this.canStop,
    required this.onStartOrResume,
    required this.onPause,
    required this.onStop,
  });

  @override
  State<WorkoutBottomControls> createState() => _WorkoutBottomControlsState();
}

class _WorkoutBottomControlsState extends State<WorkoutBottomControls>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseRippleController;

  @override
  void initState() {
    super.initState();
    _pulseRippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    if (widget.isPaused) {
      _pulseRippleController.repeat();
    }
  }

  @override
  void didUpdateWidget(WorkoutBottomControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPaused && !oldWidget.isPaused) {
      _pulseRippleController.repeat();
    } else if (!widget.isPaused && oldWidget.isPaused) {
      _pulseRippleController.stop();
      _pulseRippleController.reset();
    }
  }

  @override
  void dispose() {
    _pulseRippleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 28, right: 28, top: 22, bottom: 30),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAF8).withValues(alpha: 0.97),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
        border: Border.all(color: Colors.white, width: 1.2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildActionButton(
            label: 'หยุด',
            icon: Icons.stop_rounded,
            color: const Color(0xFFFEE6E6),
            iconColor: const Color(0xFFD32F2F),
            size: 58,
            iconSize: 28,
            enabled: widget.canStop,
            onTap: widget.canStop ? widget.onStop : null,
          ),
          _buildMainCenterButton(),
          _buildActionButton(
            label: 'ชั่วคราว',
            icon: Icons.pause_rounded,
            color: const Color(0xFFEAEFEA),
            iconColor: const Color(0xFF5A665A),
            size: 58,
            iconSize: 28,
            enabled: widget.isRunning,
            onTap: widget.isRunning ? widget.onPause : null,
          ),
        ],
      ),
    );
  }

  Widget _buildMainCenterButton() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () {
            if (widget.isRunning) {
              widget.onPause();
            } else {
              widget.onStartOrResume();
            }
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 4. แอนิเมชันคลื่นน้ำเรียกร้องความสนใจ (Pulse / Ripple Effect) เมื่ออยู่ในสถานะ พักชั่วคราว (Pause)
              if (widget.isPaused)
                AnimatedBuilder(
                  animation: _pulseRippleController,
                  builder: (context, child) {
                    final wave = _pulseRippleController.value;
                    return Container(
                      width: 82 + (wave * 34),
                      height: 82 + (wave * 34),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF2E5327).withValues(alpha: (1.0 - wave) * 0.45),
                      ),
                    );
                  },
                ),
              Container(
                width: 82,
                height: 82,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF2E5327),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2E5327).withValues(alpha: 0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return RotationTransition(
                      turns: child.key == const ValueKey('pause')
                          ? Tween<double>(begin: 0.5, end: 1.0).animate(animation)
                          : Tween<double>(begin: 0.0, end: 0.5).animate(animation),
                      child: ScaleTransition(scale: animation, child: child),
                    );
                  },
                  child: Icon(
                    widget.isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    key: ValueKey(widget.isRunning ? 'pause' : 'play'),
                    color: Colors.white,
                    size: 44,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.isRunning ? 'พักชั่วคราว' : (widget.isPaused ? 'ทำต่อ' : 'เริ่ม'),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: Color(0xFF2E5327),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required Color iconColor,
    required double size,
    required double iconSize,
    required bool enabled,
    VoidCallback? onTap,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: enabled ? onTap : null,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: enabled ? 1.0 : 0.4,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                boxShadow: enabled
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Icon(icon, color: iconColor, size: iconSize),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: enabled ? const Color(0xFF5A665A) : const Color(0xFFA0ACA0),
          ),
        ),
      ],
    );
  }
}
