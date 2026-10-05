// ส่วนนี้อธิบายบทบาทของไฟล์: หน้าจอหลัก ในฟีเจอร์กิจวัตรและเป้าหมายประจำวัน (completed routines tab)
// คอมเมนท์ภาษาไทยถูกใส่ไว้เป็นส่วนๆ เพื่อช่วยไล่ flow โดยไม่เปลี่ยนพฤติกรรมเดิมของโค้ด

part of 'completed_goals_and_routines_page.dart';

extension CompletedRoutinesTab on _CompletedGoalsAndRoutinesPageState {
  Widget _buildCompletedRoutinesTab(
    Color cardBg,
    Color textPrimary,
    Color textSecondary,
    bool isDark,
  ) {
    if (_completedRoutines.isEmpty) {
      return _buildEmptyState(
        icon: Icons.checklist_rtl_rounded,
        title: 'ยังไม่มีประวัติกิจวัตรที่ทำสำเร็จ',
        subtitle: 'เริ่มเช็คกิจวัตรแรกของคุณวันนี้ได้เลย!',
        isDark: isDark,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadHistoryData,
      color: darkGreen,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _completedRoutines.length,
        itemBuilder: (context, index) {
          final r = _completedRoutines[index];
          final title = r['sTitle']?.toString() ?? 'กิจวัตร';
          final dateStr = _formatThaiDate(r['dtLogDate']?.toString());
          final targetVal = (r['targetValue'] as num?)?.toDouble() ?? 1.0;
          final progressVal =
              (r['nProgressValue'] as num?)?.toDouble() ?? targetVal;
          final unit = r['unit']?.toString() ?? 'ครั้ง';
          final time = r['sTime']?.toString() ?? '';

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF2C3930)
                    : const Color(0xFFE2E7DF),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E3825)
                        : const Color(0xFFE8F5E9),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle_rounded,
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
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ทำได้: ${progressVal == progressVal.toInt() ? progressVal.toInt() : progressVal.toStringAsFixed(1)} / ${targetVal == targetVal.toInt() ? targetVal.toInt() : targetVal.toStringAsFixed(1)} $unit ${time.isNotEmpty ? "• $time" : ""}',
                        style: TextStyle(fontSize: 12, color: textSecondary),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF27342C)
                        : const Color(0xFFF3F6F2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    dateStr,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
