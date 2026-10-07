// ส่วนนี้อธิบายบทบาทของไฟล์: แผ่นตัวเลือกด้านล่าง ที่หลายฟีเจอร์นำไปใช้ร่วมกัน (food source bottom sheet)
// คอมเมนท์ภาษาไทยถูกใส่ไว้เป็นส่วนๆ เพื่อช่วยไล่ flow โดยไม่เปลี่ยนพฤติกรรมเดิมของโค้ด

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:healthymate/shared/theme/app_theme.dart';
import 'package:image_picker/image_picker.dart';
import 'package:healthymate/core/services/routine_state/routine_state_notifier.dart';
import 'package:healthymate/features/food_recognition/widgets/food_recognition_result_sheet.dart';
import 'package:healthymate/features/food_recognition/services/food_recognition_service.dart';

part 'food_source_bottom_sheet_option.dart';

class FoodSourceBottomSheet extends StatefulWidget {
  const FoodSourceBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const FoodSourceBottomSheet(),
    );
  }

  @override
  State<FoodSourceBottomSheet> createState() => _FoodSourceBottomSheetState();
}

class _FoodSourceBottomSheetState extends State<FoodSourceBottomSheet> {
  bool _isLoading = false;

  Future<void> _pickImage(ImageSource source) async {
    final navigator = Navigator.of(context, rootNavigator: true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 88,
      );

      if (pickedFile == null) return;
      final file = File(pickedFile.path);

      if (!mounted) return;
      setState(() => _isLoading = true);

      // เรียกใช้งาน AI Service
      final result = await FoodRecognitionService.instance.analyzeFoodImage(
        file,
      );

      if (!mounted) return;

      // ปิด FoodSourceBottomSheet
      Navigator.of(context).pop();

      // แสดงผลลัพธ์การสแกนใน Result Sheet บน root context
      showModalBottomSheet(
        context: navigator.context,
        isScrollControlled: true,
        useRootNavigator: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => FoodRecognitionResultSheet(
          scanResult: result,
          onSavedSuccessfully: () {
            RoutineStateNotifier.instance.loadData();
          },
        ),
      );
    } catch (e, stack) {
      debugPrint('Error picking image: $e\n$stack');
      if (mounted) {
        setState(() => _isLoading = false);
      }
      messenger.showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาดในการประมวลผลรูปภาพ: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = AppTheme.getBackgroundColor(isDark);
    final textPrimary = AppTheme.getTextPrimaryColor(isDark);
    final textSecondary = AppTheme.getTextSecondaryColor(isDark);

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 4,
            margin: const EdgeInsets.only(bottom: 18),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF4A584E) : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          Text(
            'บันทึกอาหารด้วย AI Food Scanner',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'ถ่ายภาพอาหารของคุณเพื่อให้ AI ประเมินแคลอรีและสารอาหารทันที',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: textSecondary),
          ),
          const SizedBox(height: 22),
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppTheme.primaryGreen,
                    ),
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'AI กำลังวิเคราะห์รูปภาพอาหาร...',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'จำแนกหลายเมนู และคำนวณแคลอรี สารอาหาร P/C/F',
                    style: TextStyle(fontSize: 12, color: textSecondary),
                  ),
                ],
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: _buildOptionButton(
                    context: context,
                    icon: Icons.camera_alt_rounded,
                    label: 'เปิดกล้องถ่ายสด',
                    sublabel: 'Camera',
                    color: isDark
                        ? AppTheme.primaryLightGreen
                        : AppTheme.primaryGreen,
                    onTap: () => _pickImage(ImageSource.camera),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildOptionButton(
                    context: context,
                    icon: Icons.photo_library_rounded,
                    label: 'เลือกจากแกลเลอรี',
                    sublabel: 'Gallery Import',
                    color: isDark
                        ? const Color(0xFF5CA86E)
                        : const Color(0xFF3F824E),
                    onTap: () => _pickImage(ImageSource.gallery),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
