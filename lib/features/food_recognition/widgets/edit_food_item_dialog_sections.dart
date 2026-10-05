// ส่วนนี้อธิบายบทบาทของไฟล์: วิดเจ็ตย่อยของ UI ในฟีเจอร์การวิเคราะห์อาหารจากรูปภาพและข้อมูลโภชนาการ (edit food item dialog sections)
// คอมเมนท์ภาษาไทยถูกใส่ไว้เป็นส่วนๆ เพื่อช่วยไล่ flow โดยไม่เปลี่ยนพฤติกรรมเดิมของโค้ด

part of 'edit_food_item_dialog.dart';

extension _EditFoodItemDialogSections on _EditFoodItemDialogState {
  Widget _buildMacroFields(Color primaryColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Macros Row: Protein, Carbs, Fat
        _buildLabel('สารอาหาร 3 หมู่หลัก (กรัม)'),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: _buildInput(
                controller: _proteinCtrl,
                hint: '0',
                label: 'โปรตีน (P)',
                suffixText: 'g',
                prefixIcon: Icons.egg_alt_outlined,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                primaryColor: const Color(0xFF3B7F4B),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildInput(
                controller: _carbsCtrl,
                hint: '0',
                label: 'คาร์บ (C)',
                suffixText: 'g',
                prefixIcon: Icons.grain_rounded,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                primaryColor: const Color(0xFFE29A38),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildInput(
                controller: _fatCtrl,
                label: 'ไขมัน (F)',
                hint: '0',
                suffixText: 'g',
                prefixIcon: Icons.water_drop_outlined,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                primaryColor: const Color(0xFFD65858),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    Color primaryColor,
    bool isHighCalorieWarning,
  ) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: const BorderSide(color: Color(0xFFE0E5E2)),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'ยกเลิก',
              style: TextStyle(color: Color(0xFF6F7A72)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isHighCalorieWarning
                  ? Colors.orange.shade800
                  : primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 12),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              final updated = widget.item.copyWith(
                name: _nameCtrl.text.trim().isNotEmpty
                    ? _nameCtrl.text.trim()
                    : widget.item.name,
                servingSize: _servingCtrl.text.trim().isNotEmpty
                    ? _servingCtrl.text.trim()
                    : widget.item.servingSize,
                calories: int.tryParse(_calCtrl.text.trim()) ?? 0,
                protein: double.tryParse(_proteinCtrl.text.trim()) ?? 0.0,
                carbs: double.tryParse(_carbsCtrl.text.trim()) ?? 0.0,
                fat: double.tryParse(_fatCtrl.text.trim()) ?? 0.0,
              );
              widget.onSave(updated);
              Navigator.pop(context);
            },
            child: const Text(
              'นำไปใช้',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
