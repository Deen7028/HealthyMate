import 'package:flutter/material.dart';
import 'models/routine_item.dart';
import 'widgets/add_routine_dialog.dart';
import 'widgets/routine_card.dart';

class RoutineNotificationPage extends StatefulWidget {
  const RoutineNotificationPage({super.key});

  @override
  State<RoutineNotificationPage> createState() => _RoutineNotificationPageState();
}

class _RoutineNotificationPageState extends State<RoutineNotificationPage> {
  // Items matching the exact design image:
  // 1. ดื่มน้ำ (ทุก 2 ชั่วโมง - ON)
  // 2. เดิน 10,000 ก้าว (เป้าหมายรายวัน - ON)
  // 3. ทำสมาธิตอนเช้า (07:00 AM - OFF)
  // 4. บันทึกมื้อเที่ยง (13:00 PM - ON)
  final List<RoutineItem> _routines = [
    RoutineItem(
      id: 'r_water',
      title: 'ดื่มน้ำ',
      category: RoutineCategory.water,
      iconData: Icons.water_drop_rounded,
      color: const Color(0xFF2E5327),
      targetValue: 2000,
      currentValue: 1200,
      unit: 'มล.',
      isNotificationEnabled: true,
      notificationTime: 'ทุก 2 ชั่วโมง',
      repeatDays: ['จ.', 'อ.', 'พ.', 'พฤ.', 'ศ.', 'ส.', 'อา.'],
    ),
    RoutineItem(
      id: 'r_steps',
      title: 'เดิน 10,000 ก้าว',
      category: RoutineCategory.fitness,
      iconData: Icons.directions_walk_rounded,
      color: const Color(0xFF2E5327),
      targetValue: 10000,
      currentValue: 6800,
      unit: 'ก้าว',
      isNotificationEnabled: true,
      notificationTime: 'เป้าหมายรายวัน',
      repeatDays: ['จ.', 'อ.', 'พ.', 'พฤ.', 'ศ.', 'ส.', 'อา.'],
    ),
    RoutineItem(
      id: 'r_meditation',
      title: 'ทำสมาธิตอนเช้า',
      category: RoutineCategory.mindfulness,
      iconData: Icons.self_improvement_rounded,
      color: const Color(0xFF2E5327),
      targetValue: 15,
      currentValue: 0,
      unit: 'นาที',
      isNotificationEnabled: false,
      notificationTime: '07:00 AM',
      repeatDays: ['จ.', 'อ.', 'พ.', 'พฤ.', 'ศ.', 'ส.', 'อา.'],
    ),
    RoutineItem(
      id: 'r_lunch',
      title: 'บันทึกมื้อเที่ยง',
      category: RoutineCategory.nutrition,
      iconData: Icons.restaurant_rounded,
      color: const Color(0xFF2E5327),
      targetValue: 1,
      currentValue: 1,
      unit: 'มื้อ',
      isNotificationEnabled: true,
      notificationTime: '13:00 PM',
      repeatDays: ['จ.', 'อ.', 'พ.', 'พฤ.', 'ศ.', 'ส.', 'อา.'],
    ),
  ];

  void _toggleNotification(String id, bool isEnabled) {
    setState(() {
      final index = _routines.indexWhere((r) => r.id == id);
      if (index != -1) {
        _routines[index].isNotificationEnabled = isEnabled;
      }
    });

    final routine = _routines.firstWhere((r) => r.id == id);
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isEnabled
              ? 'เปิดการแจ้งเตือน "${routine.title}" แล้ว'
              : 'ปิดการแจ้งเตือน "${routine.title}" แล้ว',
        ),
        backgroundColor: isEnabled ? const Color(0xFF2E5327) : Colors.grey.shade800,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _deleteRoutine(String id) {
    setState(() {
      _routines.removeWhere((r) => r.id == id);
    });
  }

  Future<void> _openAddRoutineDialog() async {
    final RoutineItem? newRoutine = await showModalBottomSheet<RoutineItem>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => const AddRoutineDialog(),
    );

    if (newRoutine != null) {
      setState(() {
        _routines.add(newRoutine);
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 10),
              Text('เพิ่ม "${newRoutine.title}" ในกิจวัตรสำเร็จ!'),
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
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Top App Bar (Avatar + HealthyMate + Bell Icon)
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

                  // 2. Header Title & Subtitle (กิจวัตรของคุณ)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'กิจวัตรของคุณ',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1C2819),
                            letterSpacing: -0.5,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'จัดการนิสัยประจำวันและการแจ้งเตือน',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF677366),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // 3. Routine List Cards
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _routines.length,
                    itemBuilder: (context, index) {
                      final routine = _routines[index];
                      return RoutineCard(
                        key: ValueKey(routine.id),
                        routine: routine,
                        onToggleNotification: (val) => _toggleNotification(routine.id, val),
                        onDelete: () => _deleteRoutine(routine.id),
                      );
                    },
                  ),

                  const SizedBox(height: 100), // Spacing for FAB
                ],
              ),
            ),

            // 4. Floating Action Button (+ ปุ่มเพิ่มกิจวัตร)
            Positioned(
              right: 20,
              bottom: 20,
              child: Material(
                color: const Color(0xFF2E5327), // Forest Green
                borderRadius: BorderRadius.circular(18),
                elevation: 4,
                child: InkWell(
                  onTap: _openAddRoutineDialog,
                  borderRadius: BorderRadius.circular(18),
                  child: const SizedBox(
                    width: 56,
                    height: 56,
                    child: Icon(
                      Icons.add_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
