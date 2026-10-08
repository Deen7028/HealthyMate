part of 'food_recognition_result_sheet.dart';
// ส่วนต่างๆ ของหน้าต่างแสดงผลการวิเคราะห์อาหาร
extension _FoodRecognitionResultSheetContent
    on _FoodRecognitionResultSheetState {
  Widget _buildResultSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = AppTheme.getBackgroundColor(isDark);
    final textPrimary = AppTheme.getTextPrimaryColor(isDark);
    final textSecondary = AppTheme.getTextSecondaryColor(isDark);
    final borderColor = AppTheme.getBorderColor(isDark);
    final surfaceBg = AppTheme.getSurfaceColor(isDark);
    final primaryColor = isDark
        ? AppTheme.primaryLightGreen
        : AppTheme.primaryGreen;

    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // ลากที่มุมบน
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF4A584E) : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          // ส่วนหัว
          ..._buildHeader(
            context,
            isDark,
            primaryColor,
            textPrimary,
            textSecondary,
            borderColor,
          ),
          // ส่วนเลื่อนลง
          _buildScrollableBody(
            isDark,
            surfaceBg,
            borderColor,
            primaryColor,
            textPrimary,
            textSecondary,
          ),
          _buildSaveFooter(isDark, cardBg, borderColor, primaryColor),
        ],
      ),
    );
  }
}
