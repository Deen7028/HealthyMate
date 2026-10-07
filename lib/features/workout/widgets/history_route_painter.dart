import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// ตัววาดภาพ Vector เส้นทางวิ่งบนการ์ดประวัติย้อนหลัง (History Route Custom Painter)
/// คำนวณ Bounds ย่อสเกลเส้นทาง พร้อมวาดจุดเริ่มต้น (เขียว) และจุดสิ้นสุด (ส้ม)
class HistoryRoutePainter extends CustomPainter {
  /// รายการพิกัดเส้นทางทั้งหมด
  final List<LatLng> points;

  HistoryRoutePainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final paint = Paint()
      ..color = const Color.fromARGB(255, 11, 255, 31)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    final double latSpan = maxLat - minLat;
    final double lngSpan = maxLng - minLng;

    const double padding = 16.0;
    final double drawWidth = size.width - (padding * 2);
    final double drawHeight = size.height - (padding * 2);

    final double scaleX = lngSpan == 0 ? 1.0 : drawWidth / lngSpan;
    final double scaleY = latSpan == 0 ? 1.0 : drawHeight / latSpan;
    final double scale = scaleX < scaleY ? scaleX : scaleY;

    final double actualWidth = lngSpan * scale;
    final double actualHeight = latSpan * scale;
    final double offsetX = padding + (drawWidth - actualWidth) / 2;
    final double offsetY = padding + (drawHeight - actualHeight) / 2;

    final path = Path();
    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      final double x = offsetX + (lngSpan == 0 ? drawWidth / 2 : (p.longitude - minLng) * scale);
      final double y = offsetY + (latSpan == 0 ? drawHeight / 2 : (maxLat - p.latitude) * scale);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);

    if (points.isNotEmpty) {
      final startPt = points.first;
      final startX = offsetX + (lngSpan == 0 ? drawWidth / 2 : (startPt.longitude - minLng) * scale);
      final startY = offsetY + (latSpan == 0 ? drawHeight / 2 : (maxLat - startPt.latitude) * scale);
      canvas.drawCircle(Offset(startX, startY), 5, Paint()..color = const Color(0xFF2E7D32));

      final endPt = points.last;
      final endX = offsetX + (lngSpan == 0 ? drawWidth / 2 : (endPt.longitude - minLng) * scale);
      final endY = offsetY + (latSpan == 0 ? drawHeight / 2 : (maxLat - endPt.latitude) * scale);
      canvas.drawCircle(Offset(endX, endY), 5, Paint()..color = const Color(0xFFD32F2F));
    }
  }

  @override
  bool shouldRepaint(covariant HistoryRoutePainter oldDelegate) => oldDelegate.points != points;
}
