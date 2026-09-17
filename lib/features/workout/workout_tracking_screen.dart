import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:healthymate/features/workout/models/workout_models.dart';
import 'package:healthymate/features/workout/state/workout_tracking_state.dart';
import 'package:healthymate/features/workout/widgets/workout_dialog_utils.dart';

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

  /// ขอสิทธิ์และดึงตำแหน่ง GPS จริง
  Future<void> _initCurrentLocation() async {
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
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('คุณปฏิเสธการให้สิทธิ์ตำแหน่ง GPS'),
                backgroundColor: Colors.redAccent,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('สิทธิ์ตำแหน่งถูกปิดถาวร กรุณาอนุญาตในตั้งค่าแอป'),
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
        return;
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
    } catch (e) {
      debugPrint('Error getting location: $e');
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
      await _initCurrentLocation();
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
      onResume: () => _state.resumeWorkout(),
    );
  }

  /// ฟังก์ชันแปลงประเภทแผนที่ของแอป ให้ตรงกับ Google Maps API
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
    return ListenableBuilder(
      listenable: _state,
      builder: (context, _) {
        if (_state.status == WorkoutState.selectingCategory) {
          return _buildCategorySelectionScreen();
        }

        return Scaffold(
          backgroundColor: const Color(0xFFEBF2EA),
          body: Stack(
            children: [
              // 1. พื้นหลังแผนที่ Google Maps จริง
              Positioned.fill(
                child: _buildMapBackground(),
              ),

              // 2. ปุ่มลอยเลือกประเภทแผนที่ (Layers) & ตำแหน่งปัจจุบัน (My Location)
              Positioned(
                right: 20,
                top: 250,
                child: Column(
                  children: [
                    _buildMapFloatingButton(
                      icon: Icons.layers_rounded,
                      badgeText: WorkoutDialogUtils.getShortMapName(_state.currentMapType),
                      onTap: () => WorkoutDialogUtils.openMapTypeSelector(
                        context: context,
                        currentType: _state.currentMapType,
                        showTraffic: _state.showTraffic,
                        onSelectType: (type) => _state.setMapType(type),
                        onToggleTraffic: (val) => _state.toggleTraffic(val),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildMapFloatingButton(
                      icon: Icons.my_location_rounded,
                      onTap: () async {
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
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),

              // 3. กล่องแสดงสถิติด้านบน
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                    child: _buildTopStatsCard(),
                  ),
                ),
              ),

              // 4. แผงควบคุมปุ่มด้านล่าง
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildBottomControls(),
              ),
            ],
          ),
        );
      },
    );
  }

  /// หน้าจอเลือกหมวดหมู่การออกกำลังกาย
  Widget _buildCategorySelectionScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6F2),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              const Text(
                'เลือกหมวดหมู่การออกกำลังกาย',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1C2819),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'เลือกประเภทกิจกรรมก่อนเริ่มตรวจวัดและคำนวณแคลอรี',
                style: TextStyle(fontSize: 13.5, color: Color(0xFF677366)),
              ),
              const SizedBox(height: 24),

              ...WorkoutCategory.categories.map((category) {
                final isSelected = _state.selectedCategory.id == category.id;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: InkWell(
                    onTap: () => _state.selectCategory(category),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF2E5327) : const Color(0xFFE2E9E0),
                          width: isSelected ? 2 : 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F3EB),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(category.icon, color: const Color(0xFF2E5327), size: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  category.title,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1C2819),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  category.subtitle,
                                  style: const TextStyle(fontSize: 12.5, color: Color(0xFF677366)),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Color(0xFF8B9889)),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopStatsCard() {
    // ปรับเงื่อนไขสี Dark Mode ให้เข้ากับ Hybrid และ Satellite
    final isDarkModeMap = _state.currentMapType == AppMapType.hybrid || _state.currentMapType == AppMapType.satellite;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: isDarkModeMap
            ? const Color(0xFF1E281F).withValues(alpha: 0.95)
            : const Color(0xFFF7FAF7).withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: isDarkModeMap ? Colors.white24 : Colors.white, width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: !_state.isRunning ? () => _state.returnToCategorySelection() : null,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  decoration: BoxDecoration(
                    color: isDarkModeMap
                        ? const Color(0xFF74B46E).withValues(alpha: 0.25)
                        : const Color(0xFF2E5327).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _state.selectedCategory.icon,
                        size: 16,
                        color: isDarkModeMap ? const Color(0xFF90DB89) : const Color(0xFF2E5327),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        _state.selectedCategory.title,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: isDarkModeMap ? const Color(0xFF90DB89) : const Color(0xFF2E5327),
                        ),
                      ),
                      if (!_state.isRunning) ...[
                        const SizedBox(width: 2),
                        Icon(
                          Icons.swap_horiz_rounded,
                          size: 16,
                          color: isDarkModeMap ? const Color(0xFF90DB89) : const Color(0xFF2E5327),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (_state.isRunning)
                FadeTransition(
                  opacity: _pulseController,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: const [
                        CircleAvatar(radius: 4, backgroundColor: Colors.redAccent),
                        SizedBox(width: 6),
                        Text(
                          'กำลังบันทึก',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.redAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            'เวลา',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDarkModeMap ? const Color(0xFFA0ACA0) : const Color(0xFF5A665A),
              letterSpacing: 0.2,
            ),
          ),

          Text(
            _state.formatTime(_state.secondsElapsed),
            style: TextStyle(
              fontSize: 38,
              fontWeight: FontWeight.w900,
              color: isDarkModeMap ? Colors.white : const Color(0xFF1E281F),
              letterSpacing: -1,
            ),
          ),

          Divider(height: 1, color: isDarkModeMap ? Colors.white12 : const Color(0xFFE4ECE2)),

          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'ระยะทาง',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDarkModeMap ? const Color(0xFFA0ACA0) : const Color(0xFF677366),
                      ),
                    ),
                    RichText(
                      text: TextSpan(
                        text: _state.distanceKm.toStringAsFixed(2),
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: isDarkModeMap ? const Color(0xFF90DB89) : const Color(0xFF2E5327),
                          letterSpacing: -0.5,
                        ),
                        children: [
                          TextSpan(
                            text: ' km',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDarkModeMap ? const Color(0xFFA0ACA0) : const Color(0xFF5A665A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                height: 36,
                width: 1,
                color: isDarkModeMap ? Colors.white12 : const Color(0xFFE4ECE2),
              ),

              Expanded(
                child: Column(
                  children: [
                    Text(
                      'แคลอรี',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDarkModeMap ? const Color(0xFFA0ACA0) : const Color(0xFF677366),
                      ),
                    ),
                    RichText(
                      text: TextSpan(
                        text: _state.caloriesBurned.toStringAsFixed(0),
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: isDarkModeMap ? Colors.white : const Color(0xFF1E281F),
                          letterSpacing: -0.5,
                        ),
                        children: [
                          TextSpan(
                            text: ' kcal',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDarkModeMap ? const Color(0xFFA0ACA0) : const Color(0xFF5A665A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// เปลี่ยนไปใช้วิดเจต GoogleMap แทน CustomPainter
  Widget _buildMapBackground() {
    return GoogleMap(
      initialCameraPosition: const CameraPosition(
        target: LatLng(13.7563, 100.5018), // พิกัดเริ่มต้น
        zoom: 15.0,
      ),
      mapType: _getGoogleMapType(_state.currentMapType),
      trafficEnabled: _state.showTraffic,
      myLocationEnabled: _state.isGpsEnabled, // จะแสดงหมุดสีฟ้าเมื่อเปิด GPS และให้สิทธิ์แล้ว
      myLocationButtonEnabled: false, // ปิดปุ่ม Default ของ Google Maps เพื่อใช้ปุ่ม UI ของเราเอง
      zoomControlsEnabled: false, // ปิดปุ่ม Zoom (+/-) เพื่อให้ UI สะอาดตา
      compassEnabled: false,
      onMapCreated: (GoogleMapController controller) {
        _mapController = controller;
        if (_currentPosition != null) {
          _moveToCurrentLocation();
        }
      },
    );
  }

  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.only(left: 28, right: 28, top: 22, bottom: 30),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAF8).withValues(alpha: 0.97),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
        border: Border.all(color: Colors.white, width: 1.2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildActionButton(
            label: 'หยุด',
            icon: Icons.stop_rounded,
            color: const Color(0xFFFEE6E6),
            iconColor: const Color(0xFFD32F2F),
            size: 58,
            iconSize: 28,
            enabled: _state.status != WorkoutState.initial,
            onTap: _state.status != WorkoutState.initial ? _handleStopWorkout : null,
          ),
          _buildMainCenterButton(),
          _buildActionButton(
            label: 'ชั่วคราว',
            icon: Icons.pause_rounded,
            color: const Color(0xFFEAEFEA),
            iconColor: const Color(0xFF5A665A),
            size: 58,
            iconSize: 28,
            enabled: _state.isRunning,
            onTap: _state.isRunning ? () => _state.pauseWorkout() : null,
          ),
        ],
      ),
    );
  }

  Widget _buildMainCenterButton() {
    final bool isRunning = _state.isRunning;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () {
            if (isRunning) {
              _state.pauseWorkout();
            } else if (_state.isPaused) {
              _state.resumeWorkout();
            } else {
              _handleStartWorkout();
            }
          },
          child: Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF2E5327),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2E5327).withValues(alpha: 0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(
              isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: Colors.white,
              size: 44,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          isRunning ? 'พักชั่วคราว' : (_state.isPaused ? 'ทำต่อ' : 'เริ่ม'),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: Color(0xFF2E5327),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required Color iconColor,
    required double size,
    required double iconSize,
    required bool enabled,
    VoidCallback? onTap,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: enabled ? onTap : null,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: enabled ? 1.0 : 0.4,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                boxShadow: enabled
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Icon(icon, color: iconColor, size: iconSize),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: enabled ? const Color(0xFF5A665A) : const Color(0xFFA0ACA0),
          ),
        ),
      ],
    );
  }

  Widget _buildMapFloatingButton({
    required IconData icon,
    String? badgeText,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Icon(icon, color: const Color(0xFF2E5327), size: 24),
            if (badgeText != null)
              Positioned(
                top: -18,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E5327),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badgeText,
                    style: const TextStyle(fontSize: 9.5, color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}