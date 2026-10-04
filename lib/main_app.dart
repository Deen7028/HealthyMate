import 'package:flutter/material.dart';
import 'package:healthymate/features/dashboard/pages/dashboard_page.dart';
import 'package:healthymate/features/health_calculator/pages/health_calculator_page.dart';
import 'package:healthymate/features/health_calculator/controllers/health_calculator_controller.dart';
import 'package:healthymate/features/practice/pages/routine_notification_page.dart';
import 'package:healthymate/features/profile/pages/profile_page.dart';
import 'package:healthymate/features/workout/pages/workout_tracking_page.dart';
import 'package:healthymate/shared/bottom_sheets/food_source_bottom_sheet.dart';
import 'package:healthymate/shared/widgets/vitality_bottom_nav_bar.dart';

/// โครงสร้างหลักของแอปพลิเคชัน (Main App Shell / Tab Navigation Shell)
/// ควบคุมการสลับหน้าจอ 5 แท็บหลัก (Dashboard, Workout, Health Calculator, Routine, Profile)
/// พร้อมปุ่มตรงกลางสำหรับสแกนอาหารด้วย AI (Camera Docked FAB)
class MainAppShell extends StatefulWidget {
  const MainAppShell({super.key});

  @override
  State<MainAppShell> createState() => _MainAppShellState();
}

class _MainAppShellState extends State<MainAppShell> {
  /// ดัชนีแท็บปัจจุบันที่เปิดอยู่นี้ (เริ่มต้นแท็บ 0: Dashboard หน้าหลัก)
  int _currentIndex = 0;

  /// คอนโทรลเลอร์คำนวณสถิติสุขภาพ
  final HealthCalculatorController _healthState = HealthCalculatorController();

  @override
  void dispose() {
    _healthState.dispose();
    super.dispose();
  }

  String? _selectedWorkoutCategory;
  int? _selectedWorkoutDurationMinutes;

  void _onTabTapped(int index, [String? category, int? targetDurationMinutes]) {
    setState(() {
      _currentIndex = index;
      _selectedWorkoutCategory = category;
      _selectedWorkoutDurationMinutes = targetDurationMinutes;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          // 0: Dashboard (หน้าหลัก)
          DashboardPageUpdated(
            isActive: _currentIndex == 0,
            onNavigateToCalculator: () => _onTabTapped(2),
            onNavigateToPractice: () => _onTabTapped(3),
            onNavigateToProfile: () => _onTabTapped(4),
            onNavigateToWorkout: (category) => _onTabTapped(1, category),
          ),
          // 1: Workout (ออกกำลังกาย)
          WorkoutTrackingPage(
            isActive: _currentIndex == 1,
            onBackToDashboard: () => _onTabTapped(0),
            initialCategory: _selectedWorkoutCategory,
            targetDurationMinutes: _selectedWorkoutDurationMinutes,
          ),
          // 2: Health Calculator (สุขภาพ)
          HealthCalculatorPage(
            isActive: _currentIndex == 2,
            state: _healthState,
          ),
          // 3: Routine (กิจวัตร)
          MyRoutinesPage(
            isActive: _currentIndex == 3,
            onNavigateToWorkout: (category, [durationMin]) =>
                _onTabTapped(1, category, durationMin),
          ),
          // 4: Profile (โปรไฟล์)
          ProfilePage(
            isActive: _currentIndex == 4,
            onNavigateToPractice: () => _onTabTapped(3),
          ),
        ],
      ),
      // ปุ่มลอยกลาง (Center Docked FAB) ไอคอนกล้องถ่ายรูปสำหรับ AI Food Recognition
      // ซ่อนปุ่มเมื่อคีย์บอร์ดถูกเปิดขึ้นมา เพื่อไม่ให้ปุ่มลอยขึ้นมาทับช่องกรอกข้อมูล
      floatingActionButton: isKeyboardOpen
          ? null
          : _CameraDockedFab(onTap: () => FoodSourceBottomSheet.show(context)),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      // ใช้งาน VitalityBottomNavBar ที่รองรับ Center Notch Cutout
      bottomNavigationBar: VitalityBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        onCameraTap: () => FoodSourceBottomSheet.show(context),
      ),
    );
  }
}

class _CameraDockedFab extends StatefulWidget {
  final VoidCallback onTap;

  const _CameraDockedFab({required this.onTap});

  @override
  State<_CameraDockedFab> createState() => _CameraDockedFabState();
}

class _CameraDockedFabState extends State<_CameraDockedFab> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        Future.microtask(widget.onTap);
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.88 : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutBack,
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF3F824E), Color(0xFF2E6339)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(
                  0xFF2E6339,
                ).withValues(alpha: _isPressed ? 0.20 : 0.38),
                blurRadius: _isPressed ? 6 : 14,
                offset: Offset(0, _isPressed ? 2 : 5),
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.camera_alt_rounded,
              size: 50,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
