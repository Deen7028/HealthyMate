part of 'routine_top_overview_banner.dart';
// ส่วนย่อยสรุปสถิติการออกกำลังกายในแบนเนอร์
extension _RoutineTopOverviewWorkoutSummary on RoutineTopOverviewBanner {
  Widget _buildWorkoutSummary(double totalDurationMin, double totalCalories) {
    return Container(
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
    );
  }
}
