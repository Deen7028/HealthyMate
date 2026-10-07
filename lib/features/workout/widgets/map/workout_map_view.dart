import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:healthymate/features/workout/models/workout_models.dart';

/// วิดเจ็ตแผนที่ Google Maps สำหรับแสดงผลตำแหน่งและเส้นทางวิ่ง Real-Time (Workout Map View Widget)
class WorkoutMapView extends StatelessWidget {
  /// รูปแบบแผนที่ (Standard, Satellite, Hybrid)
  final AppMapType mapType;

  /// แสดงการจราจรหรือไม่
  final bool showTraffic;

  /// แสดงจุดสัญลักษณ์ตำแหน่งปัจจุบันของอุปกรณ์หรือไม่
  final bool isGpsEnabled;

  /// รายการพิกัดเส้นทางทั้งหมดเพื่อวาดเป็น Polyline สีส้มบนแผนที่
  final List<LatLng> routePoints;

  /// ตำแหน่งเริ่มต้นของกล้องแผนที่
  final LatLng? initialPosition;

  /// คอลแบ็กเมื่อสร้างแผนที่เสร็จสิ้น
  final void Function(GoogleMapController controller) onMapCreated;

  const WorkoutMapView({
    super.key,
    required this.mapType,
    required this.showTraffic,
    required this.isGpsEnabled,
    required this.routePoints,
    this.initialPosition,
    required this.onMapCreated,
  });

  /// แปลง AppMapType เป็น Google Maps MapType
  MapType _getGoogleMapType(AppMapType type) {
    switch (type) {
      case AppMapType.standard:
        return MapType.normal;
      case AppMapType.satellite:
        return MapType.satellite;
      case AppMapType.hybrid:
        return MapType.hybrid;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: initialPosition ?? const LatLng(13.7563, 100.5018),
        zoom: 16.0,
      ),
      mapType: _getGoogleMapType(mapType),
      trafficEnabled: showTraffic,
      myLocationEnabled: isGpsEnabled,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      compassEnabled: false,
      polylines: routePoints.length >= 2
          ? {
              Polyline(
                polylineId: const PolylineId('live_workout_route'),
                color: const Color(0xFFFC5200),
                width: 5,
                points: routePoints,
              ),
            }
          : {},
      onMapCreated: onMapCreated,
    );
  }
}
