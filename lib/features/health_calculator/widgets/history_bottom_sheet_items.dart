part of 'history_bottom_sheet.dart';

extension _HistoryBottomSheetItems on HistoryBottomSheet {
  Widget _buildHistoryItem(
    BuildContext context,
    TbHealthRecord record,
    bool isDark,
    Color cardBg,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    final dateStr =
        '${record.dtRecordedAt.day}/${record.dtRecordedAt.month}/${record.dtRecordedAt.year}  ${record.dtRecordedAt.hour.toString().padLeft(2, '0')}:${record.dtRecordedAt.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dateStr,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: textSecondary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF23352A)
                      : const Color(0xFFE8F3EB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  record.bmiCategoryObj.badgeText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppTheme.primaryLightGreen
                        : AppTheme.primaryGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildMetricPill('น้ำหนัก', '${record.nWeight} กก.', isDark),
              const SizedBox(width: 8),
              _buildMetricPill(
                'ส่วนสูง',
                '${record.nHeight.toInt()} ซม.',
                isDark,
              ),
              const SizedBox(width: 8),
              _buildMetricPill('BMI', record.nBmi.toStringAsFixed(1), isDark),
              const SizedBox(width: 8),
              _buildMetricPill('TDEE', '${record.nTdee.toInt()} kcal', isDark),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'กิจกรรม: ${record.activityLevelTitle ?? "ปกติ"}',
                  style: TextStyle(fontSize: 11.5, color: textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              InkWell(
                onTap: () => onDeleteRecord(record.nRecordId),
                child: const Padding(
                  padding: EdgeInsets.all(4.0),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    size: 18,
                    color: Colors.redAccent,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricPill(String label, String value, bool isDark) {
    final surfaceBg = AppTheme.getSurfaceColor(isDark);
    final textPrimary = AppTheme.getTextPrimaryColor(isDark);
    final textSecondary = AppTheme.getTextSecondaryColor(isDark);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: BoxDecoration(
          color: surfaceBg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(label, style: TextStyle(fontSize: 10, color: textSecondary)),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
