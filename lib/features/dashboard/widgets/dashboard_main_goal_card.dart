// ignore_for_file: non_const_argument_for_const_parameter
import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';

class DashboardMainGoalCard extends StatelessWidget {
  final Map<String, dynamic>? userGoal;
  final List<Map<String, dynamic>> routines;
  final Map<int, bool> todayCompletionMap;
  final Map<String, Map<String, double>> todayWorkoutStats;
  final DateTime now;
  final VoidCallback? onNavigateToPractice;
  final Color primaryGreen;
  final Color darkGreen;

  const DashboardMainGoalCard({
    super.key,
    required this.userGoal,
    required this.routines,
    required this.todayCompletionMap,
    required this.todayWorkoutStats,
    required this.now,
    this.onNavigateToPractice,
    this.primaryGreen = const Color(0xFF0F9C58),
    this.darkGreen = const Color(0xFF006432),
  });

  String _formatNum(double val) =>
      val == val.toInt() ? val.toInt().toString() : val.toStringAsFixed(1);

  Color _getRoutineColor(Map<String, dynamic> routine, int index) {
    if (routine['color'] != null) {
      return Color((routine['color'] as num).toInt());
    }
    final title = routine['sTitle']?.toString().toLowerCase() ?? '';
    if (title.contains('น้ำ') ||
        title.contains('drink') ||
        title.contains('water')) {
      return const Color(0xFF0288D1);
    }
    if (title.contains('วิ่ง') ||
        title.contains('เดิน') ||
        title.contains('work')) {
      return const Color(0xFF4CAF50);
    }
    if (title.contains('สมาธิ') ||
        title.contains('นอน') ||
        title.contains('sleep')) {
      return const Color(0xFF7E57C2);
    }
    if (title.contains('อาหาร') ||
        title.contains('กิน') ||
        title.contains('eat')) {
      return const Color(0xFFFF9800);
    }
    if (title.contains('ยา') ||
        title.contains('pill') ||
        title.contains('health')) {
      return const Color(0xFFE91E63);
    }
    const defaultColors = [
      Color(0xFF0F9C58),
      Color(0xFF0288D1),
      Color(0xFFFF9800),
      Color(0xFF7E57C2),
      Color(0xFFE91E63),
    ];
    return defaultColors[index % defaultColors.length];
  }

  IconData _getRoutineIcon(Map<String, dynamic> routine, int index) {
    if (routine['iconData'] != null) {
      final int codePoint = (routine['iconData'] as num).toInt();
      return IconData(codePoint, fontFamily: 'MaterialIcons');
    }
    final title = routine['sTitle']?.toString().toLowerCase() ?? '';
    if (title.contains('น้ำ') ||
        title.contains('drink') ||
        title.contains('water')) {
      return Icons.water_drop_rounded;
    }
    if (title.contains('วิ่ง') ||
        title.contains('เดิน') ||
        title.contains('work')) {
      return Icons.directions_walk_rounded;
    }
    if (title.contains('สมาธิ') ||
        title.contains('นอน') ||
        title.contains('sleep')) {
      return Icons.self_improvement_rounded;
    }
    if (title.contains('อาหาร') ||
        title.contains('กิน') ||
        title.contains('eat')) {
      return Icons.restaurant_rounded;
    }
    if (title.contains('ยา') ||
        title.contains('pill') ||
        title.contains('health')) {
      return Icons.medical_services_rounded;
    }
    const defaultIcons = [
      Icons.flag_rounded,
      Icons.alarm_rounded,
      Icons.star_rounded,
      Icons.favorite_rounded,
    ];
    return defaultIcons[index % defaultIcons.length];
  }

  @override
  Widget build(BuildContext context) {
    final hasPinnedGoal = userGoal != null;
    final pinnedRoutineId = (userGoal?['nRoutineId'] as num?)?.toInt() ?? 0;

    Map<String, dynamic>? pinnedRoutine;
    if (hasPinnedGoal) {
      for (final r in routines) {
        final rId = (r['nRoutineId'] as num?)?.toInt() ?? 0;
        if ((pinnedRoutineId > 0 && rId == pinnedRoutineId) ||
            (r['sTitle'] == userGoal!['sTitle'])) {
          pinnedRoutine = r;
          break;
        }
      }
    }

    final double progress;
    final String displayTitle;
    final String displayDetail;
    final Color goalColor;
    final IconData goalIcon;
    bool isCompleted = false;
    bool isWorkoutGoal = false;

    if (pinnedRoutine != null) {
      final title = pinnedRoutine['sTitle']?.toString() ?? 'เป้าหมายหลัก';
      final targetVal =
          (pinnedRoutine['targetValue'] as num?)?.toDouble() ?? 1.0;
      final unitText = pinnedRoutine['unit']?.toString() ?? 'ครั้ง';
      goalColor = _getRoutineColor(pinnedRoutine, 0);
      goalIcon = _getRoutineIcon(pinnedRoutine, 0);

      final lowerTitle = title.toLowerCase();
      String matchedType = pinnedRoutine['sLinkedWorkout']?.toString() ?? '';
      if (matchedType.isEmpty) {
        if (lowerTitle.contains('วิ่ง')) {
          matchedType = 'วิ่ง';
        } else if (lowerTitle.contains('เดิน')) {
          matchedType = 'เดิน';
        } else if (lowerTitle.contains('จักรยาน') ||
            lowerTitle.contains('ปั่น')) {
          matchedType = 'ปั่นจักรยาน';
        } else if (lowerTitle.contains('ลู่วิ่ง')) {
          matchedType = 'ลู่วิ่งในร่ม';
        }
      }

      double? workoutVal;
      if (matchedType.isNotEmpty) {
        isWorkoutGoal = true;
      }

      if (matchedType.isNotEmpty &&
          todayWorkoutStats.containsKey(matchedType)) {
        final stats = todayWorkoutStats[matchedType]!;
        if (unitText.contains('กม') ||
            unitText.contains('กิโล') ||
            unitText.contains('km')) {
          workoutVal = stats['distance'];
        } else if (unitText.contains('ชม') ||
            unitText.contains('ชั่วโมง') ||
            unitText.contains('hour') ||
            unitText.contains('hr')) {
          workoutVal = (stats['duration'] ?? 0.0) / 60.0;
        } else if (unitText.contains('นาที') ||
            unitText.contains('min') ||
            unitText.contains('เวลา')) {
          workoutVal = stats['duration'];
        } else if (unitText.contains('แคล') || unitText.contains('cal')) {
          workoutVal = stats['caloriesBurned'];
        }
      }

      final routineId = (pinnedRoutine['nRoutineId'] as num?)?.toInt() ?? 0;
      final isDone = todayCompletionMap[routineId] ?? false;
      final currentVal =
          workoutVal ??
          (isDone
              ? targetVal
              : ((pinnedRoutine['currentValue'] as num?)?.toDouble() ?? 0.0));

      progress = targetVal > 0 ? (currentVal / targetVal).clamp(0.0, 1.0) : 0.0;
      final percent = (progress * 100).toInt();
      isCompleted = progress >= 1.0 || isDone;

      displayTitle = title;
      displayDetail =
          'ความคืบหน้าวันนี้: ${_formatNum(currentVal)} / ${_formatNum(targetVal)} $unitText ($percent%)';
    } else if (hasPinnedGoal) {
      progress =
          (userGoal!['nProgress'] as num?)?.toDouble().clamp(0.0, 1.0) ?? 0.0;
      goalColor = primaryGreen;
      goalIcon = Icons.flag_rounded;
      isCompleted = progress >= 1.0;

      displayTitle = userGoal!['sTitle']?.toString() ?? 'เป้าหมายหลัก';
      final remaining = userGoal!['sRemainingText']?.toString() ?? '';
      displayDetail = remaining.isNotEmpty
          ? remaining
          : 'ทำสำเร็จแล้ว ${(progress * 100).toInt()}%';
    } else {
      progress = 0.0;
      goalColor = primaryGreen;
      goalIcon = Icons.push_pin_outlined;
      displayTitle = 'ยังไม่ได้ปักหมุดเป้าหมายหลัก';
      displayDetail =
          'เลือกปักหมุดกิจวัตรสำคัญจากหน้ากิจวัตรเพื่อติดตามความคืบหน้า';
    }

    final daysRemaining = DateTime(
      now.year,
      now.month + 1,
      0,
    ).difference(now).inDays;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasPinnedGoal
              ? goalColor.withValues(alpha: 0.25)
              : Colors.grey.shade200,
          width: hasPinnedGoal ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: goalColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(goalIcon, color: goalColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            displayTitle,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          if (hasPinnedGoal) ...[
                            const SizedBox(width: 6),
                            Icon(
                              Icons.push_pin,
                              size: 14,
                              color: Colors.orange.shade700,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        displayDetail,
                        style: TextStyle(
                          fontSize: 12,
                          color: isCompleted
                              ? Colors.green.shade700
                              : Colors.grey,
                          fontWeight: isCompleted
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (!hasPinnedGoal)
                TextButton(
                  onPressed: onNavigateToPractice,
                  child: Text(
                    'ปักหมุด >',
                    style: TextStyle(
                      color: primaryGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          CircularPercentIndicator(
            radius: 54.0,
            lineWidth: 9.0,
            percent: progress,
            center: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${(progress * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: goalColor,
                  ),
                ),
                Text(
                  isCompleted ? 'สำเร็จ!' : 'ความคืบหน้า',
                  style: TextStyle(
                    fontSize: 9,
                    color: isCompleted ? Colors.green.shade800 : Colors.grey,
                    fontWeight: isCompleted
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
            progressColor: goalColor,
            backgroundColor: goalColor.withValues(alpha: 0.12),
            circularStrokeCap: CircularStrokeCap.round,
            animation: true,
          ),

          if (isCompleted) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, size: 14, color: Colors.green),
                  const SizedBox(width: 4),
                  Text(
                    'ทำเป้าหมายสำเร็จแล้ววันนี้! 🎉',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade800,
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (hasPinnedGoal) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildGoalStatItem(
                  'สถานะ',
                  isCompleted ? 'ทำสำเร็จแล้ว' : 'กำลังดำเนินการ',
                  icon: isCompleted
                      ? Icons.check_circle_outline
                      : Icons.timelapse,
                ),
                Container(height: 24, width: 1, color: Colors.grey.shade200),
                _buildGoalStatItem(
                  'ประเภท',
                  isWorkoutGoal ? 'ออกกำลังกาย' : 'กิจวัตร',
                  icon: isWorkoutGoal ? Icons.directions_run : Icons.task_alt,
                ),
                Container(height: 24, width: 1, color: Colors.grey.shade200),
                _buildGoalStatItem(
                  'เหลือเวลา',
                  '$daysRemaining วัน',
                  icon: Icons.calendar_today,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGoalStatItem(String title, String value, {IconData? icon}) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 12, color: Colors.grey),
              const SizedBox(width: 4),
            ],
            Text(
              title,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
