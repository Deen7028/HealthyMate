import 'dart:math' as math;
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Kalman Filter สำหรับกรองสัญญาณ GPS Noise และกำจัดอาการพิกัดกระโดด (GPS Drift & Jitter)
/// คำนวณด้วย State Estimation และ Covariance ตามระดับความแม่นยำ (Accuracy) ของ GPS
class KalmanLocationFilter {
  /// Process Noise ในหน่วย m/s (อัตราการเปลี่ยนแปลงความเร็วสูงสุดที่เป็นไปได้)
  /// สำหรับเดิน ~ 1.5, วิ่ง ~ 3.0, ปั่นจักรยาน ~ 8.0
  final double qMetersPerSecond;

  double? _lat;
  double? _lng;
  double _variance = -1.0;
  int _lastTimestampMs = 0;
  int _consecutiveOutliers = 0;

  KalmanLocationFilter({this.qMetersPerSecond = 3.0});

  bool get isInitialized => _variance >= 0 && _lat != null && _lng != null;
  LatLng? get currentEstimate =>
      isInitialized ? LatLng(_lat!, _lng!) : null;

  /// รีเซ็ตค่าการประมาณตำแหน่ง (ใช้เมื่อเริ่มกิจกรรมใหม่ หรือหลังจากหยุดพักเป็นเวลานาน)
  void reset() {
    _lat = null;
    _lng = null;
    _variance = -1.0;
    _lastTimestampMs = 0;
    _consecutiveOutliers = 0;
  }

  /// นำเข้าค่าพิกัด GPS ดิบ และคืนค่าพิกัดที่ผ่านการ Smooth ด้วย Kalman Filter
  /// [accuracyMeters]: ความแม่นยำของพิกัดจาก GPS (Geolocator accuracy)
  /// [timestampMs]: มิลลิวินาทีของจุดพิกัด
  LatLng process({
    required double lat,
    required double lng,
    required double accuracyMeters,
    required int timestampMs,
  }) {
    // ป้องกันค่า accuracy ติดลบหรือน้อยผิดปกติ
    final effectiveAccuracy = accuracyMeters < 1.0 ? 1.0 : accuracyMeters;

    // หากเป็นพิกัดแรก กำหนดค่าเริ่มต้น
    if (_variance < 0 || _lat == null || _lng == null) {
      _lat = lat;
      _lng = lng;
      _variance = effectiveAccuracy * effectiveAccuracy;
      _lastTimestampMs = timestampMs;
      _consecutiveOutliers = 0;
      return LatLng(_lat!, _lng!);
    }

    final durationSec = (timestampMs - _lastTimestampMs) / 1000.0;
    if (durationSec <= 0) {
      return LatLng(_lat!, _lng!);
    }

    // 1. Time Update (Prediction Step): เพิ่ม Variance ตามระยะเวลาและความเร็วของกิจกรรม
    _variance += durationSec * qMetersPerSecond * qMetersPerSecond;
    _lastTimestampMs = timestampMs;

    // 2. Outlier / Jump Detection: หากพิกัดใหม่กระโดดไกลเกินความเป็นไปได้ทางกายภาพ
    final double distFromEstimate = _distanceBetweenMeters(_lat!, _lng!, lat, lng);
    final double maxExpectedDisplacement = (durationSec * 25.0) + (effectiveAccuracy * 2.0); // max 90 km/h + accuracy margin

    if (distFromEstimate > maxExpectedDisplacement && _consecutiveOutliers < 3) {
      // ตรวจพบจุดกระโดดผิดปกติ (GPS Drift / Teleportation) ข้ามจุดนี้ไปชั่วคราว
      _consecutiveOutliers++;
      return LatLng(_lat!, _lng!);
    }
    _consecutiveOutliers = 0;

    // 3. Measurement Update (Correction Step):
    // คำนวณ Kalman Gain K = P / (P + R)
    final measurementVariance = effectiveAccuracy * effectiveAccuracy;
    final kalmanGain = _variance / (_variance + measurementVariance);

    // ปรับค่าพิกัดประมาณการ (State Estimate Update)
    _lat = _lat! + kalmanGain * (lat - _lat!);
    _lng = _lng! + kalmanGain * (lng - _lng!);

    // ปรับค่าความแปรปรวน (Covariance Update)
    _variance = (1.0 - kalmanGain) * _variance;

    return LatLng(_lat!, _lng!);
  }

  /// คำนวณระยะทาง Haversine ระหว่าง 2 พิกัดในหน่วยเมตร
  double _distanceBetweenMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371000.0; // เมตร
    final double dLat = _degToRad(lat2 - lat1);
    final double dLon = _degToRad(lon2 - lon1);

    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(lat1)) *
            math.cos(_degToRad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _degToRad(double deg) => deg * (math.pi / 180.0);
}
