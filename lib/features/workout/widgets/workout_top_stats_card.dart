// ส่วนนี้อธิบายบทบาทของไฟล์: วิดเจ็ตย่อยของ UI ในฟีเจอร์การติดตามและประวัติการออกกำลังกาย (workout top stats card)
// คอมเมนท์ภาษาไทยถูกใส่ไว้เป็นส่วนๆ เพื่อช่วยไล่ flow โดยไม่เปลี่ยนพฤติกรรมเดิมของโค้ด

import 'package:flutter/material.dart';
import 'package:healthymate/features/workout/models/workout_models.dart';
part 'workout_top_stats_card_header.dart';

/// วิดเจ็ตการ์ดแสดงผลสถิติด้านบนของหน้าจอออกกำลังกาย (Workout Top Stats Dashboard Card Widget)
/// แสดงหมวดหมู่กิจกรรม, สถานะเวลา (นับขึ้น/ถอยหลัง), ระยะทางกิโลเมตร และแคลอรีเผาผลาญ
class WorkoutTopStatsCard extends StatelessWidget {
  /// หมวดหมู่กิจกรรมที่กำลังทำอยู่
  final WorkoutCategory category;

  /// สถานะกำลังจับเวลาบันทึกกิจกรรมอยู่
  final bool isRunning;

  /// รูปแบบแผนที่ที่เลือกใช้งาน
  final AppMapType mapType;

  /// ข้อความเวลาที่ฟอร์แมตแล้ว (เช่น 00:15:30)
  final String formattedTime;

  /// ระยะทางสะสม (กิโลเมตร)
  final double distanceKm;

  /// แคลอรีสะสม (kcal)
  final double caloriesBurned;

  /// แอนิเมชันกะพริบสำหรับจุดไฟสถานะ (Pulse Animation)
  final Animation<double> pulseAnimation;

  /// คอลแบ็กเมื่อกดเปลี่ยนหมวดหมู่กิจกรรม
  final VoidCallback? onChangeCategoryTap;

  /// แฟล็กโหมดเวลาเป้าหมายถอยหลัง
  final bool isCountdownMode;

  const WorkoutTopStatsCard({
    super.key,
    required this.category,
    required this.isRunning,
    required this.mapType,
    required this.formattedTime,
    required this.distanceKm,
    required this.caloriesBurned,
    required this.pulseAnimation,
    this.onChangeCategoryTap,
    this.isCountdownMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkModeMap =
        mapType == AppMapType.hybrid || mapType == AppMapType.satellite;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: isDarkModeMap
            ? const Color(0xFF1E281F).withValues(alpha: 0.95)
            : const Color(0xFFF7FAF7).withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: isDarkModeMap ? Colors.white24 : Colors.white,
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildStatusAndCategoryHeader(isDarkModeMap),

          const SizedBox(height: 8),

          Text(
            isCountdownMode ? 'เวลานับถอยหลัง' : 'เวลา',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDarkModeMap
                  ? const Color(0xFFA0ACA0)
                  : const Color(0xFF5A665A),
              letterSpacing: 0.2,
            ),
          ),

          Text(
            formattedTime,
            style: TextStyle(
              fontSize: 38,
              fontWeight: FontWeight.w900,
              color: isDarkModeMap ? Colors.white : const Color(0xFF1E281F),
              letterSpacing: -1,
            ),
          ),

          Divider(
            height: 1,
            color: isDarkModeMap ? Colors.white12 : const Color(0xFFE4ECE2),
          ),

          Row(
            children: [
              if (category.isMoving) ...[
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'ระยะทาง',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDarkModeMap
                              ? const Color(0xFFA0ACA0)
                              : const Color(0xFF677366),
                        ),
                      ),
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0, end: distanceKm),
                        duration: const Duration(milliseconds: 2500),
                        curve: Curves.easeOutCubic,
                        builder: (context, val, _) {
                          return RichText(
                            text: TextSpan(
                              text: val.toStringAsFixed(2),
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: isDarkModeMap
                                    ? const Color(0xFF90DB89)
                                    : const Color(0xFF2E5327),
                                letterSpacing: -0.5,
                              ),
                              children: [
                                TextSpan(
                                  text: ' km',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: isDarkModeMap
                                        ? const Color(0xFFA0ACA0)
                                        : const Color(0xFF5A665A),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                Container(
                  height: 36,
                  width: 1,
                  color: isDarkModeMap
                      ? Colors.white12
                      : const Color(0xFFE4ECE2),
                ),
              ],

              Expanded(
                child: Column(
                  children: [
                    Text(
                      'แคลอรี',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDarkModeMap
                            ? const Color(0xFFA0ACA0)
                            : const Color(0xFF677366),
                      ),
                    ),
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: caloriesBurned),
                      duration: const Duration(milliseconds: 2500),
                      curve: Curves.easeOutCubic,
                      builder: (context, val, _) {
                        return RichText(
                          text: TextSpan(
                            text: val.toStringAsFixed(0),
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: isDarkModeMap
                                  ? Colors.white
                                  : const Color(0xFF1E281F),
                              letterSpacing: -0.5,
                            ),
                            children: [
                              TextSpan(
                                text: ' kcal',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isDarkModeMap
                                      ? const Color(0xFFA0ACA0)
                                      : const Color(0xFF5A665A),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
