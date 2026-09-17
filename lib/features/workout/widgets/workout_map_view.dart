import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:healthymate/features/workout/models/workout_models.dart';

class WorkoutMapView extends StatelessWidget {
  final AppMapType mapType;
  final bool showTraffic;
  final bool isGpsEnabled;
  final List<LatLng> routePoints;
  final LatLng? initialPosition;
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
