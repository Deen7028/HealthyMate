import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:healthymate/shared/theme/app_theme.dart';
import 'package:healthymate/features/workout/pages/workout_share_page.dart';
import 'history_route_painter.dart';

/// วิดเจ็ตแสดงภาพวาดมินิแมปเส้นทางวิ่งย้อนหลัง (Workout History Route Preview Widget)
class WorkoutHistoryRoutePreview extends StatelessWidget {
  /// พิกัดเส้นทางสำหรับนำไปวาดภาพ Vector ด้วย CustomPainter
  final List<LatLng> points;

  const WorkoutHistoryRoutePreview({super.key, required this.points});

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
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
                    painter: HistoryRoutePainter(points: points),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.map_rounded,
                          color: Colors.white,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          points.length >= 2 ? 'เส้นทางจริง' : 'ตำแหน่งกิจกรรม',
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
    );
  }
}

class WorkoutHistoryStatsRow extends StatelessWidget {
  final bool isDark;
  final Color borderColor;
  final Color textPrimary;
  final Color textSecondary;
  final double distance;
  final double calories;
  final int duration;
  final String type;
  final List<LatLng> routePoints;

  const WorkoutHistoryStatsRow({
    super.key,
    required this.isDark,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.distance,
    required this.calories,
    required this.duration,
    required this.type,
    required this.routePoints,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Icon(
                Icons.route_rounded,
                size: 18,
                color: isDark
                    ? AppTheme.primaryLightGreen
                    : const Color(0xFF4A7C42),
              ),
              const SizedBox(width: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ระยะทาง',
                    style: TextStyle(fontSize: 11, color: textSecondary),
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
        Container(height: 28, width: 1, color: borderColor),
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
                    style: TextStyle(fontSize: 11, color: textSecondary),
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
            color: isDark
                ? AppTheme.primaryLightGreen
                : const Color(0xFF2E5327),
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
    );
  }
}
