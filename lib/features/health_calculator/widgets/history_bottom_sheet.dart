// ส่วนนี้อธิบายบทบาทของไฟล์: วิดเจ็ตย่อยของ UI ในฟีเจอร์เครื่องคำนวณสุขภาพและบันทึกค่าสุขภาพ (history bottom sheet)
// คอมเมนท์ภาษาไทยถูกใส่ไว้เป็นส่วนๆ เพื่อช่วยไล่ flow โดยไม่เปลี่ยนพฤติกรรมเดิมของโค้ด

import 'package:flutter/material.dart';
import 'package:healthymate/shared/theme/app_theme.dart';
import 'package:healthymate/features/health_calculator/models/health_record_model.dart';

import 'weight_chart_painter.dart';

part 'history_bottom_sheet_graph.dart';
part 'history_bottom_sheet_items.dart';

class HistoryBottomSheet extends StatelessWidget {
  final List<TbHealthRecord> historyList;
  final ValueChanged<int> onDeleteRecord;

  const HistoryBottomSheet({
    super.key,
    required this.historyList,
    required this.onDeleteRecord,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = AppTheme.getScaffoldColor(isDark);
    final cardBg = AppTheme.getBackgroundColor(isDark);
    final textPrimary = AppTheme.getTextPrimaryColor(isDark);
    final textSecondary = AppTheme.getTextSecondaryColor(isDark);
    final borderColor = AppTheme.getBorderColor(isDark);

    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: BoxDecoration(
        color: scaffoldBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF4A584E) : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.history_rounded,
                      color: isDark
                          ? AppTheme.primaryLightGreen
                          : AppTheme.primaryGreen,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'ประวัติการคำนวณย้อนหลัง',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                  color: textSecondary,
                ),
              ],
            ),
          ),

          Divider(height: 1, color: borderColor),

          // Content
          Expanded(
            child: historyList.isEmpty
                ? _buildEmptyState(textSecondary)
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: historyList.length + 2,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _buildTrendGraphCard(
                          isDark,
                          cardBg,
                          borderColor,
                          textPrimary,
                          textSecondary,
                        );
                      } else if (index == 1) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 20, bottom: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'รายการบันทึกสุขภาพล่าสุด',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: textPrimary,
                                ),
                              ),
                              Text(
                                'ทั้งหมด ${historyList.length} รายการ',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: textSecondary,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      final record = historyList[index - 2];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: _buildHistoryItem(
                          context,
                          record,
                          isDark,
                          cardBg,
                          borderColor,
                          textPrimary,
                          textSecondary,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(Color textSecondary) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.history_toggle_off_rounded,
            size: 64,
            color: AppTheme.textTertiary,
          ),
          const SizedBox(height: 12),
          Text(
            'ยังไม่มีประวัติการคำนวณ',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'เมื่อคุณกดบันทึกข้อมูล ระบบจะซิงก์เข้าฐานข้อมูลและแสดงแนวโน้มที่นี่',
            style: TextStyle(fontSize: 13, color: AppTheme.textTertiary),
          ),
        ],
      ),
    );
  }
}
