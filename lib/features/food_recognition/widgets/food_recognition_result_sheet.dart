import 'dart:io';
import 'package:flutter/material.dart';
import 'package:healthymate/core/database/app_database.dart';
import 'package:healthymate/core/services/api_service.dart';
import 'package:healthymate/core/services/routine_state_notifier.dart';
import 'package:healthymate/core/services/sync_service.dart';
import 'package:healthymate/features/food_recognition/models/food_recognition_models.dart';
import 'package:healthymate/shared/theme/app_theme.dart';
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
  double _userWeight = 65.0;

  @override
  void initState() {
    super.initState();
    _result = widget.scanResult;
    _loadUserWeight();
  }

  Future<void> _loadUserWeight() async {
    final user = await AppDatabase.instance.getCurrentUser();
    final weight = user?.nWeight ?? 0.0;
    if (weight > 0 && mounted) {
      setState(() {
        _userWeight = weight;
      });
    } 
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
    final user = await AppDatabase.instance.getCurrentUser();
    final userId = user?.nUserId;
    if (userId == null) return;
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
      final user = await AppDatabase.instance.getCurrentUser();
      final userId = user?.nUserId;
      if (userId == null) return;

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

      // 🟢 Auto-Routine Sync: ตรวจจับและอัปเดตเป้าหมายกิจวัตรให้อัตโนมัติ (Protein & Meals)
      final autoSyncedRoutines = <String>[];
      final routines = await AppDatabase.instance.getRoutines(userId: userId);
      final todayStr = DateTime.now().toIso8601String().substring(0, 10);

      for (final r in routines) {
        final routineId = (r['nRoutineId'] as num?)?.toInt() ?? 0;
        final title = (r['sTitle']?.toString() ?? '').toLowerCase();
        final unit = (r['unit']?.toString() ?? (r['sUnit']?.toString() ?? '')).toLowerCase();

        if (routineId <= 0) continue;

        // 1. ซิงค์โปรตีน
        if (title.contains('โปรตีน') || unit.contains('g') || unit.contains('กรัม') || unit.contains('โปรตีน')) {
          if (_result.totalProtein > 0) {
            final targetVal = (r['targetValue'] as num?)?.toDouble() ?? 1.0;
            final existingLogs = await AppDatabase.instance.getRoutineLogsForDate(userId: userId, dateStr: todayStr);
            final currentLog = existingLogs.firstWhere((l) => (l['nRoutineId'] as num?)?.toInt() == routineId, orElse: () => {});
            final currentProgress = (currentLog['nProgressValue'] as num?)?.toDouble() ?? 0.0;
            final newProgress = currentProgress + _result.totalProtein;
            final isDone = newProgress >= targetVal;

            await AppDatabase.instance.insertOrUpdateRoutineLog(
              routineId: routineId,
              dateStr: todayStr,
              progressValue: newProgress,
              isCompleted: isDone,
            );
            // ซิงค์ขึ้น Server
            HealthApiService.updateRoutineProgressRemote(
              routineId: routineId,
              date: todayStr,
              progressValue: newProgress,
              isCompleted: isDone,
            );
            autoSyncedRoutines.add('โปรตีน (+${_result.totalProtein.toStringAsFixed(1)}g)');
          }
        }
        // 2. ซิงค์มื้ออาหาร / ผัก / ผลไม้
        else if (title.contains('มื้อ') || title.contains('อาหาร') || title.contains('ผัก') || title.contains('สลัด') || title.contains('ผลไม้')) {
          await AppDatabase.instance.insertOrUpdateRoutineLog(
            routineId: routineId,
            dateStr: todayStr,
            progressValue: 1.0,
            isCompleted: true,
          );
          // ซิงค์ขึ้น Server
          HealthApiService.updateRoutineProgressRemote(
            routineId: routineId,
            date: todayStr,
            progressValue: 1.0,
            isCompleted: true,
          );
          autoSyncedRoutines.add('${r['sTitle']} (เสร็จแล้ว)');
        }
      }

      // Notify RoutineStateNotifier to reload state across the app
      RoutineStateNotifier.instance.loadData(userId: userId);

      // ส่งสัญญาณให้อัปเดตสถานะค้างซิงค์ และซิงค์ขึ้น Cloud ในเบื้องหลังทันที
      SyncService.instance.updatePendingCount();
      SyncService.instance.syncPendingData();

      if (mounted) {
        Navigator.pop(context);
        final String syncMsg = autoSyncedRoutines.isNotEmpty
            ? '\n🎯 ซิงค์กิจวัตรสำเร็จ: ${autoSyncedRoutines.join(', ')}'
            : '';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('บันทึกมื้อ${_result.category.label} (${_result.totalCalories} kcal) สำเร็จ!$syncMsg'),
                ),
              ],
            ),
            backgroundColor: AppTheme.primaryGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 4),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = AppTheme.getBackgroundColor(isDark);
    final textPrimary = AppTheme.getTextPrimaryColor(isDark);
    final textSecondary = AppTheme.getTextSecondaryColor(isDark);
    final borderColor = AppTheme.getBorderColor(isDark);
    final surfaceBg = AppTheme.getSurfaceColor(isDark);
    final primaryColor = isDark ? AppTheme.primaryLightGreen : AppTheme.primaryGreen;

    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag Handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF4A584E) : Colors.grey.shade300,
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
                    color: primaryColor.withValues(alpha: isDark ? 0.2 : 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.auto_awesome_rounded, color: primaryColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ผลวิเคราะห์อาหาร AI Vision',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      Text(
                        'จำแนกหลายเมนู พร้อมแจกแจงสารอาหารหลัก P/C/F',
                        style: TextStyle(fontSize: 12, color: textSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'ตั้งค่า Gemini API Key',
                  onPressed: _openApiKeyDialog,
                  icon: Icon(Icons.vpn_key_outlined, color: textSecondary, size: 20),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close_rounded, color: textSecondary),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: borderColor),

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
                          color: surfaceBg,
                          child: File(_result.imagePath).existsSync()
                              ? Image.file(
                                  File(_result.imagePath),
                                  fit: BoxFit.cover,
                                )
                              : Icon(Icons.restaurant_rounded, size: 36, color: textSecondary),
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Meal Category Selector
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'เลือกประเภทมื้ออาหาร',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: textSecondary,
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
                                      color: isSel ? Colors.white : textSecondary,
                                    ),
                                  ),
                                  selected: isSel,
                                  selectedColor: isDark ? const Color(0xFF2E5327) : primaryColor,
                                  backgroundColor: surfaceBg,
                                  side: BorderSide(
                                    color: isSel ? (isDark ? AppTheme.primaryLightGreen : primaryColor) : borderColor,
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

                  // Macronutrients Summary Banner Card (Idea 1: TDEE Energy Balance)
                  FoodNutritionSummaryCard(
                    totalCalories: _result.totalCalories,
                    totalProtein: _result.totalProtein,
                    totalCarbs: _result.totalCarbs,
                    totalFat: _result.totalFat,
                    primaryColor: primaryColor,
                  ),

                  const SizedBox(height: 16),

                  // 🔥 Burn-It-Off AI Advisor Card (Idea 3: Burn-It-Off Advisor)
                  BurnItOffAdvisorCard(
                    totalCalories: _result.totalCalories,
                    userWeight: _userWeight,
                    primaryColor: primaryColor,
                  ),

                  const SizedBox(height: 22),

                  // Multi-item Food List Section Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            'เมนูที่ตรวจพบในภาพ',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: isDark ? 0.2 : 0.12),
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
            decoration: BoxDecoration(
              color: cardBg,
              border: Border(top: BorderSide(color: borderColor)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? const Color(0xFF2E5327) : primaryColor,
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
