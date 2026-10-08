part of 'routine_step_goal.dart';
//  Step 2: กำหนดระยะเวลาและการเชื่อมโยงกับแอปภายนอก 🔗
extension RoutineStepGoalUnitButton on RoutineStepGoal {
  Widget _buildQuickUnitButton(
    String unit,
    String label,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
  ) {
    final isSelected = unitController.text.trim() == unit;
    return Expanded(
      child: GestureDetector(
        onTap: () => onSelectUnit(unit),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? const Color(0xFF2E5327) : const Color(0xFF2E5327))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Text(
                unit,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : textPrimary,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: isSelected ? Colors.white70 : textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
