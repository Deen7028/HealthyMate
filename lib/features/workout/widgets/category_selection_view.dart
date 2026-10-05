// ส่วนนี้อธิบายบทบาทของไฟล์: วิดเจ็ตย่อยของ UI ในฟีเจอร์การติดตามและประวัติการออกกำลังกาย (category selection view)
// คอมเมนท์ภาษาไทยถูกใส่ไว้เป็นส่วนๆ เพื่อช่วยไล่ flow โดยไม่เปลี่ยนพฤติกรรมเดิมของโค้ด

import 'package:flutter/material.dart';
import 'package:healthymate/shared/theme/app_theme.dart';
import 'package:healthymate/features/workout/models/workout_models.dart';
import 'package:healthymate/features/workout/pages/workout_history_page.dart';

/// วิดเจ็ตหน้าจอเลือกหมวดหมู่กิจกรรมการออกกำลังกาย (Category Selection View Widget)
/// แสดงรายการประเภทกีฬา (วิ่ง, เดิน, ปั่นจักรยาน, โยคะ, ทำสมาธิ) พร้อมปุ่มประวัติกิจกรรม
class CategorySelectionView extends StatelessWidget {
  /// หมวดหมู่กิจกรรมที่ถูกเลือกอยู่ในปัจจุบัน
  final WorkoutCategory selectedCategory;

  /// รหัสผู้ใช้ปัจจุบัน
  final int userId;

  /// คอลแบ็กเมื่อผู้ใช้กดเลือกหมวดหมู่กิจกรรม
  final ValueChanged<WorkoutCategory> onSelectCategory;

  const CategorySelectionView({
    super.key,
    required this.selectedCategory,
    required this.userId,
    required this.onSelectCategory,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = AppTheme.getScaffoldColor(isDark);
    final cardBg = AppTheme.getBackgroundColor(isDark);
    final textPrimary = AppTheme.getTextPrimaryColor(isDark);
    final textSecondary = AppTheme.getTextSecondaryColor(isDark);
    final borderColor = AppTheme.getBorderColor(isDark);

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'เลือกหมวดหมู่การออกกำลังกาย',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'เลือกประเภทกิจกรรมก่อนเริ่มตรวจวัดและคำนวณแคลอรี',
                          style: TextStyle(fontSize: 13.5, color: textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // ปุ่มไอคอนประวัติการออกกำลังกาย มุมขวาบน
                  InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => WorkoutHistoryPage(userId: userId),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor, width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Tooltip(
                        message: 'ประวัติการออกกำลังกาย',
                        child: Icon(
                          Icons.history_rounded,
                          color: isDark ? AppTheme.primaryLightGreen : const Color(0xFF2E5327),
                          size: 26,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              ...WorkoutCategory.categories.map((category) {
                final isSelected = selectedCategory.id == category.id;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: AnimatedScale(
                    scale: isSelected ? 1.02 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutBack,
                    child: InkWell(
                      onTap: () => onSelectCategory(category),
                      borderRadius: BorderRadius.circular(20),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? (isDark ? AppTheme.primaryLightGreen : const Color(0xFF2E5327))
                                : borderColor,
                            width: isSelected ? 2 : 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? (isSelected ? 0.3 : 0.2) : (isSelected ? 0.08 : 0.03)),
                              blurRadius: isSelected ? 14 : 10,
                              offset: Offset(0, isSelected ? 6 : 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF23352A) : const Color(0xFFE8F3EB),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                category.icon,
                                color: isDark ? AppTheme.primaryLightGreen : const Color(0xFF2E5327),
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    category.title,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    category.subtitle,
                                    style: TextStyle(fontSize: 12.5, color: textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 16,
                              color: isDark ? const Color(0xFF8B9889) : const Color(0xFF8B9889),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
