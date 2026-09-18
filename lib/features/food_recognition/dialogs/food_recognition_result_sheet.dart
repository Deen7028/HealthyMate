import 'dart:io';
import 'package:flutter/material.dart';
import 'package:healthymate/core/database/app_database.dart';
import 'package:healthymate/core/theme/app_theme.dart';
import 'package:healthymate/features/food_recognition/dialogs/edit_food_item_dialog.dart';
import 'package:healthymate/features/food_recognition/models/food_recognition_models.dart';

class FoodRecognitionResultSheet extends StatefulWidget {
  final MealNutritionScanResult scanResult;
  final VoidCallback? onSavedSuccessfully;

  const FoodRecognitionResultSheet({
    super.key,
    required this.scanResult,
    this.onSavedSuccessfully,
  });

  @override
  State<FoodRecognitionResultSheet> createState() => _FoodRecognitionResultSheetState();
}

class _FoodRecognitionResultSheetState extends State<FoodRecognitionResultSheet> {
  late MealNutritionScanResult _result;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _result = widget.scanResult;
  }

  void _editItem(int index) {
    showDialog(
      context: context,
      builder: (context) => EditFoodItemDialog(
        item: _result.items[index],
        onSave: (updated) {
          setState(() {
            _result.items[index] = updated;
          });
        },
      ),
    );
  }

  void _addNewItem() {
    final newItem = DetectedFoodItem(
      id: 'food_${DateTime.now().millisecondsSinceEpoch}',
      name: 'รายการอาหารเพิ่มเติม',
      calories: 100,
      protein: 5.0,
      carbs: 15.0,
      fat: 2.0,
      servingSize: '1 ที่',
    );
    showDialog(
      context: context,
      builder: (context) => EditFoodItemDialog(
        item: newItem,
        onSave: (savedItem) {
          setState(() {
            _result.items.add(savedItem);
          });
        },
      ),
    );
  }

  void _removeItem(int index) {
    setState(() {
      _result.items.removeAt(index);
    });
  }

  Future<void> _saveMealToDatabase() async {
    if (_result.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ไม่มีรายการอาหารในมื้อนี้ กรุณาเพิ่มรายการอาหาร'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final user = await AppDatabase.instance.getUser();
      final userId = user?.nUserId ?? 1;

      for (final item in _result.items) {
        await AppDatabase.instance.insertNutritionLog(
          userId: userId,
          mealType: _result.category.key,
          foodName: item.name,
          calories: item.calories,
          protein: item.protein,
          carbs: item.carbs,
          fat: item.fat,
          servingSize: item.servingSize,
          imagePath: _result.imagePath,
        );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Text('บันทึกมื้อ${_result.category.label} (${_result.totalCalories} kcal) สำเร็จ!'),
              ],
            ),
            backgroundColor: AppTheme.primaryGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        widget.onSavedSuccessfully?.call();
      }
    } catch (e) {
      debugPrint('Error saving nutrition log: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาดในการบันทึก: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag Handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.auto_awesome_rounded, color: primaryColor, size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ผลวิเคราะห์อาหาร AI Vision',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E2822),
                        ),
                      ),
                      Text(
                        'จำแนกหลายเมนู พร้อมแจกแจงสารอาหารหลัก P/C/F',
                        style: TextStyle(fontSize: 12, color: Color(0xFF8A958E)),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF8A958E)),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEAEFEA)),

          // Scrollable Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image Thumbnail & Meal Type Selector Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Photo Preview
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: 88,
                          height: 88,
                          color: const Color(0xFFF2F5F3),
                          child: File(_result.imagePath).existsSync()
                              ? Image.file(
                                  File(_result.imagePath),
                                  fit: BoxFit.cover,
                                )
                              : const Icon(Icons.restaurant_rounded, size: 36, color: Color(0xFF8A958E)),
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Meal Category Selector
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'เลือกประเภทมื้ออาหาร',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF5A6559),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: MealCategory.values.map((cat) {
                                final isSel = _result.category == cat;
                                return ChoiceChip(
                                  label: Text(
                                    cat.label,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                                      color: isSel ? Colors.white : const Color(0xFF5A6559),
                                    ),
                                  ),
                                  selected: isSel,
                                  selectedColor: primaryColor,
                                  backgroundColor: const Color(0xFFF2F5F3),
                                  side: BorderSide(
                                    color: isSel ? primaryColor : const Color(0xFFE2E7DF),
                                    width: 1,
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  showCheckmark: false,
                                  onSelected: (val) {
                                    if (val) setState(() => _result.category = cat);
                                  },
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Macronutrients Summary Banner Card
                  _buildNutritionSummaryCard(primaryColor),

                  const SizedBox(height: 22),

                  // Multi-item Food List Section Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'เมนูที่ตรวจพบในภาพ',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E2822),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${_result.items.length} รายการ',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      TextButton.icon(
                        onPressed: _addNewItem,
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('เพิ่มเมนู', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        style: TextButton.styleFrom(
                          foregroundColor: primaryColor,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Items List
                  if (_result.items.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAF9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE5EAE6)),
                      ),
                      child: const Center(
                        child: Text(
                          'ยังไม่มีรายการอาหารในมื้อนี้\nกดปุ่ม "เพิ่มเมนู" เพื่อระบุอาหารด้วยตนเอง',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFF8A958E), fontSize: 13),
                        ),
                      ),
                    )
                  else
                    ..._result.items.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      return _buildFoodItemCard(item, index, primaryColor);
                    }),
                ],
              ),
            ),
          ),

          // Bottom Fixed Save Button
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFEAEFEA))),
              boxShadow: [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 10,
                  offset: Offset(0, -3),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                onPressed: _isSaving ? null : _saveMealToDatabase,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.bookmark_added_rounded, color: Colors.white),
                label: Text(
                  _isSaving
                      ? 'กำลังบันทึกข้อมูล...'
                      : 'บันทึกมื้อ${_result.category.label} (${_result.totalCalories} kcal)',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionSummaryCard(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAF8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2EBE5), width: 1.2),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'พลังงานรวมทั้งสิ้น',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF5A6559),
                ),
              ),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '${_result.totalCalories}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: primaryColor,
                      ),
                    ),
                    const TextSpan(
                      text: ' kcal',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF7A867E),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFE2EBE5)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMacroItem(
                label: 'โปรตีน (P)',
                value: '${_result.totalProtein.toStringAsFixed(1)}g',
                color: const Color(0xFF2E6339),
                icon: Icons.egg_alt_outlined,
              ),
              Container(width: 1, height: 32, color: const Color(0xFFE2EBE5)),
              _buildMacroItem(
                label: 'คาร์โบไฮเดรต (C)',
                value: '${_result.totalCarbs.toStringAsFixed(1)}g',
                color: const Color(0xFFD48220),
                icon: Icons.grain_rounded,
              ),
              Container(width: 1, height: 32, color: const Color(0xFFE2EBE5)),
              _buildMacroItem(
                label: 'ไขมัน (F)',
                value: '${_result.totalFat.toStringAsFixed(1)}g',
                color: const Color(0xFFC74848),
                icon: Icons.water_drop_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroItem({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF6F7A72),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildFoodItemCard(DetectedFoodItem item, int index, Color primaryColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6ECE8), width: 1.1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Food Icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F6F3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.fastfood_rounded, color: Color(0xFF4B6353), size: 20),
          ),
          const SizedBox(width: 12),

          // Title & Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E2822),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.servingSize} • P:${item.protein.toStringAsFixed(1)}g  C:${item.carbs.toStringAsFixed(1)}g  F:${item.fat.toStringAsFixed(1)}g',
                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF7A867E)),
                ),
              ],
            ),
          ),

          // Calories Badge
          Text(
            '${item.calories} kcal',
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: Color(0xFFD65838),
            ),
          ),

          // Edit Button
          IconButton(
            onPressed: () => _editItem(index),
            icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF6F7A72)),
            visualDensity: VisualDensity.compact,
            tooltip: 'ปรับแต่งปริมาณ/ส่วนผสม',
          ),

          // Delete Button
          IconButton(
            onPressed: () => _removeItem(index),
            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
            visualDensity: VisualDensity.compact,
            tooltip: 'ลบรายการนี้',
          ),
        ],
      ),
    );
  }
}
