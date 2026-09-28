import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:healthymate/shared/theme/app_theme.dart';
import 'package:healthymate/features/workout/pages/workout_share_page.dart';
import 'history_route_painter.dart';

class WorkoutHistoryItemCard extends StatelessWidget {
  final Map<String, dynamic> workoutItem;

  const WorkoutHistoryItemCard({
    super.key,
    required this.workoutItem,
  });

  String _formatDuration(int seconds) {
    final hrs = seconds ~/ 3600;
    final mins = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    if (hrs > 0) {
      return '$hrs ชม. $mins นาที';
    }
    if (mins > 0) {
      return '$mins นาที $secs วิ';
    }
    return '$secs วินาที';
  }

  String _formatDateTime(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      final day = dt.day.toString().padLeft(2, '0');
      final month = dt.month.toString().padLeft(2, '0');
      final year = dt.year + 543; // พ.ศ.
      final hour = dt.hour.toString().padLeft(2, '0');
      final min = dt.minute.toString().padLeft(2, '0');
      return '$day/$month/$year $hour:$min น.';
    } catch (_) {
      return dateStr;
    }
  }

  IconData _getCategoryIcon(String type) {
    final t = type.toLowerCase();
    if (t.contains('เดิน') || t.contains('walk')) {
      return Icons.directions_walk_rounded;
    } else if (t.contains('จักรยาน') ||
        t.contains('cycl') ||
        t.contains('bike')) {
      return Icons.directions_bike_rounded;
    }
    return Icons.directions_run_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = AppTheme.getBackgroundColor(isDark);
    final textPrimary = AppTheme.getTextPrimaryColor(isDark);
    final textSecondary = AppTheme.getTextSecondaryColor(isDark);
    final borderColor = AppTheme.getBorderColor(isDark);

    final type = workoutItem['sType']?.toString() ?? 'กิจกรรม';
    final distance = (workoutItem['nDistance'] as num?)?.toDouble() ?? 0.0;
    final duration = (workoutItem['nDuration'] as num?)?.toInt() ?? 0;
    final calories =
        (workoutItem['nCaloriesBurned'] as num?)?.toDouble() ?? 0.0;
    final dateStr = workoutItem['dtWorkoutDate']?.toString();
    final rawRoutePoints = workoutItem['sRoutePoints']?.toString();
    List<LatLng> routePoints = [];
    if (rawRoutePoints != null && rawRoutePoints.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawRoutePoints) as List<dynamic>;
        routePoints = decoded
            .map((pt) => LatLng(
                  (pt['lat'] as num).toDouble(),
                  (pt['lng'] as num).toDouble(),
                ))
            .toList();
      } catch (_) {}
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // หัวการ์ด: ไอคอน + ชื่อกิจกรรม + วันเวลา
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF23352A) : const Color(0xFFE8F3EB),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _getCategoryIcon(type),
                  color: isDark ? AppTheme.primaryLightGreen : const Color(0xFF2E5327),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatDateTime(dateStr),
                      style: TextStyle(
                        fontSize: 12,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF23352A) : const Color(0xFFF1F6F0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 14,
                      color: isDark ? AppTheme.primaryLightGreen : const Color(0xFF2E5327),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDuration(duration),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppTheme.primaryLightGreen : const Color(0xFF2E5327),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (routePoints.isNotEmpty) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 200,
                width: double.infinity,
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: CustomPaint(
                        painter: HistoryRoutePainter(points: routePoints),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.map_rounded,
                                color: Colors.white, size: 12),
                            const SizedBox(width: 4),
                            Text(
                              routePoints.length >= 2
                                  ? 'เส้นทางจริง'
                                  : 'ตำแหน่งกิจกรรม',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 14),
          Divider(height: 1, color: borderColor),
          const SizedBox(height: 14),

          // สถิติ: ระยะทาง และ แคลอรี
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.route_rounded,
                      size: 18,
                      color: isDark ? AppTheme.primaryLightGreen : const Color(0xFF4A7C42),
                    ),
                    const SizedBox(width: 6),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ระยะทาง',
                          style: TextStyle(
                            fontSize: 11,
                            color: textSecondary,
                          ),
                        ),
                        Text(
                          '${distance.toStringAsFixed(2)} km',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                height: 28,
                width: 1,
                color: borderColor,
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.local_fire_department_rounded,
                      size: 20,
                      color: Color(0xFFD9534F),
                    ),
                    const SizedBox(width: 6),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'เผาผลาญ',
                          style: TextStyle(
                            fontSize: 11,
                            color: textSecondary,
                          ),
                        ),
                        Text(
                          '${calories.toStringAsFixed(0)} kcal',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: Icon(
                  Icons.share_rounded,
                  color: isDark ? AppTheme.primaryLightGreen : const Color(0xFF2E5327),
                  size: 22,
                ),
                tooltip: 'แชร์กิจกรรม',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => WorkoutSharePage(
                        sType: type,
                        nDistance: distance,
                        nDuration: duration,
                        nCalories: calories,
                        routePoints: routePoints,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
