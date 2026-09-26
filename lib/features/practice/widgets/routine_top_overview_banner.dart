import 'package:flutter/material.dart';

class RoutineTopOverviewBanner extends StatelessWidget {
  final int completedCount;
  final int totalCount;
  final Map<String, Map<String, double>> todayWorkoutStats;
  final double? overallProgressRatio;

  const RoutineTopOverviewBanner({
    super.key,
    required this.completedCount,
    required this.totalCount,
    required this.todayWorkoutStats,
    this.overallProgressRatio,
  });

  @override
  Widget build(BuildContext context) {
    final overallRatio = (overallProgressRatio ??
            (totalCount > 0 ? (completedCount / totalCount) : 0.0))
        .clamp(0.0, 1.0);
    final overallPercent = (overallRatio * 100).round();

    double totalCalories = 0.0;
    double totalDurationMin = 0.0;
    todayWorkoutStats.forEach((_, stats) {
      totalDurationMin += (stats['duration'] ?? 0.0);
      totalCalories += (stats['calories'] ?? stats['caloriesBurned'] ?? 0.0);
    });

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2E5327),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E5327).withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: const Color(0xFF43703B), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.task_alt_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'สรุปภารกิจประจำวัน',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'วันนี้ $completedCount/$totalCount รายการ',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),


          const SizedBox(height: 16),

          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$overallPercent',
                style: const TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -1,
                ),
              ),
              const Text(
                '%',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF90DB89),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      completedCount == totalCount && totalCount > 0
                          ? 'สุดยอด! ทำครบทุกภารกิจแล้ว 🎉'
                          : 'ความคืบหน้าภาพรวมวันนี้',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFA0ACA0),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: overallRatio,
                        minHeight: 8,
                        backgroundColor: Colors.white.withValues(alpha: 0.15),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF90DB89),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.timer_outlined,
                      size: 16,
                      color: Color(0xFF90DB89),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'เวลาสะสม: ${totalDurationMin.toInt()} นาที',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 1,
                  height: 14,
                  color: Colors.white.withValues(alpha: 0.2),
                ),
                Row(
                  children: [
                    const Icon(
                      Icons.local_fire_department_rounded,
                      size: 16,
                      color: Colors.orangeAccent,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'เผาผลาญ: ${totalCalories.toInt()} kcal',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
