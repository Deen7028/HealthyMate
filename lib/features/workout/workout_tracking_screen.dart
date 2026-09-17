import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:healthymate/features/workout/models/workout_models.dart';
import 'package:healthymate/features/workout/state/workout_tracking_state.dart';
import 'package:healthymate/features/workout/widgets/workout_dialog_utils.dart';
import 'package:healthymate/features/workout/widgets/category_selection_view.dart';
import 'package:healthymate/features/workout/widgets/workout_top_stats_card.dart';
import 'package:healthymate/features/workout/widgets/workout_bottom_controls.dart';
import 'package:healthymate/features/workout/widgets/map_floating_buttons.dart';
import 'package:healthymate/features/workout/widgets/workout_map_view.dart';

/// หน้าจอ Workout Tracking 
/// Logic การคำนวณและ State ทั้งหมดจะถูก Delegate ไปยัง [WorkoutTrackingState]
class WorkoutTrackingScreen extends StatefulWidget {
  final VoidCallback? onBackToDashboard;

  const WorkoutTrackingScreen({super.key, this.onBackToDashboard});

  @override
  State<WorkoutTrackingScreen> createState() => _WorkoutTrackingScreenState();
}

class _WorkoutTrackingScreenState extends State<WorkoutTrackingScreen>
    with SingleTickerProviderStateMixin {
  late final WorkoutTrackingState _state;
  late final AnimationController _pulseController;
  
  // Controller สำหรับควบคุม Google Maps
  GoogleMapController? _mapController;
  LatLng? _currentPosition;

  @override
  void initState() {
    super.initState();
    _state = WorkoutTrackingState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    // ดึงพิกัดตำแหน่งจริงทันทีเมื่อเข้าหน้าจอ
    _initCurrentLocation();
  }

  /// ขอสิทธิ์และดึงตำแหน่ง GPS จริง คืนค่า true ถ้ามีสิทธิ์และ GPS พร้อมใช้งาน
  Future<bool> _initCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // ถ้าผู้ใช้ยังไม่ได้เปิด GPS ในเครื่อง ให้แจ้งเตือนและพาไปเปิด
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('กรุณาเปิดบริการตำแหน่ง (GPS) บนอุปกรณ์'),
              action: SnackBarAction(
                label: 'เปิด GPS',
                textColor: Colors.amberAccent,
                onPressed: () => Geolocator.openLocationSettings(),
              ),
              backgroundColor: const Color(0xFF2E5327),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        await Geolocator.openLocationSettings();
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('คุณปฏิเสธการให้สิทธิ์ตำแหน่ง GPS จึงไม่สามารถเริ่มจับเวลาออกกำลังกายได้'),
                backgroundColor: Colors.redAccent,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('สิทธิ์ตำแหน่งถูกปิดถาวร กรุณาอนุญาตในตั้งค่าแอปก่อนเริ่มออกกำลังกาย'),
              action: SnackBarAction(
                label: 'ไปที่ตั้งค่า',
                textColor: Colors.amberAccent,
                onPressed: () => Geolocator.openAppSettings(),
              ),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return false;
      }

      _state.enableGps();

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      if (mounted) {
        setState(() {
          _currentPosition = LatLng(pos.latitude, pos.longitude);
        });
        _moveToCurrentLocation();
      }
      return true;
    } catch (e) {
      debugPrint('Error getting location: $e');
      return false;
    }
  }

  /// เลื่อนกล้องแผนที่ไปหาตำแหน่งปัจจุบัน
  Future<void> _moveToCurrentLocation() async {
    try {
      Position pos;
      if (_currentPosition != null) {
        pos = Position(
          latitude: _currentPosition!.latitude,
          longitude: _currentPosition!.longitude,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        );
      } else {
        pos = await Geolocator.getCurrentPosition();
        if (mounted) {
          setState(() {
            _currentPosition = LatLng(pos.latitude, pos.longitude);
          });
        }
      }

      _state.enableGps();

      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(pos.latitude, pos.longitude),
            zoom: 16.5,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error moving to location: $e');
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _state.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _handleStartWorkout() async {
    if (!_state.isGpsEnabled) {
      final hasGps = await _initCurrentLocation();
      if (!hasGps) {
        return;
      }
    }
    _state.startWorkout();
  }

  void _handleStopWorkout() {
    _state.pauseWorkout();
    WorkoutDialogUtils.showStopActionSheet(
      context: context,
      timeFormatted: _state.formatTime(_state.secondsElapsed),
      distanceKm: _state.distanceKm,
      caloriesBurned: _state.caloriesBurned,
      onSave: () async {
        final calBurned = _state.caloriesBurned;
        await _state.saveWorkout();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'บันทึกกิจกรรมเรียบร้อย! เผาผลาญ ${calBurned.toStringAsFixed(0)} kcal',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF2E5327),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      },
      onDiscard: () {
        _state.discardWorkout();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.delete_sweep_rounded, color: Colors.white),
                SizedBox(width: 10),
                Text('ละทิ้งกิจกรรมการออกกำลังกายแล้ว'),
              ],
            ),
            backgroundColor: Colors.grey.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      onResume: () => _handleStartWorkout(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _state,
      builder: (context, _) {
        if (_state.status == WorkoutState.selectingCategory) {
          return CategorySelectionView(
            selectedCategory: _state.selectedCategory,
            userId: _state.userId,
            onSelectCategory: (category) => _state.selectCategory(category),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFFEBF2EA),
          body: Stack(
            children: [
              // 1. พื้นหลังแผนที่ Google Maps จริง
              Positioned.fill(
                child: WorkoutMapView(
                  mapType: _state.currentMapType,
                  showTraffic: _state.showTraffic,
                  isGpsEnabled: _state.isGpsEnabled,
                  routePoints: _state.routePoints,
                  initialPosition: _currentPosition,
                  onMapCreated: (controller) {
                    _mapController = controller;
                    if (_currentPosition != null) {
                      _moveToCurrentLocation();
                    }
                  },
                ),
              ),

              // 2. ปุ่มลอยเลือกประเภทแผนที่ (Layers) & ตำแหน่งปัจจุบัน (My Location)
              Positioned(
                right: 20,
                top: 250,
                child: MapFloatingButtons(
                  mapTypeBadgeText:
                      WorkoutDialogUtils.getShortMapName(_state.currentMapType),
                  onLayersTap: () => WorkoutDialogUtils.openMapTypeSelector(
                    context: context,
                    currentType: _state.currentMapType,
                    showTraffic: _state.showTraffic,
                    onSelectType: (type) => _state.setMapType(type),
                    onToggleTraffic: (val) => _state.toggleTraffic(val),
                  ),
                  onMyLocationTap: () async {
                    await _moveToCurrentLocation();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Row(
                            children: [
                              Icon(Icons.gps_fixed_rounded, color: Colors.white, size: 18),
                              SizedBox(width: 8),
                              Text('จัดตำแหน่งปัจจุบันอยู่กึ่งกลางแล้ว'),
                            ],
                          ),
                          backgroundColor: const Color(0xFF2E5327),
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),

              // 3. กล่องแสดงสถิติด้านบน
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: WorkoutTopStatsCard(
                    category: _state.selectedCategory,
                    isRunning: _state.isRunning,
                    mapType: _state.currentMapType,
                    formattedTime: _state.formatTime(_state.secondsElapsed),
                    distanceKm: _state.distanceKm,
                    caloriesBurned: _state.caloriesBurned,
                    pulseAnimation: _pulseController,
                    onChangeCategoryTap: !_state.isRunning
                        ? () => _state.returnToCategorySelection()
                        : null,
                  ),
                ),
              ),

              // 4. แผงควบคุมปุ่มด้านล่าง
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: WorkoutBottomControls(
                  isRunning: _state.isRunning,
                  isPaused: _state.isPaused,
                  canStop: _state.status != WorkoutState.initial,
                  onStartOrResume: _handleStartWorkout,
                  onPause: () => _state.pauseWorkout(),
                  onStop: _handleStopWorkout,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}