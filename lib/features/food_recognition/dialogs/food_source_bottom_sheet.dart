import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:healthymate/core/theme/app_theme.dart';
import 'package:healthymate/features/food_recognition/dialogs/food_recognition_result_sheet.dart';
import 'package:healthymate/features/food_recognition/services/food_recognition_service.dart';

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
      final result = await FoodRecognitionService.instance.analyzeFoodImage(file);

      if (!mounted) return;

      // ปิด FoodSourceBottomSheet
      Navigator.of(context).pop();

      // แสดงผลลัพธ์การสแกนใน Result Sheet บน root context
      showModalBottomSheet(
        context: navigator.context,
        isScrollControlled: true,
        useRootNavigator: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => FoodRecognitionResultSheet(scanResult: result),
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
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 4,
            margin: const EdgeInsets.only(bottom: 18),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const Text(
            'บันทึกอาหารด้วย AI Food Scanner',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E2822),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'ถ่ายภาพอาหารของคุณเพื่อให้ AI ประเมินแคลอรีและสารอาหารทันที',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: Color(0xFF7A867E)),
          ),
          const SizedBox(height: 22),
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: const [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
                    strokeWidth: 3,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'AI กำลังวิเคราะห์รูปภาพอาหาร...',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E2822)),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'จำแนกหลายเมนู และคำนวณแคลอรี สารอาหาร P/C/F',
                    style: TextStyle(fontSize: 12, color: Color(0xFF7A867E)),
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
                    color: AppTheme.primaryGreen,
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
                    color: const Color(0xFF3F824E),
                    onTap: () => _pickImage(ImageSource.gallery),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildOptionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String sublabel,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF7FAF8),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2EBE5), width: 1.2),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E2822),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              sublabel,
              style: const TextStyle(fontSize: 11, color: Color(0xFF8A958E)),
            ),
          ],
        ),
      ),
    );
  }
}

