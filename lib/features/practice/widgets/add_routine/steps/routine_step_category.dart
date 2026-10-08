import 'package:flutter/material.dart';
import 'package:healthymate/shared/theme/app_theme.dart';
import 'package:healthymate/features/practice/models/routine_item.dart';
// Step 1: เลือกหมวดหมู่ & ชื่อกิจวัตร 🎯
class RoutineStepCategory extends StatelessWidget {
  final RoutineCategory selectedCategory;
  final TextEditingController titleController;
  final ValueChanged<RoutineCategory> onCategoryChanged;
  final ValueChanged<String> onTitleChanged;

  const RoutineStepCategory({
    super.key,
    required this.selectedCategory,
    required this.titleController,
    required this.onCategoryChanged,
    required this.onTitleChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = AppTheme.getTextPrimaryColor(isDark);
    final textSecondary = AppTheme.getTextSecondaryColor(isDark);
    final cardBg = AppTheme.getBackgroundColor(isDark);
    final borderColor = AppTheme.getBorderColor(isDark);
    final surfaceBg = AppTheme.getSurfaceColor(isDark);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step 1: เลือกหมวดหมู่ & ชื่อกิจวัตร 🎯',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.2,
            children: RoutineCategory.values.map((cat) {
              final isSelected = cat == selectedCategory;
              return InkWell(
                onTap: () => onCategoryChanged(cat),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isDark ? const Color(0xFF2E5327) : const Color(0xFF2E5327))
                        : (isDark ? surfaceBg : const Color(0xFFF4F7F4)),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? (isDark ? AppTheme.primaryLightGreen : const Color(0xFF2E5327))
                          : borderColor,
                      width: 1.5,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(0xFF2E5327)
                                  .withValues(alpha: isDark ? 0.4 : 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.2)
                              : (isDark ? const Color(0xFF23352A) : const Color(0xFFE8F3EB)),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          cat.icon,
                          size: 20,
                          color: isSelected
                              ? Colors.white
                              : (isDark ? AppTheme.primaryLightGreen : const Color(0xFF2E5327)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          cat.label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? Colors.white
                                : textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: titleController,
            onChanged: onTitleChanged,
            style: TextStyle(color: textPrimary),
            decoration: InputDecoration(
              labelText: 'ชื่อกิจวัตร / นิสัย *',
              labelStyle: TextStyle(color: textSecondary),
              hintText:
                  'เช่น วิ่งสเปรดเช้า, ปั่นจักรยานรอบสวน, ดื่มน้ำ 2000 มล.',
              hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.6)),
              prefixIcon: Icon(
                Icons.edit_note_rounded,
                color: isDark ? AppTheme.primaryLightGreen : const Color(0xFF2E5327),
              ),
              filled: true,
              fillColor: cardBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: isDark ? AppTheme.primaryLightGreen : const Color(0xFF2E5327),
                  width: 1.8,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
