// ส่วนนี้อธิบายบทบาทของไฟล์: วิดเจ็ตย่อยของ UI ในฟีเจอร์โปรไฟล์ การตั้งค่า และบัญชีผู้ใช้ (unit picker bottom sheet)
// คอมเมนท์ภาษาไทยถูกใส่ไว้เป็นส่วนๆ เพื่อช่วยไล่ flow โดยไม่เปลี่ยนพฤติกรรมเดิมของโค้ด

import 'package:flutter/material.dart';
import 'package:healthymate/shared/theme/app_theme.dart';

class UnitPickerBottomSheet extends StatelessWidget {
  final String selectedUnit;
  final ValueChanged<String> onUnitSelected;

  const UnitPickerBottomSheet({
    super.key,
    required this.selectedUnit,
    required this.onUnitSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = AppTheme.getBackgroundColor(isDark);
    final textPrimary = AppTheme.getTextPrimaryColor(isDark);
    final textSecondary = AppTheme.getTextSecondaryColor(isDark);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'เลือกหน่วยวัด',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text(
                  'เมตริก (กิโลเมตร, กิโลกรัม)',
                  style: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
                ),
                subtitle: Text('Kilometers, Kilograms', style: TextStyle(color: textSecondary)),
                trailing: selectedUnit.startsWith('Kilo')
                    ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                    : null,
                onTap: () {
                  onUnitSelected('Kilometers, Kilograms');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: Text(
                  'อิมพีเรียล (ไมล์, ปอนด์)',
                  style: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
                ),
                subtitle: Text('Miles, Pounds', style: TextStyle(color: textSecondary)),
                trailing: selectedUnit.startsWith('Mile')
                    ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                    : null,
                onTap: () {
                  onUnitSelected('Miles, Pounds');
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
