part of 'routine_main_goal_card.dart';
// การ์ดสถานะว่างเมื่อยังไม่ได้ตั้งเป้าหมายหลัก (Empty State: ปุ่มแตะเพื่อเลือกเป้าหมาย)
extension _RoutineMainGoalCardEmpty on RoutineMainGoalCard {
  Widget _buildEmptyGoal(bool isDark, Color textSecondary) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2822) : cardGreenBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: primaryGreen.withValues(alpha: isDark ? 0.4 : 0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primaryGreen.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.flag_rounded,
                  color: isDark ? const Color(0xFF90DB89) : darkGreen,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ยังไม่มีเป้าหมายหลัก',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? const Color(0xFF90DB89) : darkGreen,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'ตั้งเป้าหมายภาพรวม เช่น วิ่งสะสมระยะทาง หรือเผาผลาญแคลอรี',
                      style: TextStyle(fontSize: 12, color: textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: onSetMainGoal,
              icon: const Icon(
                Icons.add_circle_outline,
                color: Colors.white,
                size: 20,
              ),
              label: const Text(
                '+ ตั้งเป้าหมายหลัก (Set Main Goal)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: darkGreen,
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
