import 'package:flutter/material.dart';
import 'package:healthymate/features/food_recognition/models/food_recognition_models.dart';

part 'edit_food_item_dialog_content.dart';
part 'edit_food_item_dialog_sections.dart';

// วิดเจ็ตกล่องข้อความแก้ไขรายละเอียดรายการอาหาร (Edit Food Item Dialog Widget)
// อนุญาตให้ผู้ใช้ปรับปรุงชื่อ ปริมาณ และสารอาหาร (แคลอรี โปรตีน คาร์บ ไขมัน) ก่อนบันทึก
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
    _proteinCtrl = TextEditingController(
      text: widget.item.protein.toStringAsFixed(1),
    );
    _carbsCtrl = TextEditingController(
      text: widget.item.carbs.toStringAsFixed(1),
    );
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
  Widget build(BuildContext context) => _buildDialog(context);

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
        color: primaryColor == Colors.orange.shade800
            ? Colors.orange.shade900
            : const Color(0xFF1E2822),
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFA5AEA8), fontSize: 12),
        prefixIcon: Icon(prefixIcon, size: 18, color: primaryColor),
        suffixText: suffixText,
        suffixStyle: const TextStyle(
          fontSize: 11,
          color: Color(0xFF8A958E),
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: fillColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
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
