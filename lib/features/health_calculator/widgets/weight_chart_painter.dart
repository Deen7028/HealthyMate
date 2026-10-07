import 'package:flutter/material.dart';
import 'package:healthymate/shared/theme/app_theme.dart';

class WeightChartPainter extends CustomPainter {
  final List<double> weights;
  final bool isDark;

  WeightChartPainter({required this.weights, this.isDark = false});

  @override
  void paint(Canvas canvas, Size size) {
    if (weights.isEmpty) return;

    final primaryColor = isDark
        ? AppTheme.primaryLightGreen
        : AppTheme.primaryGreen;

    final linePaint = Paint()
      ..color = primaryColor
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          primaryColor.withValues(alpha: 0.25),
          primaryColor.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final dotPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;

    final dotInnerPaint = Paint()
      ..color = isDark ? const Color(0xFF1E2822) : Colors.white
      ..style = PaintingStyle.fill;

    final gridPaint = Paint()
      ..color = isDark ? const Color(0xFF2E3D34) : AppTheme.borderLight
      ..strokeWidth = 1.0;

    for (int i = 0; i <= 3; i++) {
      final y = size.height * (i / 3);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (weights.length == 1) {
      final point = Offset(size.width / 2, size.height / 2);
      canvas.drawCircle(point, 6, dotPaint);
      canvas.drawCircle(point, 3, dotInnerPaint);
      return;
    }

    final minW = weights.reduce((a, b) => a < b ? a : b) - 1.0;
    final maxW = weights.reduce((a, b) => a > b ? a : b) + 1.0;
    final range = (maxW - minW) == 0 ? 1.0 : (maxW - minW);

    final points = <Offset>[];
    final dx = size.width / (weights.length - 1);

    for (int i = 0; i < weights.length; i++) {
      final x = i * dx;
      final normalized = (weights[i] - minW) / range;
      final y = size.height - (normalized * (size.height - 20) + 10);
      points.add(Offset(x, y));
    }

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      final p0 = points[i - 1];
      final p1 = points[i];
      final cx = (p0.dx + p1.dx) / 2;
      path.cubicTo(cx, p0.dy, cx, p1.dy, p1.dx, p1.dy);
    }

    final fillPath = Path.from(path)
      ..lineTo(points.last.dx, size.height)
      ..lineTo(points.first.dx, size.height)
      ..close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);

    for (final pt in points) {
      canvas.drawCircle(pt, 5, dotPaint);
      canvas.drawCircle(pt, 2.5, dotInnerPaint);
    }
  }

  @override
  bool shouldRepaint(covariant WeightChartPainter oldDelegate) {
    return oldDelegate.weights != weights || oldDelegate.isDark != isDark;
  }
}
