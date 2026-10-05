// ส่วนนี้อธิบายบทบาทของไฟล์: หน้าจอหลัก ในฟีเจอร์การติดตามและประวัติการออกกำลังกาย (workout tracking page content)
// คอมเมนท์ภาษาไทยถูกใส่ไว้เป็นส่วนๆ เพื่อช่วยไล่ flow โดยไม่เปลี่ยนพฤติกรรมเดิมของโค้ด

part of 'workout_tracking_page.dart';

/// ส่วนขยายจัดการสร้างโครงสร้าง UI หน้าจอออกกำลังกาย (Workout UI Layout Builder)
extension WorkoutTrackingPageContent on _WorkoutTrackingPageState {
  /// สร้างตามสถานะปัจจุบัน (_state.status)
  Widget _buildWorkoutPage(BuildContext context) {
    return ListenableBuilder(
      listenable: _state,
      builder: (context, _) {
        // 1. หน้าจอเลือกหมวดหมู่กิจกรรม (Category Selection View)
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
              // 1. พื้นหลัง (สลับระหว่าง แผนที่ GPS กับ Zen Focus Mode สำหรับกิจกรรมไม่อยู่กับที่)
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
                                this._moveToCurrentLocation();
                              },
                            )
                          : Container(
                              color: const Color(0xFFEBF2EA),
                              child: const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CircularProgressIndicator(
                                      color: Color(0xFF2E5327),
                                    ),
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
                    mapTypeBadgeText: WorkoutMapTypeSelector.getShortMapName(
                      _state.currentMapType,
                    ),
                    onLayersTap: () =>
                        WorkoutMapTypeSelector.openMapTypeSelector(
                          context: context,
                          currentType: _state.currentMapType,
                          showTraffic: _state.showTraffic,
                          onSelectType: (type) => _state.setMapType(type),
                          onToggleTraffic: (val) => _state.toggleTraffic(val),
                        ),
                    onMyLocationTap: () async {
                      await this._moveToCurrentLocation();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Row(
                              children: [
                                Icon(
                                  Icons.gps_fixed_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
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
                  onStartOrResume: this._handleStartWorkout,
                  onPause: () => _state.pauseWorkout(),
                  onStop: this._handleStopWorkout,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
