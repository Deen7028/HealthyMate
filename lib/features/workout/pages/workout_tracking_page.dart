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
part 'workout_tracking_page_location.dart';
part 'workout_tracking_page_actions.dart';
part 'workout_tracking_page_content.dart';

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
      _state.selectCategoryByName(
        widget.initialCategory,
        widget.targetDurationMinutes,
      );
    } else {
      _state.returnToCategorySelection();
    }
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    // ดึงพิกัดตำแหน่งจริงทันทีเมื่อเข้าหน้าจอ
    this._initCurrentLocation();
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
        _state.selectCategoryByName(
          widget.initialCategory,
          widget.targetDurationMinutes,
        );
      } else if (widget.initialCategory == 'selectingCategory' ||
          widget.initialCategory == 'all' ||
          widget.initialCategory == 'selection') {
        _state.returnToCategorySelection();
      }
    }
  }

  /// ขอสิทธิ์และดึงตำแหน่ง GPS จริง คืนค่า true ถ้ามีสิทธิ์และ GPS พร้อมใช้งาน
  @override
  void dispose() {
    _pulseController.dispose();
    _state.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  @override
  Widget build(BuildContext context) => this._buildWorkoutPage(context);
}
