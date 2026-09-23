import 'package:flutter/material.dart';
import 'package:healthymate/core/database/app_database.dart';
import 'package:healthymate/core/services/api_service.dart';
import 'package:healthymate/features/health_calculator/models/user_model.dart';
import 'models/routine_item.dart';
import 'widgets/add_routine_dialog.dart';

class MyRoutinesPage extends StatefulWidget {
  const MyRoutinesPage({super.key});

  @override
  State<MyRoutinesPage> createState() => _MyRoutinesPageState();
}

class _MyRoutinesPageState extends State<MyRoutinesPage> {
  final Color primaryGreen = const Color(0xFF0F9C58);
  final Color darkGreen = const Color(0xFF006432);
  final Color lightBg = const Color(0xFFF7F9FB);
  final Color cardGreenBg = const Color(0xFFE8F5E9);

  // ---------- State ----------
  bool _isLoading = true;
  TbUser? _user;
  List<Map<String, dynamic>> _routines = [];
  // routineId -> isCompleted (for today)
  Map<int, bool> _todayCompletionMap = {};
  int _completedCount = 0;
  Map<String, dynamic>? _userGoal;

  // ข้อมูล workout สำหรับ main goal card
  double _totalDistanceKm = 0.0;
  double _totalCaloriesBurned = 0.0;
  int _workoutCount = 0;

  String get _todayStr {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final db = AppDatabase.instance;

      // 1. หา user
      final email = await db.getLoggedInUserEmail();
      TbUser? user;
      if (email != null && email.isNotEmpty) {
        user = await db.getUserByEmail(email);
      }
      user ??= await db.getUser(userId: 1);

      if (user == null) {
        debugPrint('[Routines] ❌ ไม่พบข้อมูลผู้ใช้');
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final userId = user.nUserId;
      debugPrint('[Routines] ✅ ผู้ใช้: ${user.sFullName} (ID=$userId)');

      // 2. ดึงกิจวัตรทั้งหมด
      final routines = await db.getRoutines(userId: userId);
      debugPrint('[Routines] 📋 กิจวัตร: ${routines.length} รายการ');

      // 3. ดึง completion สำหรับวันนี้
      final Map<int, bool> completionMap = {};
      for (final r in routines) {
        final routineId = (r['nRoutineId'] as num?)?.toInt() ?? 0;
        final log = await db.getRoutineLogForDate(
          routineId: routineId,
          dateStr: _todayStr,
        );
        completionMap[routineId] = (log?['isCompleted'] as num?)?.toInt() == 1;
      }
      final completedCount = completionMap.values.where((v) => v).length;

      // 4. ดึงเป้าหมายหลัก
      final goal = await db.getUserGoal(userId);

      // 5. ดึงข้อมูล workout
      final workouts = await db.getWorkouts(userId: userId);
      double totalDist = 0.0;
      double totalCal = 0.0;
      for (final w in workouts) {
        totalDist += (w['nDistance'] as num?)?.toDouble() ?? 0.0;
        totalCal += (w['nCaloriesBurned'] as num?)?.toDouble() ?? 0.0;
      }

      if (mounted) {
        setState(() {
          _user = user;
          _routines = routines;
          _todayCompletionMap = completionMap;
          _completedCount = completedCount;
          _userGoal = goal;
          _totalDistanceKm = totalDist;
          _totalCaloriesBurned = totalCal;
          _workoutCount = workouts.length;
          _isLoading = false;
        });
      }

      // 6. Sync จาก Server (background)
      _syncRoutinesFromServer(userId);
    } catch (e, stack) {
      debugPrint('[Routines] ❌ Error loading data: $e');
      debugPrint('[Routines] Stack: $stack');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// ดึงกิจวัตรจาก Server แล้ว merge กับ local
  Future<void> _syncRoutinesFromServer(int userId) async {
    try {
      debugPrint('[Routines] 🌐 กำลังซิงค์จาก Server...');
      final serverResult = await HealthApiService.fetchRoutines(userId: userId);

      if (serverResult == null) {
        debugPrint('[Routines] 🌐 Server ไม่ตอบ — ใช้ข้อมูล Local');
        return;
      }

      final serverRoutines = (serverResult['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      debugPrint('[Routines] 🌐 ✅ Server routines: ${serverRoutines.length} รายการ');

      // Merge: เมื่อ Server ตอบกลับสถานะสำเร็จ ให้อัปเดต UI และสถานะเช็คของวันนี้ (รวมถึงกรณีการลบรายการ)
      if (serverResult['status'] == 'success' && mounted) {
        final Map<int, bool> newCompletionMap = {};
        for (final r in serverRoutines) {
          final routineId = (r['nRoutineId'] as num?)?.toInt() ?? 0;
          newCompletionMap[routineId] = (r['todayCompleted'] as num?)?.toInt() == 1;
        }
        setState(() {
          _routines = serverRoutines;
          _todayCompletionMap = newCompletionMap;
          _completedCount = newCompletionMap.values.where((v) => v).length;
        });
        debugPrint('[Routines] 🌐 ✅ UI อัปเดตจาก Server (รวมการลบ/สลับสถานะ)');
      }
    } catch (e) {
      debugPrint('[Routines] 🌐 ❌ Sync error: $e');
    }
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

    if (newRoutine != null && _user != null) {
      // บันทึก Local
      final id = await AppDatabase.instance.insertRoutine(
        userId: _user!.nUserId,
        title: newRoutine.title,
        time: newRoutine.notificationTime,
        isNotificationActive: newRoutine.isNotificationEnabled,
      );
      debugPrint('[Routines] ✅ เพิ่มกิจวัตร: "${newRoutine.title}" (ID=$id)');
      _showSnackBar('เพิ่ม "${newRoutine.title}" ในกิจวัตรสำเร็จ!');

      // บันทึก Server (background)
      HealthApiService.insertRoutineRemote(
        userId: _user!.nUserId,
        title: newRoutine.title,
        time: newRoutine.notificationTime,
        isNotificationActive: newRoutine.isNotificationEnabled,
      ).then((serverId) {
        debugPrint('[Routines] 🌐 Server insert: ID=$serverId');
      });

      await _loadData();
    }
  }

  Future<void> _deleteRoutine(int routineId, String title) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('ยืนยันการลบ'),
        content: Text('ต้องการลบกิจวัตร "$title" หรือไม่?\nข้อมูลที่เช็คไว้จะถูกลบทั้งหมด'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ลบ', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // ลบ Local
      await AppDatabase.instance.deleteRoutine(routineId);
      debugPrint('[Routines] 🗑️ ลบกิจวัตร: "$title" (ID=$routineId)');
      _showSnackBar('ลบ "$title" เรียบร้อย');

      // ลบ Server (background)
      HealthApiService.deleteRoutineRemote(routineId).then((ok) {
        debugPrint('[Routines] 🌐 Server delete: ${ok ? "✅" : "❌"}');
      });

      await _loadData();
    }
  }

  Future<void> _editRoutine(Map<String, dynamic> routine) async {
    final routineId = (routine['nRoutineId'] as num?)?.toInt() ?? 0;
    final currentTitle = routine['sTitle']?.toString() ?? '';
    final currentTime = routine['sTime']?.toString() ?? '';

    final titleController = TextEditingController(text: currentTitle);
    final timeController = TextEditingController(text: currentTime);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.edit, color: darkGreen),
            const SizedBox(width: 8),
            const Text('แก้ไขกิจวัตร'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: 'ชื่อกิจวัตร',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: timeController,
              decoration: InputDecoration(
                labelText: 'เวลาแจ้งเตือน',
                hintText: 'เช่น 08:00 น.',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: darkGreen,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('บันทึก', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result == true) {
      final newTitle = titleController.text.trim();
      final newTime = timeController.text.trim();

      // อัปเดต Local
      await AppDatabase.instance.updateRoutine(
        routineId: routineId,
        title: newTitle,
        time: newTime,
      );
      debugPrint('[Routines] ✏️ แก้ไขกิจวัตร: "$currentTitle" → "$newTitle"');
      _showSnackBar('แก้ไขกิจวัตรสำเร็จ');

      // อัปเดต Server (background)
      HealthApiService.updateRoutineRemote(
        routineId: routineId,
        title: newTitle,
        time: newTime,
      ).then((ok) {
        debugPrint('[Routines] 🌐 Server update: ${ok ? "✅" : "❌"}');
      });

      await _loadData();
    }

    titleController.dispose();
    timeController.dispose();
  }

  Future<void> _toggleRoutineCompletion(int routineId) async {
    // Toggle Local
    final isCompleted = await AppDatabase.instance.toggleRoutineLog(
      routineId: routineId,
      dateStr: _todayStr,
    );

    if (mounted) {
      setState(() {
        _todayCompletionMap[routineId] = isCompleted;
        _completedCount = _todayCompletionMap.values.where((v) => v).length;
      });
    }

    // Toggle Server (background)
    HealthApiService.toggleRoutineLogRemote(
      routineId: routineId,
      date: _todayStr,
    ).then((serverResult) {
      debugPrint('[Routines] 🌐 Server toggle: routineId=$routineId → $serverResult');
    });
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: darkGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // --- เมนู 3 จุด (Popup Menu) ---
  Widget _buildThreeDotsMenu({
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Colors.grey),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) {
        if (value == 'edit') onEdit();
        if (value == 'delete') onDelete();
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, color: Colors.blue, size: 20),
              SizedBox(width: 8),
              Text('แก้ไข'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, color: Colors.red, size: 20),
              SizedBox(width: 8),
              Text('ลบ'),
            ],
          ),
        ),
      ],
    );
  }

  // ---------- สีและไอคอนตามลำดับกิจวัตร ----------
  static const _routineColors = [
    Colors.blue,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.red,
    Colors.indigo,
    Colors.green,
    Colors.pink,
  ];

  static const _routineIcons = [
    Icons.check_circle_outline,
    Icons.fitness_center,
    Icons.self_improvement,
    Icons.water_drop,
    Icons.directions_walk,
    Icons.bedtime,
    Icons.restaurant,
    Icons.favorite,
  ];

  Color _getRoutineColor(int index) => _routineColors[index % _routineColors.length];
  IconData _getRoutineIcon(int index) => _routineIcons[index % _routineIcons.length];

  // ---------- Time block classification ----------
  String _getTimeBlock(String? time) {
    if (time == null || time.isEmpty) return 'other';
    // ลองแปลง HH:mm
    final match = RegExp(r'(\d{1,2})[:\.](\d{2})').firstMatch(time);
    if (match != null) {
      final hour = int.tryParse(match.group(1) ?? '') ?? 12;
      if (hour < 12) return 'morning';
      if (hour < 18) return 'afternoon';
      return 'night';
    }
    // ถ้าไม่มีเวลา ดูจาก keyword
    if (time.contains('เช้า') || time.contains('Morning')) return 'morning';
    if (time.contains('บ่าย') || time.contains('Afternoon')) return 'afternoon';
    if (time.contains('เย็น') || time.contains('คืน') || time.contains('Night')) return 'night';
    return 'other';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: lightBg,
        appBar: _buildAppBar(),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: primaryGreen),
              const SizedBox(height: 16),
              Text('กำลังโหลดกิจวัตร...', style: TextStyle(color: Colors.grey.shade600)),
            ],
          ),
        ),
      );
    }

    // จัดกลุ่มกิจวัตรตามช่วงเวลา
    final morningRoutines = <Map<String, dynamic>>[];
    final afternoonRoutines = <Map<String, dynamic>>[];
    final nightRoutines = <Map<String, dynamic>>[];
    final otherRoutines = <Map<String, dynamic>>[];

    for (final r in _routines) {
      final time = r['sTime']?.toString() ?? '';
      switch (_getTimeBlock(time)) {
        case 'morning':
          morningRoutines.add(r);
          break;
        case 'afternoon':
          afternoonRoutines.add(r);
          break;
        case 'night':
          nightRoutines.add(r);
          break;
        default:
          otherRoutines.add(r);
      }
    }

    return Scaffold(
      backgroundColor: lightBg,
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        color: primaryGreen,
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),

                // Main Goal Card
                _buildMainGoalCard(),
                const SizedBox(height: 24),

                // Daily Routines Header
                _buildDailyRoutinesHeader(),
                const SizedBox(height: 16),

                // Empty state
                if (_routines.isEmpty)
                  _buildEmptyState(),

                // ☀️ ช่วงเช้า
                if (morningRoutines.isNotEmpty) ...[
                  _buildTimeBlockHeader('☀️ ช่วงเช้า (Morning)', '06:00 - 11:00'),
                  ...morningRoutines.map((r) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildRoutineCardFromDb(r, _routines.indexOf(r)),
                  )),
                  const SizedBox(height: 8),
                ],

                // 🏃 ระหว่างวัน
                if (afternoonRoutines.isNotEmpty) ...[
                  _buildTimeBlockHeader('🏃 ระหว่างวัน (Afternoon)', '12:00 - 18:00'),
                  ...afternoonRoutines.map((r) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildRoutineCardFromDb(r, _routines.indexOf(r)),
                  )),
                  const SizedBox(height: 8),
                ],

                // 🌙 ก่อนนอน
                if (nightRoutines.isNotEmpty) ...[
                  _buildTimeBlockHeader('🌙 ก่อนนอน (Night)', '21:00 - 23:00'),
                  ...nightRoutines.map((r) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildRoutineCardFromDb(r, _routines.indexOf(r)),
                  )),
                  const SizedBox(height: 8),
                ],

                // ⭐ อื่นๆ
                if (otherRoutines.isNotEmpty) ...[
                  _buildTimeBlockHeader('⭐ กิจวัตรอื่นๆ', 'ตลอดทั้งวัน'),
                  ...otherRoutines.map((r) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildRoutineCardFromDb(r, _routines.indexOf(r)),
                  )),
                ],

                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddRoutineDialog,
        backgroundColor: darkGreen,
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final userName = _user?.sFirstName ?? 'ผู้ใช้งาน';
    return AppBar(
      backgroundColor: lightBg,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('กิจวัตรของฉัน', style: TextStyle(color: darkGreen, fontWeight: FontWeight.bold, fontSize: 18)),
          const Text('(My Routines)', style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
      actions: [
        IconButton(icon: const Icon(Icons.notifications_active, color: Colors.blueGrey, size: 20), onPressed: () {}),
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: CircleAvatar(
            radius: 16,
            backgroundColor: primaryGreen,
            child: Text(
              userName.isNotEmpty ? userName[0].toUpperCase() : '?',
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  // --- Empty State ---
  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.playlist_add_check_rounded, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'ยังไม่มีกิจวัตร',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            'กดปุ่ม + ด้านล่างเพื่อเพิ่มกิจวัตรประจำวัน\nเช่น ดื่มน้ำ, ออกกำลังกาย, นั่งสมาธิ',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  // --- Main Goal Card (from DB) ---
  Widget _buildMainGoalCard() {
    final goalTitle = _userGoal?['sTitle']?.toString() ?? '';
    final goalProgress = (_userGoal?['nProgress'] as num?)?.toDouble() ?? 0.0;
    final goalRemaining = _userGoal?['sRemainingText']?.toString() ?? '';

    // Fallback to workout stats if no goal
    final String title;
    final String subtitle;
    if (goalTitle.isNotEmpty) {
      title = goalTitle;
      subtitle = goalRemaining.isNotEmpty
          ? goalRemaining
          : 'ทำสำเร็จแล้ว ${(goalProgress * 100).toInt()}%';
    } else {
      title = 'วิ่งเก็บระยะทางสะสม';
      subtitle = 'สะสมแล้ว ${_totalDistanceKm.toStringAsFixed(1)} กม. | $_workoutCount ครั้ง | ${_totalCaloriesBurned.toStringAsFixed(0)} kcal';
    }

    return Container(
      decoration: BoxDecoration(
        color: cardGreenBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryGreen.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 12, right: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: darkGreen, borderRadius: BorderRadius.circular(12)),
              child: const Text('🚩 กิจวัตรจากเป้าหมายหลัก', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ),
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: darkGreen.withValues(alpha: 0.12), shape: BoxShape.circle),
                      child: Icon(Icons.directions_run, color: darkGreen),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 4),
                          Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // เช็กลิสต์สรุปวันนี้
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: primaryGreen.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.checklist, size: 18, color: darkGreen),
                      const SizedBox(width: 8),
                      Text(
                        'วันนี้ทำสำเร็จ $_completedCount / ${_routines.length} กิจวัตร',
                        style: TextStyle(fontSize: 13, color: darkGreen, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      if (_routines.isNotEmpty)
                        Text(
                          '${(_completedCount / _routines.length * 100).toInt()}%',
                          style: TextStyle(fontSize: 13, color: darkGreen, fontWeight: FontWeight.bold),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyRoutinesHeader() {
    // นับจำนวนช่วงเวลาที่มีกิจวัตร
    int timeBlockCount = 0;
    final times = _routines.map((r) => _getTimeBlock(r['sTime']?.toString() ?? '')).toSet();
    timeBlockCount = times.length;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Text('กิจวัตรประจำวัน (Daily\nRoutines)', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, height: 1.2)),
        Text(
          _routines.isEmpty ? 'ยังไม่มี' : '$timeBlockCount ช่วง\nเวลา',
          textAlign: TextAlign.right,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildTimeBlockHeader(String title, String timeRange) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1C2819))),
          Text(timeRange, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  // --- Routine Card จาก Database ---
  Widget _buildRoutineCardFromDb(Map<String, dynamic> routine, int index) {
    final routineId = (routine['nRoutineId'] as num?)?.toInt() ?? 0;
    final title = routine['sTitle']?.toString() ?? 'ไม่มีชื่อ';
    final time = routine['sTime']?.toString() ?? '';
    final isNotifActive = (routine['isNotificationActive'] as num?)?.toInt() == 1;
    final isCompleted = _todayCompletionMap[routineId] ?? false;
    final color = _getRoutineColor(index);
    final icon = _getRoutineIcon(index);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCompleted ? color.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isCompleted ? Border.all(color: color.withValues(alpha: 0.3)) : null,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ไอคอน
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              // ชื่อ + เวลา
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              decoration: isCompleted ? TextDecoration.lineThrough : null,
                              color: isCompleted ? Colors.grey : Colors.black87,
                            ),
                          ),
                        ),
                        if (isCompleted)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('✅ เสร็จแล้ว', style: TextStyle(color: Colors.green.shade800, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (time.isNotEmpty) ...[
                          Icon(Icons.access_time, size: 14, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(time, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                          const SizedBox(width: 12),
                        ],
                        if (isNotifActive)
                          Icon(Icons.notifications_active, size: 14, color: Colors.amber.shade700)
                        else
                          Icon(Icons.notifications_off, size: 14, color: Colors.grey.shade400),
                      ],
                    ),
                  ],
                ),
              ),
              // Actions
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Check/Uncheck Button
                  InkWell(
                    onTap: () => _toggleRoutineCompletion(routineId),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isCompleted ? color.withValues(alpha: 0.15) : Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                        color: isCompleted ? color : Colors.grey,
                        size: 24,
                      ),
                    ),
                  ),
                  _buildThreeDotsMenu(
                    onEdit: () => _editRoutine(routine),
                    onDelete: () => _deleteRoutine(routineId, title),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}