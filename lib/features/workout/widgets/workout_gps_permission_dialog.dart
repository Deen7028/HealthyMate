// ส่วนนี้อธิบายบทบาทของไฟล์: วิดเจ็ตย่อยของ UI ในฟีเจอร์การติดตามและประวัติการออกกำลังกาย (workout gps permission dialog)
// คอมเมนท์ภาษาไทยถูกใส่ไว้เป็นส่วนๆ เพื่อช่วยไล่ flow โดยไม่เปลี่ยนพฤติกรรมเดิมของโค้ด

import 'package:flutter/material.dart';

class WorkoutGpsPermissionDialog {
  static Future<bool?> showGpsPermissionDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
        title: Row(
          children: const [
            Icon(
              Icons.location_searching_rounded,
              color: Color(0xFF2E5327),
              size: 28,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'ขอสิทธิ์เข้าถึงตำแหน่ง (GPS)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1C2819),
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'ขณะนี้ระบบตรวจพบว่า GPS ยังไม่ได้เปิดใช้งาน',
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2E5327),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'HealthyMate จำเป็นต้องใช้ GPS เพื่อคำนวณระยะทาง ความเร็ว และการเผาผลาญแคลอรีขณะออกกำลังกายอย่างแม่นยำ\n\nต้องการเปิดใช้งาน GPS ตอนนี้หรือไม่?',
              style: TextStyle(
                fontSize: 13.5,
                color: Color(0xFF5A665A),
                height: 1.4,
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'ไม่อนุญาต',
              style: TextStyle(
                color: Color(0xFF8B9889),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.check_circle_outline, size: 18),
            label: const Text('เปิดใช้งาน GPS'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E5327),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );
  }

  /// แสดง Action Sheet สิ้นสุดกิจกรรม: ละทิ้ง หรือ บันทึก
}
