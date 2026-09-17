import 'package:flutter/material.dart';
import '../models/workout_models.dart';

/// Helper utilities และ UI Dialog สำหรับ Workout
class WorkoutDialogUtils {
  /// แสดง Dialog ขออนุญาตเปิด GPS
  static Future<bool?> showGpsPermissionDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
        title: Row(
          children: const [
            Icon(Icons.location_searching_rounded, color: Color(0xFF2E5327), size: 28),
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
              style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: Color(0xFF2E5327)),
            ),
            SizedBox(height: 8),
            Text(
              'HealthyMate จำเป็นต้องใช้ GPS เพื่อคำนวณระยะทาง ความเร็ว และการเผาผลาญแคลอรีขณะออกกำลังกายอย่างแม่นยำ\n\nต้องการเปิดใช้งาน GPS ตอนนี้หรือไม่?',
              style: TextStyle(fontSize: 13.5, color: Color(0xFF5A665A), height: 1.4),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('ไม่อนุญาต', style: TextStyle(color: Color(0xFF8B9889), fontWeight: FontWeight.w600)),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.check_circle_outline, size: 18),
            label: const Text('เปิดใช้งาน GPS'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E5327),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );
  }

  /// แสดง Action Sheet สิ้นสุดกิจกรรม: ละทิ้ง หรือ บันทึก
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
                label: const Text('บันทึกกิจกรรมลงประวัติ', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E5327),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
                icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFD32F2F), size: 20),
                label: const Text('ละทิ้งกิจกรรมนี้', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFFD32F2F))),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFFFCDD2)),
                  backgroundColor: const Color(0xFFFFF5F5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
              child: const Text('ทำกิจกรรมต่อ', style: TextStyle(color: Color(0xFF5A665A), fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  /// แสดงแผงเลือกโหมดแผนที่ (Map Type Layer Sheet)
  static void openMapTypeSelector({
    required BuildContext context,
    required AppMapType currentType,
    required bool showTraffic,
    required ValueChanged<AppMapType> onSelectType,
    required ValueChanged<bool> onToggleTraffic,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'ประเภทแผนที่ (Map Type)',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1C2819),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: AppMapType.values.map((type) {
                  final isSelected = currentType == type;
                  return GestureDetector(
                    onTap: () {
                      onSelectType(type);
                      setSheetState(() {});
                      Navigator.of(ctx).pop();
                    },
                    child: Column(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: getMapTypePreviewColor(type),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF2E5327) : const Color(0xFFE2E9E0),
                              width: isSelected ? 3 : 1.2,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF2E5327).withValues(alpha: 0.25),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Icon(
                            type.icon,
                            color: type == AppMapType.satellite || type == AppMapType.hybrid
                                ? Colors.white
                                : const Color(0xFF2E5327),
                            size: 32,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          getShortMapName(type),
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? const Color(0xFF2E5327) : const Color(0xFF5A665A),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),
              const Divider(height: 1, color: Color(0xFFE8EFE8)),
              const SizedBox(height: 14),

              const Text(
                'รายละเอียดแผนที่เพิ่มเติม',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1C2819),
                ),
              ),
              const SizedBox(height: 8),

              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeThumbColor: const Color(0xFF2E5327),
                secondary: const Icon(Icons.traffic_rounded, color: Color(0xFF2E5327)),
                title: const Text('เส้นทางการจราจร (Traffic)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                subtitle: const Text('แสดงสภาพการจราจรแบบเรียลไทม์บนเส้นทาง', style: TextStyle(fontSize: 12, color: Color(0xFF7A887A))),
                value: showTraffic,
                onChanged: (val) {
                  onToggleTraffic(val);
                  setSheetState(() {});
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Color getMapTypePreviewColor(AppMapType type) {
    switch (type) {
      case AppMapType.standard:
        return const Color(0xFFE3EDE1);
      case AppMapType.satellite:
        return const Color(0xFF213A28);
      case AppMapType.hybrid:
        return const Color(0xFFDED0B6);
    }
  }

  static String getShortMapName(AppMapType type) {
    switch (type) {
      case AppMapType.standard:
        return 'เริ่มต้น';
      case AppMapType.satellite:
        return 'ดาวเทียม';
      case AppMapType.hybrid:
        return 'ไฮบริด';
    }
  }
}
