import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:healthymate/shared/theme/app_theme.dart';
import 'workout_history_card_sections.dart';

class WorkoutHistoryItemCard extends StatelessWidget {
  final Map<String, dynamic> workoutItem;

  const WorkoutHistoryItemCard({super.key, required this.workoutItem});

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
            .map(
              (pt) => LatLng(
                (pt['lat'] as num).toDouble(),
                (pt['lng'] as num).toDouble(),
              ),
            )
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
                  color: isDark
                      ? const Color(0xFF23352A)
                      : const Color(0xFFE8F3EB),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _getCategoryIcon(type),
                  color: isDark
                      ? AppTheme.primaryLightGreen
                      : const Color(0xFF2E5327),
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
                      style: TextStyle(fontSize: 12, color: textSecondary),
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
                  color: isDark
                      ? const Color(0xFF23352A)
                      : const Color(0xFFF1F6F0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 14,
                      color: isDark
                          ? AppTheme.primaryLightGreen
                          : const Color(0xFF2E5327),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDuration(duration),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppTheme.primaryLightGreen
                            : const Color(0xFF2E5327),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          WorkoutHistoryRoutePreview(points: routePoints),

          const SizedBox(height: 14),
          Divider(height: 1, color: borderColor),
          const SizedBox(height: 14),

          WorkoutHistoryStatsRow(
            isDark: isDark,
            borderColor: borderColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            distance: distance,
            calories: calories,
            duration: duration,
            type: type,
            routePoints: routePoints,
          ),
        ],
      ),
    );
  }
}
