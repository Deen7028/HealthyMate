import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:healthymate/features/workout/models/workout_models.dart';
import 'package:healthymate/features/workout/controllers/workout_tracking_controller.dart';
import 'package:healthymate/features/workout/widgets/workout_dialog_utils.dart';
import 'package:healthymate/features/workout/widgets/category_selection_view.dart';
import 'package:healthymate/features/workout/widgets/workout_top_stats_card.dart';
import 'package:healthymate/features/workout/widgets/workout_bottom_controls.dart';
import 'package:healthymate/features/workout/widgets/map_floating_buttons.dart';
import 'package:healthymate/features/workout/widgets/workout_map_view.dart';
import 'package:healthymate/features/workout/widgets/zen_focus_background.dart';

/// หน้าจอ Workout Tracking 
/// Logic การคำนวณและ State ทั้งหมดจะถูก Delegate ไปยัง [WorkoutTrackingController]
class WorkoutTrackingPage extends StatefulWidget {
  final bool isActive;
  final VoidCallback? onBackToDashboard;
  final String? initialCategory;
  final int? targetDurationMinutes;

  const WorkoutTrackingPage({
    super.key,
    this.isActive = true,
    this.onBackToDashboard,
    this.initialCategory,
    this.targetDurationMinutes,
  });

  @override
  State<WorkoutTrackingPage> createState() => _WorkoutTrackingPageState();
}

class _WorkoutTrackingPageState extends State<WorkoutTrackingPage>
    with SingleTickerProviderStateMixin {
  late final WorkoutTrackingController _state;
  late final AnimationController _pulseController;
  
  // Controller สำหรับควบคุม Google Maps
  GoogleMapController? _mapController;
  LatLng? _currentPosition;

  @override
  void initState() {
    super.initState();
    _state = WorkoutTrackingController();
    if (widget.initialCategory != null &&
        widget.initialCategory!.isNotEmpty &&
        widget.initialCategory != 'selectingCategory' &&
        widget.initialCategory != 'all' &&
        widget.initialCategory != 'selection') {
      _state.selectCategoryByName(widget.initialCategory, widget.targetDurationMinutes);
    } else {
      _state.returnToCategorySelection();
    }
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    // ดึงพิกัดตำแหน่งจริงทันทีเมื่อเข้าหน้าจอ
    _initCurrentLocation();
  }

  @override
  void didUpdateWidget(covariant WorkoutTrackingPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialCategory != oldWidget.initialCategory ||
        widget.targetDurationMinutes != oldWidget.targetDurationMinutes ||
        (widget.isActive && !oldWidget.isActive)) {
      if (widget.initialCategory != null &&
          widget.initialCategory!.isNotEmpty &&
          widget.initialCategory != 'selectingCategory' &&
          widget.initialCategory != 'all' &&
          widget.initialCategory != 'selection') {
        _state.selectCategoryByName(widget.initialCategory, widget.targetDurationMinutes);
      } else if (widget.initialCategory == 'selectingCategory' ||
          widget.initialCategory == 'all' ||
          widget.initialCategory == 'selection') {
        _state.returnToCategorySelection();
      }
    }
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

  /// เลื่อนกล้องแผนที่ไปหาตำแหน่งปัจจุบัน (ใช้พิกัดสดใหม่จาก Controller ป้องกันบั๊กปุ่มบินกลับจุดเริ่มต้น)
  Future<void> _moveToCurrentLocation() async {
    try {
      LatLng? targetPos = _state.currentLatLng;
      if (targetPos == null) {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
        );
        targetPos = LatLng(pos.latitude, pos.longitude);
      }

      _state.enableGps();

      if (mounted) {
        setState(() {
          _currentPosition = targetPos;
        });
      }

      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: targetPos,
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
    await _state.ensureUserDataLoaded();
    if (!_state.hasAuthenticatedUser) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('กรุณาเข้าสู่ระบบก่อนบันทึกการออกกำลังกาย')),
        );
      }
      return;
    }
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

        final activePosition = _currentPosition ?? _state.currentLatLng;

        return Scaffold(
          backgroundColor: const Color(0xFFEBF2EA),
          body: Stack(
            children: [
              // 1. พื้นหลัง (สลับระหว่าง แผนที่ GPS กับ Zen Focus Mode สำหรับกิจกรรมไม่เคลื่อนที่)
              Positioned.fill(
                child: _state.selectedCategory.isMoving
                    ? (activePosition != null
                        ? WorkoutMapView(
                            mapType: _state.currentMapType,
                            showTraffic: _state.showTraffic,
                            isGpsEnabled: _state.isGpsEnabled,
                            routePoints: _state.routePoints,
                            initialPosition: activePosition,
                            onMapCreated: (controller) {
                              _mapController = controller;
                              _moveToCurrentLocation();
                            },
                          )
                        : Container(
                            color: const Color(0xFFEBF2EA),
                            child: const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(color: Color(0xFF2E5327)),
                                  SizedBox(height: 16),
                                  Text(
                                    'กำลังค้นหาสัญญาณ GPS ของคุณ...',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF2E5327),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ))
                    : const ZenFocusBackground(),
              ),

              // 2. ปุ่มลอยเลือกประเภทแผนที่ (แสดงเฉพาะกิจกรรมที่มีการเคลื่อนที่)
              if (_state.selectedCategory.isMoving)
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

              // 3. กล่องแสดงสถิติด้านบน (แอนิเมชัน Slide-in เลื่อนลงมาจากด้านบน)
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: -150.0, end: 0.0),
                duration: const Duration(milliseconds: 550),
                curve: Curves.easeOutCubic,
                builder: (context, topOffset, child) {
                  return Positioned(
                    top: topOffset,
                    left: 0,
                    right: 0,
                    child: child!,
                  );
                },
                child: SafeArea(
                  child: ValueListenableBuilder<int>(
                    valueListenable: _state.secondsElapsedNotifier,
                    builder: (context, seconds, _) {
                      return WorkoutTopStatsCard(
                        category: _state.selectedCategory,
                        isRunning: _state.isRunning,
                        mapType: _state.currentMapType,
                        formattedTime: _state.formatTime(seconds),
                        distanceKm: _state.distanceKm,
                        caloriesBurned: _state.caloriesBurned,
                        pulseAnimation: _pulseController,
                        isCountdownMode: _state.isCountdownMode,
                        onChangeCategoryTap: !_state.isRunning
                            ? () => _state.returnToCategorySelection()
                            : null,
                      );
                    },
                  ),
                ),
              ),

              // 4. แผงควบคุมปุ่มด้านล่าง (แอนิเมชัน Slide-in เลื่อนขึ้นมาจากด้านล่าง)
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 150.0, end: 0.0),
                duration: const Duration(milliseconds: 550),
                curve: Curves.easeOutCubic,
                builder: (context, bottomOffset, child) {
                  return Positioned(
                    bottom: bottomOffset,
                    left: 0,
                    right: 0,
                    child: child!,
                  );
                },
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
