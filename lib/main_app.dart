import 'package:flutter/material.dart';
import 'package:healthymate/features/dashboard/dashboard_page.dart';
import 'package:healthymate/features/health_calculator/screens/health_calculator_screen.dart';
import 'package:healthymate/features/health_calculator/state/health_calculator_state.dart';
import 'package:healthymate/features/practice/routine_notification_page.dart';
import 'package:healthymate/features/profile/profile_screen.dart';
import 'package:healthymate/features/workout/workout_tracking_screen.dart';
import 'package:healthymate/shared/widgets/vitality_bottom_nav_bar.dart';

class MainAppShell extends StatefulWidget {
  const MainAppShell({super.key});

  @override
  State<MainAppShell> createState() => _MainAppShellState();
}

class _MainAppShellState extends State<MainAppShell> {
  int _currentIndex =
      2; // Default to Health Calculator tab (index 2) as in prototype
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
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          // 0: Dashboard (หน้าหลัก)
          DashboardPage(
            state: _healthState,
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
          const RoutineNotificationPage(),
          // 4: Profile (โปรไฟล์)
          const ProfileScreen(),
        ],
      ),
      // ใช้งาน VitalityBottomNavBar ที่แยกออกมาเป็นคอมโพเนนต์อิสระ
      bottomNavigationBar: VitalityBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}
