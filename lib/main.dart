import 'package:flutter/material.dart';
<<<<<<< HEAD
import 'package:healthymate/core/theme/app_theme.dart';
import 'package:healthymate/main_app.dart';
=======
import 'features/dashboard/dashboard_page.dart';
import 'features/practice/routine_notification_page.dart';
>>>>>>> sal

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HealthyMateApp());
}

class HealthyMateApp extends StatelessWidget {
  const HealthyMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HealthyMate',
      debugShowCheckedModeBanner: false,
<<<<<<< HEAD
      theme: AppTheme.lightTheme,
      home: const MainAppShell(),
=======
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'THSarabunNew',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E5327),
          primary: const Color(0xFF2E5327),
        ),
        scaffoldBackgroundColor: const Color(0xFFF3F6F2),
      ),
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardPage(
        onNavigateToPractice: () {
          setState(() {
            _currentIndex = 3; // Switch to กิจวัตร tab
          });
        },
      ),
      // Placeholder for ออกกำลังกาย (Workout)
      const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.fitness_center_rounded, size: 64, color: Color(0xFF2E5327)),
            SizedBox(height: 12),
            Text('หน้าออกกำลังกาย (Workout)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      // Placeholder for สุขภาพ (Health)
      const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_rounded, size: 64, color: Color(0xFF2E5327)),
            SizedBox(height: 12),
            Text('หน้าข้อมูลสุขภาพ (Health)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      // กิจวัตร & เตือน (Routine & Notifications)
      const RoutineNotificationPage(),
      // Placeholder for โปรไฟล์ (Profile)
      const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_rounded, size: 64, color: Color(0xFF2E5327)),
            SizedBox(height: 12),
            Text('หน้าโปรไฟล์ผู้ใช้ (Profile)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: Colors.white,
          elevation: 0,
          indicatorColor: const Color(0xFF90C289), // Soft green active pill indicator from design image
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.grid_view_outlined, color: Color(0xFF5A6559)),
              selectedIcon: Icon(Icons.grid_view_rounded, color: Color(0xFF1C2819)),
              label: 'หน้าหลัก',
            ),
            NavigationDestination(
              icon: Icon(Icons.fitness_center_outlined, color: Color(0xFF5A6559)),
              selectedIcon: Icon(Icons.fitness_center_rounded, color: Color(0xFF1C2819)),
              label: 'ออกกำลังกาย',
            ),
            NavigationDestination(
              icon: Icon(Icons.medical_services_outlined, color: Color(0xFF5A6559)),
              selectedIcon: Icon(Icons.medical_services_rounded, color: Color(0xFF1C2819)),
              label: 'สุขภาพ',
            ),
            NavigationDestination(
              icon: Icon(Icons.calendar_today_outlined, color: Color(0xFF5A6559)),
              selectedIcon: Icon(Icons.calendar_today_rounded, color: Color(0xFF1C2819)),
              label: 'กิจวัตร',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded, color: Color(0xFF5A6559)),
              selectedIcon: Icon(Icons.person_rounded, color: Color(0xFF1C2819)),
              label: 'โปรไฟล์',
            ),
          ],
        ),
      ),
>>>>>>> sal
    );
  }
}
