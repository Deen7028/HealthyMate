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
import 'package:healthymate/features/workout/services/workout_recovery_service.dart';

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

    // 4. Auto-Recovery: ตรวจสอบว่ามีกิจกรรมที่ค้างอยู่จากการแอปปิด/หลุดหรือไม่
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkInterruptedWorkout();
    });
  }

  @override
  void didUpdateWidget(covariant WorkoutTrackingPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // ป้องกันการรีเซ็ตสถานะขณะออกกำลังกาย หรือขณะหยุดพักชั่วคราว
    if (_state.isRunning || _state.isPaused) {
      return;
    }

    if (widget.initialCategory != oldWidget.initialCategory ||
        widget.targetDurationMinutes != oldWidget.targetDurationMinutes ||
        (widget.isActive && !oldWidget.isActive)) {
      if (widget.initialCategory != null &&
          widget.initialCategory!.isNotEmpty &&
          widget.initialCategory != 'selectingCategory' &&
          widget.initialCategory != 'all' &&
          widget.initialCategory != 'selection') {
        // อัปเดตเฉพาะเมื่อหมวดหมู่ต่างจากปัจจุบัน
        if (_state.selectedCategory.id != widget.initialCategory &&
            _state.selectedCategory.title != widget.initialCategory) {
          _state.selectCategoryByName(
            widget.initialCategory,
            widget.targetDurationMinutes,
          );
        } else if (widget.targetDurationMinutes != oldWidget.targetDurationMinutes) {
          _state.setTargetDurationMinutes(widget.targetDurationMinutes);
        }
      } else if (widget.initialCategory == 'selectingCategory' ||
          widget.initialCategory == 'all' ||
          widget.initialCategory == 'selection') {
        if (_state.status != WorkoutState.selectingCategory) {
          _state.returnToCategorySelection();
        }
      }
    }
  }

  /// 4. Auto-Recovery: ตรวจสอบและแสดง Dialog ให้กู้คืนกิจกรรมที่ค้างอยู่จากการแอปปิด/ดับ
  Future<void> _checkInterruptedWorkout() async {
    try {
      // ดึงข้อมูล Checkpoint การออกกำลังกายล่าสุดของผู้ใช้
      final checkpoint = await _state.checkForInterruptedWorkout();
      if (checkpoint != null && mounted) {
        // แสดงป๊อบอัพถามผู้ใช้ว่าต้องการกู้คืนข้อมูลกิจกรรมก่อนหน้าหรือไม่
        final shouldRestore = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.history_toggle_off_rounded, color: Colors.orange),
                SizedBox(width: 8),
                Text('พบกิจกรรมที่ค้างอยู่', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            content: Text(
              'ตรวจพบการออกกำลังกายที่บันทึกค้างไว้เมื่อ ${checkpoint.checkpointTime.hour.toString().padLeft(2, '0')}:${checkpoint.checkpointTime.minute.toString().padLeft(2, '0')} น.\n'
              'ระยะทาง: ${checkpoint.distanceKm.toStringAsFixed(2)} กม. (${checkpoint.secondsElapsed ~/ 60} นาที)\n\n'
              'คุณต้องการกู้คืนเพื่อออกกำลังกายต่อหรือไม่?',
            ),
            actions: [
              // ปุ่มละทิ้งกิจกรรมที่ค้างอยู่
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('ละทิ้ง', style: TextStyle(color: Colors.red)),
              ),
              // ปุ่มตกลงกู้คืนกิจกรรม
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('กู้คืนกิจกรรม', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );

        // หากผู้ใช้เลือกกู้คืน ให้โหลด State กลับมาและเลื่อนกล้องแผนที่ไปยังพิกัดล่าสุด
        if (shouldRestore == true && mounted) {
          _state.restoreFromCheckpoint(checkpoint);
          if (_state.routePoints.isNotEmpty && _mapController != null) {
            _mapController?.animateCamera(
              CameraUpdate.newLatLngZoom(_state.routePoints.last, 17),
            );
          }
        } else {
          // หากผู้ใช้เลือกล้าง ให้ลบ Checkpoint ออกจากเครื่อง
          await WorkoutRecoveryService.instance.clearCheckpoint();
        }
      }
    } catch (e) {
      debugPrint('Error checking interrupted workout: $e');
    }
  }

  /// คืนทรัพยากร Animation, Controller และ Map Controller เมื่อออกจากหน้าจอ
  @override
  void dispose() {
    _pulseController.dispose();
    _state.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => this._buildWorkoutPage(context);
}
