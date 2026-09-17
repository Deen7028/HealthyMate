import 'package:flutter/material.dart';

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
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'เลือกหน่วยวัด',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E2822),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('เมตริก (กิโลเมตร, กิโลกรัม)'),
              subtitle: const Text('Kilometers, Kilograms'),
              trailing: selectedUnit.startsWith('Kilo')
                  ? const Icon(Icons.check, color: Color(0xFF2E6339))
                  : null,
              onTap: () {
                onUnitSelected('Kilometers, Kilograms');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('อิมพีเรียล (ไมล์, ปอนด์)'),
              subtitle: const Text('Miles, Pounds'),
              trailing: selectedUnit.startsWith('Mile')
                  ? const Icon(Icons.check, color: Color(0xFF2E6339))
                  : null,
              onTap: () {
                onUnitSelected('Miles, Pounds');
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
