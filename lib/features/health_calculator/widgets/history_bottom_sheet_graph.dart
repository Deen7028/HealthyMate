// ส่วนนี้อธิบายบทบาทของไฟล์: วิดเจ็ตย่อยของ UI ในฟีเจอร์เครื่องคำนวณสุขภาพและบันทึกค่าสุขภาพ (history bottom sheet graph)
// คอมเมนท์ภาษาไทยถูกใส่ไว้เป็นส่วนๆ เพื่อช่วยไล่ flow โดยไม่เปลี่ยนพฤติกรรมเดิมของโค้ด

part of 'history_bottom_sheet.dart';

extension _HistoryBottomSheetGraph on HistoryBottomSheet {
  Widget _buildTrendGraphCard(
    bool isDark,
    Color cardBg,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    final sortedRecords = List<TbHealthRecord>.from(
      historyList,
    ).reversed.toList();
    final weights = sortedRecords.map((r) => r.nWeight).toList();
    final firstWeight = weights.isNotEmpty ? weights.first : 0.0;
    final latestWeight = weights.isNotEmpty ? weights.last : 0.0;
    final diff = latestWeight - firstWeight;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'แนวโน้มการเปลี่ยนแปลงน้ำหนัก',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'เปรียบเทียบจาก ${sortedRecords.length} บันทึก',
                    style: TextStyle(fontSize: 12, color: textSecondary),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: diff <= 0
                      ? (isDark
                            ? const Color(0xFF23352A)
                            : const Color(0xFFE8F3EB))
                      : (isDark
                            ? const Color(0xFF3E271D)
                            : const Color(0xFFFFF0E8)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  diff <= 0
                      ? '${diff.toStringAsFixed(1)} กก. (ลดลง)'
                      : '+${diff.toStringAsFixed(1)} กก. (เพิ่มขึ้น)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: diff <= 0
                        ? (isDark
                              ? AppTheme.primaryLightGreen
                              : AppTheme.primaryGreen)
                        : const Color(0xFFE06D2D),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 120,
            width: double.infinity,
            child: RepaintBoundary(
              child: CustomPaint(
                painter: WeightChartPainter(weights: weights, isDark: isDark),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'เริ่มต้น: ${firstWeight.toStringAsFixed(1)} กก.',
                style: TextStyle(fontSize: 12, color: textSecondary),
              ),
              Text(
                'ปัจจุบัน: ${latestWeight.toStringAsFixed(1)} กก.',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppTheme.primaryLightGreen
                      : AppTheme.primaryGreen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
