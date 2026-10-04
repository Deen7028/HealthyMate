import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

/// บริการ Map Matching ดึงเส้นทาง GPS ไป Snap บนถนนหรือทางเท้าจริง
/// ใช้ OSRM Map Matching Service หรือ Fallback กลับสู่พิกัดเดิมหากไม่มีสัญญาณอินเทอร์เน็ต
class MapMatchingService {
  MapMatchingService._();
  static final MapMatchingService instance = MapMatchingService._();

  static const String _osrmBaseUrl = 'https://router.project-osrm.org/match/v1';

  /// ดึงจุดพิกัดเส้นทางไปเทียบกับแผนที่ถนนจริง (Post-workout or Batch processing)
  /// [points]: จุดพิกัดเส้นทางทั้งหมด
  /// [mode]: 'walking' สำหรับเดิน/วิ่ง, 'cycling' สำหรับปั่นจักรยาน
  /// คืนค่า `List<LatLng>` ที่ถูก Snap แล้ว (หรือพิกัดเดิมหาก Offline / ล้มเหลว)
  Future<List<LatLng>> matchRoute(
    List<LatLng> points, {
    String mode = 'walking',
  }) async {
    if (points.length < 3) {
      return points;
    }

    try {
      // แบ่ง Chunk สูงสุดไม่เกิน 60 จุดต่อ Request เพื่อป้องกัน URL Length Limit ของ OSRM
      const int chunkSize = 60;
      final List<LatLng> matchedResults = [];

      for (int i = 0; i < points.length; i += (chunkSize - 1)) {
        final end = (i + chunkSize < points.length) ? (i + chunkSize) : points.length;
        final segment = points.sublist(i, end);
        if (segment.length < 2) continue;

        final segmentMatched = await _matchChunk(segment, mode: mode);
        if (matchedResults.isEmpty) {
          matchedResults.addAll(segmentMatched);
        } else {
          // ข้ามจุดแรกของ chunk ถัดไปเพื่อไม่ให้จุดซ้ำ
          matchedResults.addAll(segmentMatched.skip(1));
        }
      }

      if (matchedResults.isNotEmpty) {
        debugPrint('MapMatching: Snapped ${points.length} points into ${matchedResults.length} points');
        return matchedResults;
      }
    } catch (e) {
      debugPrint('MapMatchingService error, falling back to raw route: $e');
    }

    // Graceful fallback คืนค่าเดิมกรณี offline หรือเรียก OSRM ไม่สำเร็จ
    return points;
  }

  Future<List<LatLng>> _matchChunk(
    List<LatLng> chunk, {
    required String mode,
  }) async {
    try {
      // OSRM Format: {lon},{lat};{lon},{lat}...
      final coordinatesStr = chunk
          .map((p) => '${p.longitude.toStringAsFixed(6)},${p.latitude.toStringAsFixed(6)}')
          .join(';');

      // Radiuses: กำหนดขอบเขตค้นหาถนนรอบจุดพิกัด (เช่น 25 เมตร)
      final radiusesStr = List.filled(chunk.length, '25').join(';');

      final profile = mode == 'cycling' ? 'cycling' : 'foot';
      final url = Uri.parse(
        '$_osrmBaseUrl/$profile/$coordinatesStr?geometries=geojson&overview=full&radiuses=$radiusesStr',
      );

      final response = await http.get(url).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == 'Ok' && data['matchings'] is List && (data['matchings'] as List).isNotEmpty) {
          final List<LatLng> chunkResult = [];
          for (final matching in data['matchings']) {
            final geometry = matching['geometry'];
            if (geometry != null && geometry['coordinates'] is List) {
              for (final coord in geometry['coordinates']) {
                if (coord is List && coord.length >= 2) {
                  final double lng = (coord[0] as num).toDouble();
                  final double lat = (coord[1] as num).toDouble();
                  chunkResult.add(LatLng(lat, lng));
                }
              }
            }
          }
          if (chunkResult.isNotEmpty) {
            return chunkResult;
          }
        }
      }
    } catch (e) {
      debugPrint('OSRM chunk match request failed: $e');
    }

    return chunk;
  }
}
