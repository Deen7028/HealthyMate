import 'package:flutter/material.dart';
import 'package:healthymate/features/food_recognition/models/food_recognition_models.dart';

class EditFoodItemDialog extends StatefulWidget {
  final DetectedFoodItem item;
  final ValueChanged<DetectedFoodItem> onSave;

  const EditFoodItemDialog({
    super.key,
    required this.item,
    required this.onSave,
  });

  @override
  State<EditFoodItemDialog> createState() => _EditFoodItemDialogState();
}

class _EditFoodItemDialogState extends State<EditFoodItemDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _servingCtrl;
  late final TextEditingController _calCtrl;
  late final TextEditingController _proteinCtrl;
  late final TextEditingController _carbsCtrl;
  late final TextEditingController _fatCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.item.name);
    _servingCtrl = TextEditingController(text: widget.item.servingSize);
    _calCtrl = TextEditingController(text: widget.item.calories.toString());
    _proteinCtrl = TextEditingController(text: widget.item.protein.toStringAsFixed(1));
    _carbsCtrl = TextEditingController(text: widget.item.carbs.toStringAsFixed(1));
    _fatCtrl = TextEditingController(text: widget.item.fat.toStringAsFixed(1));

    _calCtrl.addListener(_onCaloriesChanged);
  }

  void _onCaloriesChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _calCtrl.removeListener(_onCaloriesChanged);
    _nameCtrl.dispose();
    _servingCtrl.dispose();
    _calCtrl.dispose();
    _proteinCtrl.dispose();
    _carbsCtrl.dispose();
    _fatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    final enteredCalories = int.tryParse(_calCtrl.text.trim()) ?? 0;
    final aiCalories = widget.item.calories;
    final isHighCalorieWarning = aiCalories > 0 && enteredCalories >= (aiCalories * 2);

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
                    child: Icon(Icons.edit_note_rounded, color: primaryColor, size: 24),
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
                          style: TextStyle(fontSize: 12, color: Color(0xFF8A958E)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF8A958E)),
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
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      primaryColor: const Color(0xFFD65858),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: const BorderSide(color: Color(0xFFE0E5E2)),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('ยกเลิก', style: TextStyle(color: Color(0xFF6F7A72))),
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                      child: const Text('นำไปใช้', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Color(0xFF6F7A72),
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String hint,
    required IconData prefixIcon,
    required Color primaryColor,
    String? label,
    String? suffixText,
    Color fillColor = const Color(0xFFF7F9F8),
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
        color: primaryColor == Colors.orange.shade800 ? Colors.orange.shade900 : const Color(0xFF1E2822),
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFA5AEA8), fontSize: 12),
        prefixIcon: Icon(prefixIcon, size: 18, color: primaryColor),
        suffixText: suffixText,
        suffixStyle: const TextStyle(fontSize: 11, color: Color(0xFF8A958E), fontWeight: FontWeight.w500),
        filled: true,
        fillColor: fillColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: primaryColor == Colors.orange.shade800
                ? Colors.orange.shade300
                : const Color(0xFFE4E9E6),
            width: 1.1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 1.6),
        ),
      ),
    );
  }
}
