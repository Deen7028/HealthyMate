import 'dart:io';
import 'package:flutter/material.dart';
import 'package:healthymate/core/database/app_database.dart';
import 'package:healthymate/core/services/sync_service.dart';
import 'package:healthymate/core/theme/app_theme.dart';
import 'package:healthymate/features/food_recognition/models/food_recognition_models.dart';
import 'package:healthymate/shared/widgets/fade_slide_entrance.dart';
import 'index.dart';

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

  Future<void> _openApiKeyDialog() async {
    final user = await AppDatabase.instance.getUser();
    final userId = user?.nUserId ?? 1;
    final currentKey = await AppDatabase.instance.getGeminiApiKey(userId);
    if (mounted) {
      GeminiApiKeyDialog.show(
        context,
        userId: userId,
        currentKey: currentKey,
        onSaved: (_) {},
      );
    }
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

      // ส่งสัญญาณให้อัปเดตสถานะค้างซิงค์ และซิงค์ขึ้น Cloud ในเบื้องหลังทันที
      SyncService.instance.updatePendingCount();
      SyncService.instance.syncPendingData();

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
                  tooltip: 'ตั้งค่า Gemini API Key',
                  onPressed: _openApiKeyDialog,
                  icon: const Icon(Icons.vpn_key_outlined, color: Color(0xFF6F7A72), size: 20),
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
                  FoodNutritionSummaryCard(
                    totalCalories: _result.totalCalories,
                    totalProtein: _result.totalProtein,
                    totalCarbs: _result.totalCarbs,
                    totalFat: _result.totalFat,
                    primaryColor: primaryColor,
                  ),

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
                    EmptyFoodRecognitionCard(
                      hasApiKey: _result.hasApiKey,
                      errorMessage: _result.errorMessage,
                      primaryColor: primaryColor,
                      onAddNewItem: _addNewItem,
                      onOpenApiKeyDialog: _openApiKeyDialog,
                    )
                  else
                    ..._result.items.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      return FadeSlideEntrance(
                        delayIndex: index,
                        child: DetectedFoodItemCard(
                          item: item,
                          onEdit: () => _editItem(index),
                          onDelete: () => _removeItem(index),
                        ),
                      );
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
                onPressed: (_isSaving || _result.items.isEmpty) ? null : _saveMealToDatabase,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Icon(
                        _result.items.isEmpty ? Icons.playlist_add_rounded : Icons.bookmark_added_rounded,
                        color: Colors.white,
                      ),
                label: Text(
                  _isSaving
                      ? 'กำลังบันทึกข้อมูล...'
                      : _result.items.isEmpty
                          ? 'กรุณาเพิ่มรายการอาหารก่อนบันทึก'
                          : 'บันทึกมื้อ${_result.category.label} (${_result.totalCalories} kcal)',
                  style: const TextStyle(
                    fontSize: 15,
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
}
