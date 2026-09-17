import 'package:flutter/material.dart';
import 'package:healthymate/core/theme/app_theme.dart';
import 'package:healthymate/features/dashboard/dashboard_page.dart';
import 'package:healthymate/features/health_calculator/screens/health_calculator_screen.dart';
import 'package:healthymate/features/health_calculator/state/health_calculator_state.dart';
import 'package:healthymate/features/practice/routine_notification_page.dart';
import 'package:healthymate/features/workout/workout_tracking_screen.dart';
import 'package:healthymate/core/services/auth_service.dart';
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

  Widget _buildProfileTab() {
    return Scaffold(
      appBar: AppBar(title: const Text('โปรไฟล์ส่วนตัว'), centerTitle: false),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Center(
              child: CircleAvatar(
                radius: 44,
                backgroundColor: AppTheme.primaryGreenLight,
                child: Icon(
                  Icons.person_rounded,
                  size: 52,
                  color: AppTheme.primaryGreen,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                AuthService.instance.currentUserEmail.isNotEmpty
                    ? AuthService.instance.currentUserEmail
                    : 'ผู้ใช้งาน HealthyMate',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 6),
            const Center(
              child: Text(
                'สถานะ: เข้าสู่ระบบแล้ว',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.primaryGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 36),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await AuthService.instance.logout();
                },
                icon: const Icon(Icons.logout_rounded, color: Colors.white),
                label: const Text(
                  'ออกจากระบบ',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD93838),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
          _buildProfileTab(),
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
