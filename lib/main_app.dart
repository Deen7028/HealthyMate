import 'package:flutter/material.dart';
import 'package:healthymate/features/dashboard/dashboard_page.dart';
import 'package:healthymate/features/health_calculator/screens/health_calculator_screen.dart';
import 'package:healthymate/features/health_calculator/state/health_calculator_state.dart';
import 'package:healthymate/features/practice/routine_notification_page.dart';
import 'package:healthymate/features/profile/profile_screen.dart';
import 'package:healthymate/features/workout/workout_tracking_screen.dart';
import 'package:healthymate/features/food_recognition/dialogs/food_source_bottom_sheet.dart';
import 'package:healthymate/shared/widgets/vitality_bottom_nav_bar.dart';

class MainAppShell extends StatefulWidget {
  const MainAppShell({super.key});

  @override
  State<MainAppShell> createState() => _MainAppShellState();
}

class _MainAppShellState extends State<MainAppShell> {
  int _currentIndex = 0; // Default to Dashboard (หน้าหลัก, index 0)
  final HealthCalculatorState _healthState = HealthCalculatorState();

  @override
  void dispose() {
    _healthState.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
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
            onNavigateToWorkout: () => _onTabTapped(1),
          ),
          // 1: Workout (ออกกำลังกาย)
          WorkoutTrackingScreen(
            onBackToDashboard: () => _onTabTapped(0),
          ),
          // 2: Health Calculator (สุขภาพ)
          HealthCalculatorScreen(state: _healthState),
          // 3: Routine (กิจวัตร)
          MyRoutinesPage(
            isActive: _currentIndex == 3,
          ),
          // 4: Profile (โปรไฟล์)
          const ProfileScreen(),
        ],
      ),
      // ปุ่มลอยกลาง (Center Docked FAB) ไอคอนกล้องถ่ายรูปสำหรับ AI Food Recognition
      // ซ่อนปุ่มเมื่อคีย์บอร์ดถูกเปิดขึ้นมา เพื่อไม่ให้ปุ่มลอยขึ้นมาทับช่องกรอกข้อมูล
      floatingActionButton: isKeyboardOpen
          ? null
          : _CameraDockedFab(
              onTap: () => FoodSourceBottomSheet.show(context),
            ),
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
        widget.onTap();
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
                color: const Color(0xFF2E6339).withValues(alpha: _isPressed ? 0.20 : 0.38),
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

