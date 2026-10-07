import 'package:flutter/material.dart';
import '../models/routine_item.dart';

class RoutineCard extends StatelessWidget {
  final RoutineItem routine;
  final ValueChanged<bool> onToggleNotification;
  final VoidCallback? onDelete;

  const RoutineCard({
    super.key,
    required this.routine,
    required this.onToggleNotification,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left Icon Badge Container
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F0), // Pale soft green grey
              shape: BoxShape.circle,
            ),
            child: Icon(
              routine.iconData,
              color: const Color(0xFF2E5327), // Deep Forest Green
              size: 24,
            ),
          ),
          const SizedBox(width: 16),

          // Title & Subtitle Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  routine.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1C2819),
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  routine.notificationTime,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF768275),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Custom Notification Switch (Green Track + Blue Checkmark Thumb)
          Transform.scale(
            scale: 0.95,
            child: Switch(
              value: routine.isNotificationEnabled,
              onChanged: onToggleNotification,
              activeTrackColor: const Color(0xFF2E5327), // Forest Green track
              activeThumbColor: const Color(0xFF2563EB), // Vibrant Blue Circle Thumb
              thumbIcon: WidgetStateProperty.resolveWith<Icon?>((states) {
                if (states.contains(WidgetState.selected)) {
                  return const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 14,
                  );
                }
                return null;
              }),
              inactiveTrackColor: const Color(0xFFE2E8F0),
              inactiveThumbColor: const Color(0xFFCBD5E1),
              trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
            ),
          ),
        ],
      ),
    );
  }
}
