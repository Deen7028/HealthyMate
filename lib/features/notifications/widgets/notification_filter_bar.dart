import 'package:flutter/material.dart';
import 'package:healthymate/features/notifications/models/notification_item.dart';
import 'package:healthymate/shared/theme/app_theme.dart';

/// แถบเลือกกรองหมวดหมู่การแจ้งเตือน (Notification Filter Bar)
class NotificationFilterBar extends StatelessWidget {
  final String selectedCategory;
  final ValueChanged<String> onSelectCategory;

  const NotificationFilterBar({
    super.key,
    required this.selectedCategory,
    required this.onSelectCategory,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = AppTheme.getBackgroundColor(isDark);
    final textPrimary = AppTheme.getTextPrimaryColor(isDark);
    final borderColor = AppTheme.getBorderColor(isDark);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: NotificationCategoryType.values.map((cat) {
          final isSelected = selectedCategory == cat.id;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => onSelectCategory(cat.id),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark ? const Color(0xFF23352A) : const Color(0xFF2E5327))
                      : cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? (isDark ? AppTheme.primaryLightGreen : const Color(0xFF2E5327))
                        : borderColor,
                    width: 1.2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      cat.icon,
                      size: 16,
                      color: isSelected
                          ? (isDark ? AppTheme.primaryLightGreen : Colors.white)
                          : cat.color,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      cat.label,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? (isDark ? AppTheme.primaryLightGreen : Colors.white)
                            : textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
