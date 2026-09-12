import 'package:flutter/material.dart';
import 'package:healthymate/core/theme/app_theme.dart';
import 'package:healthymate/features/dashboard/screens/dashboard_screen.dart';
import 'package:healthymate/features/health_calculator/screens/health_calculator_screen.dart';
import 'package:healthymate/features/health_calculator/state/health_calculator_state.dart';
import 'package:healthymate/shared/widgets/vitality_bottom_nav_bar.dart';

class MainAppShell extends StatefulWidget {
  const MainAppShell({super.key});

  @override
  State<MainAppShell> createState() => _MainAppShellState();
}

class _MainAppShellState extends State<MainAppShell> {
  int _currentIndex = 2; // Default to Health Calculator tab (index 2) as in prototype
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

  Widget _buildPlaceholderTab(String title, IconData icon) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppTheme.primaryGreenLight,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: AppTheme.primaryGreen),
            ),
            const SizedBox(height: 16),
            Text(
              'หน้า $title',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'กำลังพัฒนาฟังก์ชันเพิ่มเติมเร็วๆ นี้',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
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
          DashboardScreen(
            state: _healthState,
            onNavigateToCalculator: () => _onTabTapped(2),
          ),
          // 1: Workout (ออกกำลังกาย)
          _buildPlaceholderTab('ออกกำลังกาย', Icons.fitness_center_rounded),
          // 2: Health Calculator (สุขภาพ)
          HealthCalculatorScreen(state: _healthState),
          // 3: Routine (กิจวัตร)
          _buildPlaceholderTab('กิจวัตรประจำวัน', Icons.calendar_month_outlined),
          // 4: Profile (โปรไฟล์)
          _buildPlaceholderTab('โปรไฟล์ส่วนตัว', Icons.person_outline_rounded),
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
