import 'package:flutter/material.dart';
import 'package:healthymate/core/database/app_database.dart';
import 'package:healthymate/core/services/api_service.dart';
import 'package:healthymate/features/health_calculator/models/user_model.dart';
import 'models/routine_item.dart';
import 'widgets/add_routine_dialog.dart';

class MyRoutinesPage extends StatefulWidget {
  final bool isActive;
  const MyRoutinesPage({super.key, this.isActive = true});

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
  // เก็บสถิติออกกำลังกายของวันนี้แยกตามประเภท (เช่น 'วิ่ง', 'เดิน')
  Map<String, Map<String, double>> _todayWorkoutStats = {};

  @override
  void didUpdateWidget(covariant MyRoutinesPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _loadData();
    }
  }

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

      // 5. ดึงข้อมูล workout และแยกสถิติของวันนี้
      final workouts = await db.getWorkouts(userId: userId);
      Map<String, Map<String, double>> todayStats = {};

      for (final w in workouts) {
        // คำนวณเฉพาะข้อมูลของวันนี้ เพื่อนำไปแสดงในกล่องกิจวัตรแต่ละประเภท
        final workoutDate = w['dtWorkoutDate']?.toString() ?? '';
        if (workoutDate.startsWith(_todayStr)) {
          final type = w['sType']?.toString() ?? 'อื่นๆ'; // เช่น 'วิ่ง', 'เดิน'
          final dist = (w['nDistance'] as num?)?.toDouble() ?? 0.0;
          final duration =
              (w['nDuration'] as num?)?.toDouble() ?? 0.0; // เป็นนาที

          if (!todayStats.containsKey(type)) {
            todayStats[type] = {'distance': 0.0, 'duration': 0.0};
          }
          todayStats[type]!['distance'] =
              (todayStats[type]!['distance'] ?? 0) + dist;
          todayStats[type]!['duration'] =
              (todayStats[type]!['duration'] ?? 0) + duration;
        }
      }

      if (mounted) {
        setState(() {
          _user = user;
          _routines = routines;
          _todayCompletionMap = completionMap;
          _completedCount = completedCount;
          _userGoal = _userGoal ?? goal;
          _todayWorkoutStats = todayStats; // 🔥 นำค่าของวันนี้มาเก็บไว้ใน State
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

      final serverRoutines =
          (serverResult['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      debugPrint(
        '[Routines] 🌐 ✅ Server routines: ${serverRoutines.length} รายการ',
      );

      // Merge: เมื่อ Server ตอบกลับสถานะสำเร็จ ให้อัปเดต UI และสถานะเช็คของวันนี้ (รวมถึงกรณีการลบรายการ)
      if (serverResult['status'] == 'success' && mounted) {
        final Map<int, bool> newCompletionMap = {};
        for (final r in serverRoutines) {
          final routineId = (r['nRoutineId'] as num?)?.toInt() ?? 0;
          newCompletionMap[routineId] =
              (r['todayCompleted'] as num?)?.toInt() == 1;
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
        targetValue: newRoutine.targetValue,
        unit: newRoutine.unit,
        linkedWorkout: newRoutine.linkedWorkoutType ?? '',
        color: newRoutine.color.value,
        iconData: newRoutine.iconData.codePoint,
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

  Future<void> _pinAsMainGoal(Map<String, dynamic> routine) async {
    final title = routine['sTitle']?.toString() ?? 'ไม่มีชื่อ';
    final routineId = (routine['nRoutineId'] as num?)?.toInt() ?? 0;
    final targetVal = (routine['targetValue'] as num?)?.toDouble() ?? 1.0;
    final unitText = routine['unit']?.toString() ?? 'ครั้ง';

    // คำนวณ progress เริ่มต้น
    final lowerTitle = title.toLowerCase();
    String matchedType = routine['sLinkedWorkout']?.toString() ?? '';
    if (matchedType.isEmpty) {
      if (lowerTitle.contains('วิ่ง')) matchedType = 'วิ่ง';
      else if (lowerTitle.contains('เดิน')) matchedType = 'เดิน';
      else if (lowerTitle.contains('จักรยาน') || lowerTitle.contains('ปั่น')) matchedType = 'ปั่นจักรยาน';
      else if (lowerTitle.contains('ลู่วิ่ง')) matchedType = 'ลู่วิ่งในร่ม';
    }

    double currentVal = 0.0;
    if (matchedType.isNotEmpty && _todayWorkoutStats.containsKey(matchedType)) {
      final stats = _todayWorkoutStats[matchedType]!;
      if (unitText.contains('กม') || unitText.contains('กิโล') || unitText.contains('km')) {
        currentVal = stats['distance'] ?? 0.0;
      } else if (unitText.contains('นาที') || unitText.contains('min') || unitText.contains('เวลา') || unitText.contains('ชม')) {
        currentVal = stats['duration'] ?? 0.0;
      }
    } else {
      final isDone = _todayCompletionMap[routineId] ?? false;
      currentVal = isDone ? targetVal : 0.0;
    }

    final double progress = targetVal > 0 ? (currentVal / targetVal).clamp(0.0, 1.0) : 0.0;
    final int percent = (progress * 100).toInt();
    final String remainingText = 'ความคืบหน้า: ${currentVal == currentVal.toInt() ? currentVal.toInt() : currentVal.toStringAsFixed(1)} / ${targetVal == targetVal.toInt() ? targetVal.toInt() : targetVal.toStringAsFixed(1)} $unitText ($percent%)';

    // อัปเดต State เพื่อแสดงกล่องเป้าหมายหลัก
    setState(() {
      _userGoal = {
        'nRoutineId': routineId,
        'sTitle': title,
        'nProgress': progress,
        'sRemainingText': remainingText,
      };
    });

    _showSnackBar('ปักหมุด "$title" เป็นเป้าหมายหลักแล้ว');

    // 🔥 บันทึกลง Database
    if (_user != null) {
      try {
        await AppDatabase.instance.saveUserGoal(
          userId: _user!.nUserId,
          nRoutineId: routineId,
          title: title,
          progress: progress,
          remainingText: remainingText,
        );
      } catch (e) {
        debugPrint('Error saving pin: $e');
      }
    }
  }

  Future<void> _unpinMainGoal() async {
    setState(() {
      _userGoal = null;
    });

    _showSnackBar('ยกเลิกการปักหมุดเป้าหมายหลักแล้ว');

    // 🔥 ลบออกจาก Database
    if (_user != null) {
      try {
        await AppDatabase.instance.clearUserGoal(_user!.nUserId);
      } catch (e) {
        debugPrint('Error clearing pin: $e');
      }
    }
  }

  Future<void> _deleteRoutine(int routineId, String title) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('ยืนยันการลบ'),
        content: Text(
          'ต้องการลบกิจวัตร "$title" หรือไม่?\nข้อมูลที่เช็คไว้จะถูกลบทั้งหมด',
        ),
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

      // หากเป็นตัวที่ปักหมุดไว้ ให้เคลียร์ออกจาก Goal ด้วย
      if (_userGoal != null) {
        final pinnedId = (_userGoal!['nRoutineId'] as num?)?.toInt() ?? 0;
        if (pinnedId == routineId || _userGoal!['sTitle'] == title) {
          setState(() {
            _userGoal = null;
          });
          if (_user != null) {
            await AppDatabase.instance.clearUserGoal(_user!.nUserId);
          }
        }
      }

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

    // เรียกหน้า AddRoutineDialog พร้อมส่งข้อมูลเก่าไป (initialRoutine)
    final RoutineItem? updatedRoutine = await showModalBottomSheet<RoutineItem>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => AddRoutineDialog(initialRoutine: routine),
    );

    if (updatedRoutine != null) {
      final newTitle = updatedRoutine.title;
      final newTime = updatedRoutine.notificationTime;

      // อัปเดต Local Database
      await AppDatabase.instance.updateRoutine(
        routineId: routineId,
        title: newTitle,
        time: newTime,
        targetValue: updatedRoutine.targetValue,
        unit: updatedRoutine.unit,
        linkedWorkout: updatedRoutine.linkedWorkoutType ?? '',
        color: updatedRoutine.color.value,
        iconData: updatedRoutine.iconData.codePoint,
        isNotificationActive: updatedRoutine.isNotificationEnabled,
      );
      debugPrint('[Routines] ✏️ แก้ไขกิจวัตร: "$currentTitle" → "$newTitle"');
      _showSnackBar('แก้ไขกิจวัตรสำเร็จ');

      // 🔥 เช็คและอัปเดตกล่องเป้าหมายหลักแบบ Real-time
      if (_userGoal != null) {
        final pinnedId = (_userGoal!['nRoutineId'] as num?)?.toInt() ?? 0;
        // เช็คว่า ID ตรงกัน หรือชื่อเก่าตรงกันหรือไม่
        if (pinnedId == routineId || _userGoal!['sTitle'] == currentTitle) {
          final targetVal = updatedRoutine.targetValue;
          final unitText = updatedRoutine.unit;
          final isDone = _todayCompletionMap[routineId] ?? false;
          final progress = isDone ? 1.0 : 0.0;
          final remainingText =
              'ความคืบหน้า: ${isDone ? targetVal : 0} / $targetVal $unitText';

          setState(() {
            _userGoal!['sTitle'] = newTitle;
            _userGoal!['sRemainingText'] = remainingText;
          });

          if (_user != null) {
            await AppDatabase.instance.saveUserGoal(
              userId: _user!.nUserId,
              nRoutineId: routineId,
              title: newTitle,
              progress: progress,
              remainingText: remainingText,
            );
          }
        }
      }

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

    // ถ้าตัวที่ toggle คือเป้าหมายหลัก ให้คำนวณ progress ใหม่และอัปเดต Goal ใน DB ด้วย
    if (_userGoal != null && _user != null) {
      final pinnedId = (_userGoal!['nRoutineId'] as num?)?.toInt() ?? 0;
      if (pinnedId == routineId) {
        final r = _routines.firstWhere(
          (item) => ((item['nRoutineId'] as num?)?.toInt() ?? 0) == routineId,
          orElse: () => {},
        );
        if (r.isNotEmpty) {
          final targetVal = (r['targetValue'] as num?)?.toDouble() ?? 1.0;
          final unitText = r['unit']?.toString() ?? 'ครั้ง';
          final currentVal = isCompleted ? targetVal : 0.0;
          final progress = isCompleted ? 1.0 : 0.0;
          final percent = (progress * 100).toInt();
          final remainingText =
              'ความคืบหน้า: ${currentVal == currentVal.toInt() ? currentVal.toInt() : currentVal.toStringAsFixed(1)} / ${targetVal == targetVal.toInt() ? targetVal.toInt() : targetVal.toStringAsFixed(1)} $unitText ($percent%)';

          setState(() {
            _userGoal = {
              'nRoutineId': routineId,
              'sTitle': r['sTitle']?.toString() ?? _userGoal!['sTitle'],
              'nProgress': progress,
              'sRemainingText': remainingText,
            };
          });

          AppDatabase.instance.saveUserGoal(
            userId: _user!.nUserId,
            nRoutineId: routineId,
            title: r['sTitle']?.toString() ?? _userGoal!['sTitle'],
            progress: progress,
            remainingText: remainingText,
          );
        }
      }
    }

    // Toggle Server (background)
    HealthApiService.toggleRoutineLogRemote(
      routineId: routineId,
      date: _todayStr,
    ).then((serverResult) {
      debugPrint(
        '[Routines] 🌐 Server toggle: routineId=$routineId → $serverResult',
      );
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
    required VoidCallback onPinAsMainGoal,
  }) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Colors.grey),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) {
        if (value == 'edit') onEdit();
        if (value == 'delete') onDelete();
        if (value == 'pin') onPinAsMainGoal(); // เพิ่มเงื่อนไขนี้
      },
      itemBuilder: (context) => [
        // เพิ่มเมนูปักหมุดไว้บนสุด
        const PopupMenuItem(
          value: 'pin',
          child: Row(
            children: [
              Icon(Icons.push_pin, color: Colors.orange, size: 20),
              SizedBox(width: 8),
              Text('ปักหมุดเป้าหมายหลัก'),
            ],
          ),
        ),
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

  Color _getRoutineColor(int index) =>
      _routineColors[index % _routineColors.length];
  IconData _getRoutineIcon(int index) =>
      _routineIcons[index % _routineIcons.length];

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
    if (time.contains('เย็น') || time.contains('คืน') || time.contains('Night'))
      return 'night';
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
              Text(
                'กำลังโหลดกิจวัตร...',
                style: TextStyle(color: Colors.grey.shade600),
              ),
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

                // 📌 นำฟังก์ชัน _buildMainGoalCard
                _buildMainGoalCard(),

                // Daily Routines Header
                _buildDailyRoutinesHeader(),
                const SizedBox(height: 16),
                // Empty state
                if (_routines.isEmpty) _buildEmptyState(),

                // ☀️ ช่วงเช้า
                if (morningRoutines.isNotEmpty) ...[
                  _buildTimeBlockHeader(
                    '☀️ ช่วงเช้า (Morning)',
                    '06:00 - 11:00',
                  ),
                  ...morningRoutines.map(
                    (r) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildRoutineCardFromDb(r, _routines.indexOf(r)),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                // 🏃 ระหว่างวัน
                if (afternoonRoutines.isNotEmpty) ...[
                  _buildTimeBlockHeader(
                    '🏃 ระหว่างวัน (Afternoon)',
                    '12:00 - 18:00',
                  ),
                  ...afternoonRoutines.map(
                    (r) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildRoutineCardFromDb(r, _routines.indexOf(r)),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                // 🌙 ก่อนนอน
                if (nightRoutines.isNotEmpty) ...[
                  _buildTimeBlockHeader('🌙 ก่อนนอน (Night)', '21:00 - 23:00'),
                  ...nightRoutines.map(
                    (r) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildRoutineCardFromDb(r, _routines.indexOf(r)),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                // ⭐ อื่นๆ
                if (otherRoutines.isNotEmpty) ...[
                  _buildTimeBlockHeader('⭐ กิจวัตรอื่นๆ', 'ตลอดทั้งวัน'),
                  ...otherRoutines.map(
                    (r) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildRoutineCardFromDb(r, _routines.indexOf(r)),
                    ),
                  ),
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
          Text(
            'กิจวัตรของฉัน',
            style: TextStyle(
              color: darkGreen,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const Text(
            '(My Routines)',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(
            Icons.notifications_active,
            color: Colors.blueGrey,
            size: 20,
          ),
          onPressed: () {},
        ),
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: CircleAvatar(
            radius: 16,
            backgroundColor: primaryGreen,
            child: Text(
              userName.isNotEmpty ? userName[0].toUpperCase() : '?',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
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
          Icon(
            Icons.playlist_add_check_rounded,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'ยังไม่มีกิจวัตร',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
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

  // --- Main Goal Card ---
  Widget _buildMainGoalCard() {
    final goalTitle = _userGoal?['sTitle']?.toString() ?? '';

    // เช็คว่าถ้าไม่มีเป้าหมายถูกปักหมุด ให้ "ซ่อน" กล่องนี้ไปเลย
    if (goalTitle.isEmpty) {
      return const SizedBox.shrink();
    }

    // ข้อมูลสำหรับแสดงผลเมื่อมีการปักหมุด
    final goalProgress = (_userGoal?['nProgress'] as num?)?.toDouble() ?? 0.0;
    final goalRemaining = _userGoal?['sRemainingText']?.toString() ?? '';
    final String subtitle = goalRemaining.isNotEmpty
        ? goalRemaining
        : 'ทำสำเร็จแล้ว ${(goalProgress * 100).toInt()}%';

    return Container(
      margin: const EdgeInsets.only(
        bottom: 24,
      ), // เพิ่มระยะห่างด้านล่างแทน SizedBox ในหน้าหลัก
      decoration: BoxDecoration(
        color: cardGreenBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryGreen.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 12, right: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: darkGreen,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '🚩 กิจวัตรจากเป้าหมายหลัก',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // ปุ่มจุด 3 จุด สำหรับยกเลิกการปักหมุด
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert,
                    color: Colors.grey,
                    size: 20,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: (value) {
                    if (value == 'unpin') _unpinMainGoal();
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'unpin',
                      child: Row(
                        children: [
                          Icon(Icons.close, color: Colors.grey, size: 20),
                          SizedBox(width: 8),
                          Text('ยกเลิกเป้าหมายหลัก'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: darkGreen.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      // ไอคอนของการ์ดเป้าหมายหลัก
                      child: Icon(Icons.flag, color: darkGreen),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            goalTitle,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // เช็กลิสต์สรุปวันนี้
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
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
                        style: TextStyle(
                          fontSize: 13,
                          color: darkGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      if (_routines.isNotEmpty)
                        Text(
                          '${(_completedCount / _routines.length * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 13,
                            color: darkGreen,
                            fontWeight: FontWeight.bold,
                          ),
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
    final times = _routines
        .map((r) => _getTimeBlock(r['sTime']?.toString() ?? ''))
        .toSet();
    timeBlockCount = times.length;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Text(
          'กิจวัตรประจำวัน (Daily\nRoutines)',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            height: 1.2,
          ),
        ),
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
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Color(0xFF1C2819),
            ),
          ),
          Text(
            timeRange,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // ฟังก์ชันดึงสีให้เข้ากับกิจวัตร
  Color _getDynamicColor(Map<String, dynamic> routine, int index) {
    // หาก Database มีการเก็บค่าสีไว้
    if (routine['color'] != null)
      return Color((routine['color'] as num).toInt());

    final title = routine['sTitle']?.toString().toLowerCase() ?? '';
    if (title.contains('น้ำ') ||
        title.contains('drink') ||
        title.contains('water'))
      return const Color(0xFF0288D1);
    if (title.contains('วิ่ง') ||
        title.contains('เดิน') ||
        title.contains('work'))
      return const Color(0xFF4CAF50);
    if (title.contains('สมาธิ') ||
        title.contains('นอน') ||
        title.contains('sleep'))
      return const Color(0xFF7E57C2);
    if (title.contains('อาหาร') ||
        title.contains('กิน') ||
        title.contains('eat'))
      return const Color(0xFFFF9800);
    if (title.contains('ยา') ||
        title.contains('pill') ||
        title.contains('health'))
      return const Color(0xFFE91E63);

    return _getRoutineColor(index); // ค่าเริ่มต้นตามลำดับ
  }

  // ฟังก์ชันดึงไอคอนให้เข้ากับกิจวัตร
  IconData _getDynamicIcon(Map<String, dynamic> routine, int index) {
    // หาก Database มีการเก็บรหัสไอคอนไว้
    if (routine['iconData'] != null)
      return IconData(
        (routine['iconData'] as num).toInt(),
        fontFamily: 'MaterialIcons',
      );

    final title = routine['sTitle']?.toString().toLowerCase() ?? '';
    if (title.contains('น้ำ') ||
        title.contains('drink') ||
        title.contains('water'))
      return Icons.water_drop_rounded;
    if (title.contains('วิ่ง') ||
        title.contains('เดิน') ||
        title.contains('work'))
      return Icons.directions_walk_rounded;
    if (title.contains('สมาธิ') ||
        title.contains('นอน') ||
        title.contains('sleep'))
      return Icons.self_improvement_rounded;
    if (title.contains('อาหาร') ||
        title.contains('กิน') ||
        title.contains('eat'))
      return Icons.restaurant_rounded;
    if (title.contains('ยา') ||
        title.contains('pill') ||
        title.contains('health'))
      return Icons.medical_services_rounded;

    return _getRoutineIcon(index); // ค่าเริ่มต้นตามลำดับ
  }

  // --- Routine Card จาก Database (เชื่อมข้อมูลจริง) ---
  Widget _buildRoutineCardFromDb(Map<String, dynamic> routine, int index) {
    final routineId = (routine['nRoutineId'] as num?)?.toInt() ?? 0;
    final title = routine['sTitle']?.toString() ?? 'ไม่มีชื่อ';

    // ดึงข้อมูลสีและไอคอน
    final color = _getDynamicColor(routine, index);
    final icon = _getDynamicIcon(routine, index);

    // --- ดึงข้อมูลเป้าหมายและหน่วย ---
    final targetVal = (routine['targetValue'] as num?)?.toDouble() ?? 1.0;
    final unitText = routine['unit']?.toString() ?? 'ครั้ง';
    final lowerTitle = title.toLowerCase();
    
    // --- โลจิกใหม่: ดึงค่าจากช่องที่เลือกลิงก์ไว้โดยตรง ---
    double? workoutCurrentVal;
    
    // 1. ดึงประเภทออกกำลังกายที่ผู้ใช้เลือกเชื่อมโยงไว้จาก Database
    String matchedType = routine['sLinkedWorkout']?.toString() ?? '';
    
    // 2. ถ้าไม่ได้เลือกไว้ (เป็นค่าว่าง) ให้ใช้วิธีค้นหาจากคีย์เวิร์ดในชื่อเป็นระบบสำรอง
    if (matchedType.isEmpty) {
      if (lowerTitle.contains('วิ่ง')) matchedType = 'วิ่ง';
      else if (lowerTitle.contains('เดิน')) matchedType = 'เดิน';
      else if (lowerTitle.contains('จักรยาน') || lowerTitle.contains('ปั่น')) matchedType = 'ปั่นจักรยาน';
      else if (lowerTitle.contains('ลู่วิ่ง')) matchedType = 'ลู่วิ่งในร่ม';
    }
    
    // 3. นำประเภทที่ได้ไปดึงข้อมูลสถิติของวันนี้มาแสดง
    if (matchedType.isNotEmpty && _todayWorkoutStats.containsKey(matchedType)) {
      final stats = _todayWorkoutStats[matchedType]!;
      if (unitText.contains('กม') || unitText.contains('กิโล') || unitText.contains('km')) {
        workoutCurrentVal = stats['distance'];
      } else if (unitText.contains('นาที') || unitText.contains('min') || unitText.contains('เวลา') || unitText.contains('ชม')) {
        workoutCurrentVal = stats['duration'];
      }
    }

    // 3. กำหนดค่าปัจจุบัน 
    // (ถ้ามีข้อมูลออกกำลังกาย ให้ใช้ข้อมูลนั้นอัตโนมัติ ถ้าไม่มีค่อยใช้ค่าจากการติ๊กมือ)
    final isManuallyCompleted = _todayCompletionMap[routineId] ?? false;
    final currentVal = workoutCurrentVal ?? ((routine['currentValue'] as num?)?.toDouble() ?? (isManuallyCompleted ? targetVal : 0.0));
    
    // 4. เช็คสถานะว่าถึงเป้าหมายหรือยัง
    final bool isActuallyCompleted = currentVal >= targetVal;

    // --- กำหนดข้อความและปุ่มตามหมวดหมู่ (เพื่อให้ตรงดีไซน์ภาพ) ---
    String actionBtnText = 'ทำรายการ';
    IconData? actionBtnIcon;
    bool isPrimaryAction = false;
    String subtitleText = 'เป้าหมายประจำวัน: $targetVal $unitText';

    if (lowerTitle.contains('น้ำ') || lowerTitle.contains('drink')) {
      subtitleText = 'เป้าหมายเข้าถึงบ่าย: $targetVal $unitText';
      actionBtnText = '+250 ml';
      actionBtnIcon = Icons.add;
      isPrimaryAction = true;
    } else if (lowerTitle.contains('เดิน') ||
        lowerTitle.contains('ก้าว') ||
        lowerTitle.contains('วิ่ง')) {
      subtitleText = 'เป้าหมายการขยับร่างกาย: $targetVal $unitText';
      actionBtnText = 'ซิงค์ข้อมูล';
      actionBtnIcon = Icons.sync;
      isPrimaryAction = false;
    } else if (lowerTitle.contains('นอน') || lowerTitle.contains('sleep')) {
      subtitleText = 'พักผ่อนอย่างมีคุณภาพ: เป้าหมาย $targetVal $unitText';
      actionBtnText = 'ตั้งเวลา';
      actionBtnIcon = Icons.alarm;
      isPrimaryAction = false;
    } else {
      actionBtnText = isActuallyCompleted ? 'เสร็จแล้ว' : 'บันทึก';
      actionBtnIcon = isActuallyCompleted ? Icons.check : Icons.edit;
      isPrimaryAction = !isActuallyCompleted;
    }

    // คำนวณเปอร์เซ็นต์
    final double progressRatio = targetVal > 0
        ? (currentVal / targetVal).clamp(0.0, 1.0)
        : 0.0;
    final int percent = (progressRatio * 100).toInt();

    // ฟังก์ชันช่วยจัดรูปแบบตัวเลข (ซ่อน .0 ถ้าเป็นจำนวนเต็ม)
    String formatValue(double val) =>
        val == val.toInt() ? val.toInt().toString() : val.toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- ส่วนบน (Icon, Text, Action Button) ---
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. ไอคอน
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 14),

              // 2. ชื่อกิจวัตร และ ป้ายเปอร์เซ็นต์
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Color(0xFF1E293B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$percent%',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitleText,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // 3. ปุ่ม Action และ เมนู 3 จุด
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () {
                      // กดปุ่มนี้แล้วไปเรียกฟังก์ชันติ๊กเสร็จสิ้นที่มีอยู่เดิมในระบบ
                      _toggleRoutineCompletion(routineId);
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isPrimaryAction
                            ? color
                            : color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          if (actionBtnIcon != null) ...[
                            Icon(
                              actionBtnIcon,
                              size: 14,
                              color: isPrimaryAction ? Colors.white : color,
                            ),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            actionBtnText,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isPrimaryAction ? Colors.white : color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  _buildThreeDotsMenu(
                    onEdit: () => _editRoutine(routine),
                    onDelete: () => _deleteRoutine(routineId, title),
                    onPinAsMainGoal: () => _pinAsMainGoal(routine),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // --- ส่วนล่าง (Progress Bar) ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ความคืบหน้า',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
              Text(
                '${formatValue(currentVal)} / ${formatValue(targetVal)} $unitText ($percent%)',
                style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progressRatio,
              minHeight: 8,
              backgroundColor: color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}
