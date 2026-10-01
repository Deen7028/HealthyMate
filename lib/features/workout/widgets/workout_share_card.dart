import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'mini_route_painter.dart';

class WorkoutShareCard extends StatelessWidget {
  final double distance;
  final int duration;
  final List<LatLng> routePoints;
  final bool isTransparent;

  const WorkoutShareCard({
    super.key,
    required this.distance,
    required this.duration,
    required this.routePoints,
    required this.isTransparent,
  });

  String _calculatePace() {
    if (distance <= 0.05 || duration <= 0) return "-:--";
    final double totalMinutes = duration / 60.0;
    final double paceDecimal = totalMinutes / distance;
    final int paceMin = paceDecimal.toInt();
    final int paceSec = ((paceDecimal - paceMin) * 60).round();
    return '$paceMin:${paceSec.toString().padLeft(2, '0')}';
  }

  String _formatDuration(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '$minsน. $secsวิ';
  }

  @override
  Widget build(BuildContext context) {
    final textShadows = isTransparent
        ? const [
            Shadow(color: Colors.black87, blurRadius: 6, offset: Offset(0, 1)),
          ]
        : null;

    return Container(
      width: 280,
      height: 480,
      decoration: BoxDecoration(
        color: isTransparent ? Colors.transparent : const Color(0xFF233620),
        borderRadius: BorderRadius.circular(24),
        border: isTransparent
            ? null
            : Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1.5,
              ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (distance > 0.05) ...[
              Text(
                'ระยะทาง',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  shadows: textShadows,
                ),
              ),
              Text(
                '${distance.toStringAsFixed(2)} กม.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  shadows: textShadows,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'เพซ',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  shadows: textShadows,
                ),
              ),
              Text(
                '${_calculatePace()} /กม.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  shadows: textShadows,
                ),
              ),
              const SizedBox(height: 14),
            ],
            Text(
              'เวลา',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                shadows: textShadows,
              ),
            ),
            Text(
              _formatDuration(duration),
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w900,
                shadows: textShadows,
              ),
            ),
            const SizedBox(height: 24),
            if (routePoints.length >= 2)
              CustomPaint(
                size: const Size(140, 90),
                painter: MiniRoutePainter(points: routePoints),
              )
            else
              const SizedBox(height: 90),
            const SizedBox(height: 30),
            Text(
              'HEALTHYMATE',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 3,
                shadows: textShadows,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
