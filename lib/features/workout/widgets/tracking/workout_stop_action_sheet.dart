import 'package:flutter/material.dart';

/// ยูทิลิตี้แสดงป๊อบอัพ Action Sheet เมื่อกดหยุดกิจกรรม (Workout Stop Action Sheet Dialog)
/// ให้ผู้ใช้เลือกว่าต้องการ บันทึก (Save), ละทิ้ง (Discard) หรือ ออกกำลังกายต่อ (Resume)
class WorkoutStopActionSheet {
  /// แสดง Modal Bottom Sheet สรุปเวลา ระยะทาง และแคลอรี
  static void showStopActionSheet({
    required BuildContext context,
    required String timeFormatted,
    required double distanceKm,
    required double caloriesBurned,
    required VoidCallback onSave,
    required VoidCallback onDiscard,
    required VoidCallback onResume,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 18),

            const Text(
              'สิ้นสุดกิจกรรมการออกกำลังกาย',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1C2819),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'เวลา: $timeFormatted • ระยะทาง: ${distanceKm.toStringAsFixed(2)} กม. • เผาผลาญ: ${caloriesBurned.toStringAsFixed(0)} kcal',
              style: const TextStyle(
                fontSize: 13.5,
                color: Color(0xFF5A665A),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),

            // ปุ่มบันทึกกิจกรรม
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.check_circle_rounded, size: 20),
                label: const Text(
                  'บันทึกกิจกรรมลงประวัติ',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E5327),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  onSave();
                },
              ),
            ),

            const SizedBox(height: 12),

            // ปุ่มละทิ้งกิจกรรม
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFFD32F2F),
                  size: 20,
                ),
                label: const Text(
                  'ละทิ้งกิจกรรมนี้',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFD32F2F),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFFFCDD2)),
                  backgroundColor: const Color(0xFFFFF5F5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  onDiscard();
                },
              ),
            ),

            const SizedBox(height: 10),

            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                onResume();
              },
              child: const Text(
                'ทำกิจกรรมต่อ',
                style: TextStyle(
                  color: Color(0xFF5A665A),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// แสดงแผงเลือกโหมดแผนที่ (Map Type Layer Sheet)
}
