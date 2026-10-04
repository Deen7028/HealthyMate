import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// ยูทิลิตี้จัดการเส้นทาง GPS (Polyline Encoding, Douglas-Peucker Simplification & Parsing)
class RouteUtils {
  RouteUtils._();

  /// แปลงข้อความจากฐานข้อมูล (รองรับทั้ง Encoded Polyline และ JSON ดั้งเดิม) เป็น `List<LatLng>`
  static List<LatLng> parseRoutePoints(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return const [];
    }

    final trimmed = raw.trim();

    // 1. ตรวจสอบว่าจัดเก็บแบบ JSON Array ดั้งเดิมหรือไม่
    if (trimmed.startsWith('[')) {
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is List) {
          final List<LatLng> points = [];
          for (final item in decoded) {
            if (item is Map) {
              final lat = (item['lat'] as num?)?.toDouble();
              final lng = (item['lng'] as num?)?.toDouble();
              if (lat != null && lng != null) {
                points.add(LatLng(lat, lng));
              }
            }
          }
          return points;
        }
      } catch (_) {
        // หากถอดรหัส JSON ล้มเหลว ลองตรวจสอบการถอดรหัสแบบ Polyline
      }
    }

    // 2. ถอดรหัสด้วย Google Encoded Polyline Algorithm
    try {
      return PolylineCodec.decode(trimmed);
    } catch (_) {
      return const [];
    }
  }

  /// บีบอัดและแปลง `List<LatLng>` เป็น Google Encoded Polyline String
  /// [simplify]: ลดจำนวนจุดซ้ำซ้อนด้วย Douglas-Peucker ก่อนแปลง เพื่อประหยัดเนื้อที่ถึง 90%+
  /// [toleranceMeters]: ระยะคลาดเคลื่อนที่ยอมรับได้ในการลดจุด (ค่ามาตรฐาน 2.5 เมตร)
  static String toEncodedPolyline(
    List<LatLng> points, {
    bool simplify = true,
    double toleranceMeters = 2.5,
  }) {
    if (points.isEmpty) return '';

    final processPoints = simplify && points.length > 2
        ? DouglasPeucker.simplify(points, toleranceMeters: toleranceMeters)
        : points;

    return PolylineCodec.encode(processPoints);
  }
}

/// Google Encoded Polyline Algorithm (Precision = 1e5 ~ 1 เมตร)
class PolylineCodec {
  PolylineCodec._();

  /// เข้ารหัส `List<LatLng>` ให้เป็น ASCII String
  static String encode(List<LatLng> points) {
    if (points.isEmpty) return '';

    final StringBuffer buffer = StringBuffer();
    int lastLat = 0;
    int lastLng = 0;

    for (final point in points) {
      final int lat = (point.latitude * 1e5).round();
      final int lng = (point.longitude * 1e5).round();

      final int deltaLat = lat - lastLat;
      final int deltaLng = lng - lastLng;

      _encodeValue(deltaLat, buffer);
      _encodeValue(deltaLng, buffer);

      lastLat = lat;
      lastLng = lng;
    }

    return buffer.toString();
  }

  /// ถอดรหัส Encoded Polyline String กลับมาเป็น `List<LatLng>`
  static List<LatLng> decode(String encoded) {
    final List<LatLng> points = [];
    if (encoded.isEmpty) return points;

    int index = 0;
    final int len = encoded.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int b;
      int shift = 0;
      int result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20 && index < len);

      final int deltaLat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += deltaLat;

      shift = 0;
      result = 0;
      if (index >= len) break;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20 && index < len);

      final int deltaLng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += deltaLng;

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }

    return points;
  }

  static void _encodeValue(int value, StringBuffer buffer) {
    int v = value < 0 ? ~(value << 1) : (value << 1);
    while (v >= 0x20) {
      buffer.writeCharCode((0x20 | (v & 0x1f)) + 63);
      v >>= 5;
    }
    buffer.writeCharCode(v + 63);
  }
}

/// Ramer-Douglas-Peucker Algorithm สำหรับตัดจุดพิกัดส่วนเกินในเส้นทางตรง
class DouglasPeucker {
  DouglasPeucker._();

  /// ลดทอนจุดพิกัดโดยคงโครงสร้างรูปทรงทางภูมิศาสตร์ไว้
  /// [toleranceMeters]: ค่าความเบี่ยงเบนในหน่วยเมตร (แนะนำ 2.0 - 5.0 เมตรสำหรับเดิน/วิ่ง)
  static List<LatLng> simplify(
    List<LatLng> points, {
    double toleranceMeters = 2.5,
  }) {
    if (points.length <= 2) return List.from(points);

    // แปลงระยะเมตรเป็นค่าองศาประมาณการ (1 เมตร ~ 0.000009 องศา)
    final double toleranceDegrees = toleranceMeters / 111319.5;
    final double toleranceSq = toleranceDegrees * toleranceDegrees;

    final List<bool> keep = List<bool>.filled(points.length, false);
    keep.first = true;
    keep.last = true;

    _simplifySegment(points, 0, points.length - 1, toleranceSq, keep);

    final List<LatLng> result = [];
    for (int i = 0; i < points.length; i++) {
      if (keep[i]) {
        result.add(points[i]);
      }
    }
    return result;
  }

  static void _simplifySegment(
    List<LatLng> points,
    int first,
    int last,
    double toleranceSq,
    List<bool> keep,
  ) {
    if (last <= first + 1) return;

    double maxDistanceSq = 0.0;
    int indexFarthest = first;

    final LatLng p1 = points[first];
    final LatLng p2 = points[last];

    for (int i = first + 1; i < last; i++) {
      final double distSq = _perpendicularDistanceSq(points[i], p1, p2);
      if (distSq > maxDistanceSq) {
        maxDistanceSq = distSq;
        indexFarthest = i;
      }
    }

    if (maxDistanceSq > toleranceSq) {
      keep[indexFarthest] = true;
      _simplifySegment(points, first, indexFarthest, toleranceSq, keep);
      _simplifySegment(points, indexFarthest, last, toleranceSq, keep);
    }
  }

  static double _perpendicularDistanceSq(LatLng p, LatLng p1, LatLng p2) {
    final double x = p.longitude;
    final double y = p.latitude;
    final double x1 = p1.longitude;
    final double y1 = p1.latitude;
    final double x2 = p2.longitude;
    final double y2 = p2.latitude;

    final double dx = x2 - x1;
    final double dy = y2 - y1;

    if (dx == 0 && dy == 0) {
      final double diffX = x - x1;
      final double diffY = y - y1;
      return diffX * diffX + diffY * diffY;
    }

    // คำนวณ Projection t
    final double t = ((x - x1) * dx + (y - y1) * dy) / (dx * dx + dy * dy);

    double projX, projY;
    if (t < 0) {
      projX = x1;
      projY = y1;
    } else if (t > 1) {
      projX = x2;
      projY = y2;
    } else {
      projX = x1 + t * dx;
      projY = y1 + t * dy;
    }

    final double diffX = x - projX;
    final double diffY = y - projY;
    return diffX * diffX + diffY * diffY;
  }
}
