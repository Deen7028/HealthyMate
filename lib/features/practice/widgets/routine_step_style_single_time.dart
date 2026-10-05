// ส่วนนี้อธิบายบทบาทของไฟล์: วิดเจ็ตย่อยของ UI ในฟีเจอร์กิจวัตรและเป้าหมายประจำวัน (routine step style single time)
// คอมเมนท์ภาษาไทยถูกใส่ไว้เป็นส่วนๆ เพื่อช่วยไล่ flow โดยไม่เปลี่ยนพฤติกรรมเดิมของโค้ด

part of 'routine_step_style.dart';

extension RoutineStepStyleSingleTime on _RoutineStepStyleState {
  Widget _buildSingleTimeMode(
    bool isDark,
    Color cardBg,
    Color borderColor,
    Color textPrimary,
  ) {
    final currentText = widget.notificationTimeController.text.trim();
    final timeDisplay =
        (currentText.isNotEmpty &&
            !currentText.startsWith('ทุก ') &&
            !currentText.contains(','))
        ? currentText
        : '08:00 น.';

    return InkWell(
      onTap: () async {
        TimeOfDay initialTime = const TimeOfDay(hour: 8, minute: 0);
        final match = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(timeDisplay);
        if (match != null) {
          initialTime = TimeOfDay(
            hour: int.parse(match.group(1)!),
            minute: int.parse(match.group(2)!),
          );
        }
        final picked = await _pickTime(initialTime);
        if (picked != null) {
          final formattedHour = picked.hour.toString().padLeft(2, '0');
          final formattedMinute = picked.minute.toString().padLeft(2, '0');
          setState(() {
            widget.notificationTimeController.text =
                '$formattedHour:$formattedMinute น.';
          });
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.access_time_filled_rounded,
                  color: widget.btnColor,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  timeDisplay,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: widget.btnColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'เปลี่ยนเวลา',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: widget.btnColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
