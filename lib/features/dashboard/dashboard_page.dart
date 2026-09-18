import 'package:flutter/material.dart';
import 'package:healthymate/features/health_calculator/state/health_calculator_state.dart';
import 'models/dashboard_data.dart';
import 'widgets/activity_progress_ring.dart';
import 'widgets/daily_routine_checklist.dart';
import 'widgets/key_stats_grid.dart';

class DashboardPage extends StatefulWidget {
  final HealthCalculatorState? state;
  final VoidCallback? onNavigateToCalculator;
  final VoidCallback? onNavigateToPractice;
  final VoidCallback? onNavigateToWorkout;
  final VoidCallback? onStartWorkout;

  const DashboardPage({
    super.key,
    this.state,
    this.onNavigateToCalculator,
    this.onNavigateToPractice,
    this.onNavigateToWorkout,
    this.onStartWorkout,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final DashboardStats _stats = DashboardStats(
    distanceKm: 4.2,
    activeTimeMinutes: 45,
    caloriesBurned: 320,
    stepCount: 6840,
  );

  // Exact checklist items matching design image:
  final List<DailyChecklistItem> _checklistItems = [
    DailyChecklistItem(
      id: 'c1',
      title: 'ยืดเส้นยืดสายยามเช้า',
      subtitle: '10 นาทีเพื่อปลุกร่างกาย',
      icon: Icons.self_improvement_rounded,
      color: const Color(0xFF2E5327),
      isCompleted: true,
    ),
    DailyChecklistItem(
      id: 'c2',
      title: 'ดื่มน้ำ',
      subtitle: 'เริ่มต้นวันด้วยน้ำ 500 มล.',
      icon: Icons.water_drop_rounded,
      color: const Color(0xFF2E5327),
      isCompleted: true,
    ),
    DailyChecklistItem(
      id: 'c3',
      title: 'โปรตีนหลังออกกำลังกาย',
      subtitle: 'เครื่องดื่มหรืออาหารโปรตีนสูง',
      icon: Icons.restaurant_rounded,
      color: const Color(0xFF5A6559),
      isCompleted: false,
    ),
    DailyChecklistItem(
      id: 'c4',
      title: 'เดินเล่นยามเย็น',
      subtitle: 'เดินเบาๆ 15 นาทีหลังอาหารเย็น',
      icon: Icons.directions_walk_rounded,
      color: const Color(0xFF5A6559),
      isCompleted: false,
    ),
    DailyChecklistItem(
      id: 'c5',
      title: 'ทำสมาธิผ่อนคลาย',
      subtitle: '10 นาทีเพื่อผ่อนคลายจิตใจก่อนนอน',
      icon: Icons.spa_rounded,
      color: const Color(0xFF2E5327),
      isCompleted: true,
    ),
  ];

  double get _calculatedProgress {
    if (_checklistItems.isEmpty) return 0.75;
    final completed = _checklistItems.where((i) => i.isCompleted).length;
    return completed / _checklistItems.length;
  }

  void _toggleChecklistItem(String id, bool isChecked) {
    setState(() {
      final index = _checklistItems.indexWhere((i) => i.id == id);
      if (index != -1) {
        _checklistItems[index].isCompleted = isChecked;
      }
    });
  }

  void _handleStartWorkout() {
    if (widget.onNavigateToWorkout != null) {
      widget.onNavigateToWorkout!();
    } else if (widget.onStartWorkout != null) {
      widget.onStartWorkout!();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.directions_run_rounded, color: Colors.white),
              SizedBox(width: 10),
              Text('กำลังเข้าสู่โหมดออกกำลังกาย... 🏋️‍♂️'),
            ],
          ),
          backgroundColor: const Color(0xFF2E5327),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6F2), // Light warm grey-green background matching design
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top App Bar (Profile photo + HealthyMate + Bell icon)
              Padding(
                padding: const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        // User Avatar
                        Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            image: DecorationImage(
                              image: NetworkImage(
                                'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=150&q=80',
                              ),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // App Title
                        const Text(
                          'HealthyMate',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1C2819),
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                    // Notification Bell Icon with Badge
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE2E9E0)),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const Icon(
                            Icons.notifications_none_rounded,
                            color: Color(0xFF2E5327),
                            size: 22,
                          ),
                          Positioned(
                            top: 10,
                            right: 10,
                            child: Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: Color(0xFF2E5327),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Greeting Section (สวัสดีตอนเช้า, Alex)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'สวัสดีตอนเช้า, Alex',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1C2819),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'วันนี้คุณทำได้ดีมาก มาเคลื่อนไหวร่างกายกันต่อเถอะ!',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF677366),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),

              // 3. Daily Activity Progress Ring Card (กิจกรรมประจำวัน 75% + ปุ่มเริ่มออกกำลังกาย)
              DailyActivityCard(
                progress: _calculatedProgress,
                onStartWorkout: _handleStartWorkout,
              ),

              // 4. Key Stats Grid (ระยะทาง 4.2 กม., เวลา 45 นาที, แคลอรี่ 320 กิโลแคลอรี่)
              KeyStatsGrid(
                stats: _stats,
              ),

              // 5. Daily Routine Checklist (กิจวัตรประจำวัน เสร็จสิ้น 3/5)
              DailyRoutineChecklist(
                items: _checklistItems,
                onToggleItem: _toggleChecklistItem,
                onViewAllTap: widget.onNavigateToPractice,
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
