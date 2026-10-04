import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:healthymate/core/utils/route_utils.dart';

void main() {
  group('RouteUtils & PolylineCodec Tests', () {
    test('encode and decode polyline correctly', () {
      final originalPoints = [
        const LatLng(13.7563, 100.5018),
        const LatLng(13.7565, 100.5020),
        const LatLng(13.7570, 100.5030),
      ];

      final encoded = RouteUtils.toEncodedPolyline(originalPoints, simplify: false);
      expect(encoded.isNotEmpty, isTrue);

      final decoded = RouteUtils.parseRoutePoints(encoded);
      expect(decoded.length, equals(originalPoints.length));
      for (int i = 0; i < originalPoints.length; i++) {
        expect(decoded[i].latitude, closeTo(originalPoints[i].latitude, 0.0001));
        expect(decoded[i].longitude, closeTo(originalPoints[i].longitude, 0.0001));
      }
    });

    test('backward compatibility with legacy JSON format', () {
      const legacyJson = '[{"lat":13.7563,"lng":100.5018},{"lat":13.7565,"lng":100.5020}]';
      final decoded = RouteUtils.parseRoutePoints(legacyJson);
      expect(decoded.length, equals(2));
      expect(decoded[0].latitude, equals(13.7563));
      expect(decoded[0].longitude, equals(100.5018));
    });

    test('Douglas-Peucker simplifies straight line points', () {
      final points = [
        const LatLng(13.0, 100.0),
        const LatLng(13.00001, 100.00001), // Near collinear
        const LatLng(13.00002, 100.00002), // Near collinear
        const LatLng(13.001, 100.001),
      ];

      final simplified = DouglasPeucker.simplify(points, toleranceMeters: 5.0);
      expect(simplified.length, lessThan(points.length));
      expect(simplified.first, equals(points.first));
      expect(simplified.last, equals(points.last));
    });
  });
}
