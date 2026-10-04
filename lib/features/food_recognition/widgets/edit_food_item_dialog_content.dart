// ส่วนนี้อธิบายบทบาทของไฟล์: วิดเจ็ตย่อยของ UI ในฟีเจอร์การวิเคราะห์อาหารจากรูปภาพและข้อมูลโภชนาการ (edit food item dialog content)
// คอมเมนท์ภาษาไทยถูกใส่ไว้เป็นส่วนๆ เพื่อช่วยไล่ flow โดยไม่เปลี่ยนพฤติกรรมเดิมของโค้ด

part of 'edit_food_item_dialog.dart';

extension _EditFoodItemDialogContent on _EditFoodItemDialogState {
  Widget _buildDialog(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    final enteredCalories = int.tryParse(_calCtrl.text.trim()) ?? 0;
    final aiCalories = widget.item.calories;
    final isHighCalorieWarning =
        aiCalories > 0 && enteredCalories >= (aiCalories * 2);

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.edit_note_rounded,
                      color: primaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ปรับแก้ข้อมูลอาหาร',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E2822),
                          ),
                        ),
                        Text(
                          'แก้ไขชื่อ ขนาดเสิร์ฟ หรือสารอาหารตามจริง',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF8A958E),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Color(0xFF8A958E),
                    ),
                    splashRadius: 20,
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Food Name
              _buildLabel('ชื่อรายการอาหาร'),
              const SizedBox(height: 6),
              _buildInput(
                controller: _nameCtrl,
                hint: 'ระบุชื่ออาหาร',
                prefixIcon: Icons.restaurant_rounded,
                primaryColor: primaryColor,
              ),

              const SizedBox(height: 14),

              // Serving Size
              _buildLabel('ขนาดหน่วยบริโภค / ปริมาณ'),
              const SizedBox(height: 6),
              _buildInput(
                controller: _servingCtrl,
                hint: 'เช่น 1 จาน (300g), พิเศษ, 1 ชาม',
                prefixIcon: Icons.straighten_rounded,
                primaryColor: primaryColor,
              ),

              const SizedBox(height: 14),

              // Calories
              _buildLabel('พลังงาน (แคลอรี)'),
              const SizedBox(height: 6),
              _buildInput(
                controller: _calCtrl,
                hint: '0',
                suffixText: 'kcal',
                prefixIcon: isHighCalorieWarning
                    ? Icons.warning_amber_rounded
                    : Icons.local_fire_department_rounded,
                keyboardType: TextInputType.number,
                primaryColor: isHighCalorieWarning
                    ? Colors.orange.shade800
                    : const Color(0xFFE06D53),
                fillColor: isHighCalorieWarning
                    ? Colors.orange.shade50.withValues(alpha: 0.6)
                    : const Color(0xFFF7F9F8),
              ),

              // Visual Warning Banner (Smart Guardrails)
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                child: isHighCalorieWarning
                    ? Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              size: 14,
                              color: Colors.orange.shade800,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'ค่าพลังงานนี้สูงกว่าที่ AI ประเมินไว้มาก ($aiCalories kcal) คุณแน่ใจหรือไม่?',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.orange.shade800,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),

              const SizedBox(height: 14),

              _buildMacroFields(primaryColor),

              const SizedBox(height: 22),

              _buildActionButtons(context, primaryColor, isHighCalorieWarning),
            ],
          ),
        ),
      ),
    );
  }
}
