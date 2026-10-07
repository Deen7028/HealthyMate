import 'package:flutter_test/flutter_test.dart';
import 'package:healthymate/features/workout/services/kalman_location_filter.dart';

void main() {
  group('KalmanLocationFilter Tests', () {
    test('filters jitter and smooths location', () {
      final filter = KalmanLocationFilter(qMetersPerSecond: 3.0);

      // จุดเริ่มต้น
      final p1 = filter.process(
        lat: 13.7563,
        lng: 100.5018,
        accuracyMeters: 5.0,
        timestampMs: 1000,
      );
      expect(p1.latitude, equals(13.7563));
      expect(p1.longitude, equals(100.5018));

      // จุดที่สองที่มี GPS noise กระโดดเล็กน้อย (accuracy 20.0m ต่ำลง)
      final p2 = filter.process(
        lat: 13.75635,
        lng: 100.50185,
        accuracyMeters: 20.0,
        timestampMs: 2000,
      );
      // พิกัดควรถูกถ่วงน้ำหนักเข้าหา p1 ไม่ให้กระโดดไปตาม noise ทั้งหมด
      expect(p2.latitude, lessThan(13.75635));
      expect(p2.latitude, greaterThan(13.75630));
    });

    test('rejects sudden teleports/outliers', () {
      final filter = KalmanLocationFilter(qMetersPerSecond: 3.0);

      filter.process(
        lat: 13.7563,
        lng: 100.5018,
        accuracyMeters: 5.0,
        timestampMs: 1000,
      );

      // กระโดดไป 1 กิโลเมตรภายใน 1 วินาที (เป็นไปไม่ได้สำหรับการวิ่ง)
      final pOutlier = filter.process(
        lat: 13.7663,
        lng: 100.5118,
        accuracyMeters: 10.0,
        timestampMs: 2000,
      );

      // ค่าประมาณยังคงรักษาตำแหน่งเดิมไว้ ไม่กระโดดตาม outlier
      expect(pOutlier.latitude, closeTo(13.7563, 0.001));
    });
  });
}
