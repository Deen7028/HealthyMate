part of 'routine_step_style.dart';
//  Step 3: ตั้งค่าการแจ้งเตือน 
extension RoutineStepStyleInterval on _RoutineStepStyleState {
  Widget _buildIntervalMode(
    bool isDark,
    Color cardBg,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _intervalOptions.contains(_selectedInterval)
              ? _selectedInterval
              : _intervalOptions.first,
          dropdownColor: cardBg,
          isExpanded: true,
          icon: Icon(Icons.arrow_drop_down_rounded, color: textSecondary),
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _selectedInterval = val;
                _updateControllerText();
              });
            }
          },
          items: _intervalOptions.map((opt) {
            return DropdownMenuItem<String>(
              value: opt,
              child: Row(
                children: [
                  Icon(Icons.sync_rounded, size: 18, color: widget.btnColor),
                  const SizedBox(width: 10),
                  Text(
                    opt,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
