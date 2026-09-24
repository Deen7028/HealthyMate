import 'package:flutter/material.dart';
import 'package:healthymate/core/database/app_database.dart';
import 'package:healthymate/core/services/api_service.dart';
import 'package:healthymate/features/health_calculator/models/user_model.dart';
import 'models/routine_item.dart';
import 'widgets/add_routine_dialog.dart';

class MyRoutinesPage extends StatefulWidget {
  final bool isActive;
  final Function(String? workoutCategory)? onNavigateToWorkout;

  const MyRoutinesPage({
    super.key,
    this.isActive = true,
    this.onNavigateToWorkout,
  });

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
  // routineId -> currentValue (for today step progress)
  Map<int, double> _todayProgressValues = {};

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

      // 3. ดึง completion สำหรับวันนี้และคำนวณค่าสะสม
      final Map<int, bool> completionMap = {};
      final Map<int, double> progressValues = {};
      for (final r in routines) {
        final routineId = (r['nRoutineId'] as num?)?.toInt() ?? 0;
        final targetVal = (r['targetValue'] as num?)?.toDouble() ?? 1.0;
        final log = await db.getRoutineLogForDate(
          routineId: routineId,
          dateStr: _todayStr,
        );
        final isDone = (log?['isCompleted'] as num?)?.toInt() == 1;
        completionMap[routineId] = isDone;
        progressValues[routineId] = isDone ? targetVal : 0.0;
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
          _todayProgressValues = progressValues;
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
      if (serverResult['status'] == 'success' && serverRoutines.isNotEmpty && mounted) {
        final Map<int, bool> newCompletionMap = Map.from(_todayCompletionMap);
        for (final r in serverRoutines) {
          final routineId = (r['nRoutineId'] as num?)?.toInt() ?? 0;
          if (r.containsKey('todayCompleted') && r['todayCompleted'] != null) {
            newCompletionMap[routineId] = (r['todayCompleted'] as num?)?.toInt() == 1;
          }
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
        color: newRoutine.color.toARGB32(),
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
      if (lowerTitle.contains('วิ่ง')) {
        matchedType = 'วิ่ง';
      } else if (lowerTitle.contains('เดิน')) {
        matchedType = 'เดิน';
      } else if (lowerTitle.contains('จักรยาน') || lowerTitle.contains('ปั่น')) {
        matchedType = 'ปั่นจักรยาน';
      } else if (lowerTitle.contains('ลู่วิ่ง')) {
        matchedType = 'ลู่วิ่งในร่ม';
      }
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
        color: updatedRoutine.color.toARGB32(),
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

  RoutineButtonType _getRoutineButtonType(Map<String, dynamic> routine, bool isWorkoutRoutine) {
    if (isWorkoutRoutine) return RoutineButtonType.workout;

    final unit = (routine['unit']?.toString() ?? '').toLowerCase();
    final title = (routine['sTitle']?.toString() ?? '').toLowerCase();
    final targetVal = (routine['targetValue'] as num?)?.toDouble() ?? 1.0;

    // 1. Interactive Timer: unit = นาที, min, ชม, hr หรือ title มีคำว่า สมาธิ, หายใจ
    if (unit.contains('นาที') ||
        unit.contains('min') ||
        unit.contains('ชม') ||
        unit.contains('hr') ||
        title.contains('สมาธิ') ||
        title.contains('หายใจ') ||
        title.contains('โฟกัส')) {
      return RoutineButtonType.timer;
    }

    // 2. Quick Step-Add: unit = มล, ml, ลิตร, l, มื้อ, แก้ว, จาน, ครั้ง (และ targetVal > 1)
    if ((unit.contains('มล') ||
            unit.contains('ml') ||
            unit.contains('ลิตร') ||
            unit.contains('มื้อ') ||
            unit.contains('แก้ว') ||
            unit.contains('จาน') ||
            unit.contains('หน้า') ||
            unit.contains('ครั้ง')) &&
        targetVal > 1.0) {
      return RoutineButtonType.stepAdd;
    }

    // 3. Single-Check Toggle
    return RoutineButtonType.singleCheck;
  }

  double _calculateStepAmount(double targetVal, String unit) {
    final u = unit.toLowerCase();
    if (u.contains('มล') || u.contains('ml')) {
      if (targetVal >= 2000) return 250;
      if (targetVal >= 1000) return 200;
      if (targetVal >= 500) return 100;
      return 50;
    }
    if (u.contains('ลิตร') || u.contains('l')) {
      if (targetVal >= 2) return 0.25;
      return 0.1;
    }
    if (u.contains('มื้อ') || u.contains('แก้ว') || u.contains('จาน') || u.contains('ครั้ง') || u.contains('หน้า')) {
      return 1.0;
    }
    if (targetVal <= 5) return 1.0;
    if (targetVal <= 20) return 2.0;
    return (targetVal / 4).roundToDouble().clamp(1.0, targetVal);
  }

  Future<void> _incrementRoutineValue(int routineId, double stepVal, double targetVal) async {
    final current = _todayProgressValues[routineId] ?? 0.0;
    double nextVal = current + stepVal;
    if (nextVal > targetVal) nextVal = targetVal;

    setState(() {
      _todayProgressValues[routineId] = nextVal;
    });

    if (nextVal >= targetVal) {
      if (!(_todayCompletionMap[routineId] ?? false)) {
        await _toggleRoutineCompletion(routineId);
      }
    }
  }

  void _showCountdownTimerDialog(BuildContext context, Map<String, dynamic> routine, int durationMinutes) {
    final title = routine['sTitle']?.toString() ?? 'จับเวลาทำกิจกรรม';
    final routineId = (routine['nRoutineId'] as num?)?.toInt() ?? 0;
    final targetVal = (routine['targetValue'] as num?)?.toDouble() ?? durationMinutes.toDouble();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return _RoutineCountdownTimerModal(
          title: title,
          durationMinutes: durationMinutes,
          onTimerCompleted: () async {
            if (mounted) {
              setState(() {
                _todayProgressValues[routineId] = targetVal;
              });
              if (!(_todayCompletionMap[routineId] ?? false)) {
                await _toggleRoutineCompletion(routineId);
              }
              _showSnackBar('🎉 ทำ "$title" ครบเวลาเรียบร้อยแล้ว!');
            }
          },
        );
      },
    );
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

  // ignore: unused_element
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
                // 1.1 Top Overview Banner (สรุปภารกิจประจำวัน โทนสีเขียวป่า #2E5327)
                _buildTopOverviewBanner(),
                const SizedBox(height: 20),

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

  // --- 1.1 Top Overview Banner (ส่วนสรุปความคืบหน้ารวม โทนสีเขียวป่า #2E5327) ---
  Widget _buildTopOverviewBanner() {
    final totalCount = _routines.length;
    final overallPercent = totalCount > 0 ? ((_completedCount / totalCount) * 100).toInt() : 0;
    final overallRatio = totalCount > 0 ? (_completedCount / totalCount).clamp(0.0, 1.0) : 0.0;

    // คำนวณแคลอรีรวมจากการออกกำลังกายของวันนี้
    double totalCalories = 0.0;
    double totalDurationMin = 0.0;
    _todayWorkoutStats.forEach((_, stats) {
      totalDurationMin += (stats['duration'] ?? 0.0);
    });
    for (final r in _routines) {
      final rId = (r['nRoutineId'] as num?)?.toInt() ?? 0;
      if (_todayCompletionMap[rId] == true) {
        totalCalories += 150; // ประเมินแคลอรีเฉลี่ยต่อภารกิจที่ทำสำเร็จ
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2E5327), // Forest Green #2E5327
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E5327).withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: const Color(0xFF43703B),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.task_alt_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'สรุปภารกิจประจำวัน',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'วันนี้ $_completedCount/$totalCount รายการ',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ตัวเลขเปอร์เซ็นต์ใหญ่แบบ WorkoutTopStatsCard
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$overallPercent',
                style: const TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -1,
                ),
              ),
              const Text(
                '%',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF90DB89),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _completedCount == totalCount && totalCount > 0
                          ? 'สุดยอด! ทำครบทุกภารกิจแล้ว 🎉'
                          : 'ความคืบหน้าภาพรวมวันนี้',
                      style: const TextStyle(fontSize: 12, color: Color(0xFFA0ACA0), fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: overallRatio,
                        minHeight: 8,
                        backgroundColor: Colors.white.withValues(alpha: 0.15),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF90DB89)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(height: 1, color: Colors.white12),
          const SizedBox(height: 14),

          // สถิติย่อย 3 ช่อง สไตล์เดียวกับ WorkoutTopStatsCard
          Row(
            children: [
              Expanded(
                child: _buildBannerStatTile(
                  label: 'เผาผลาญ',
                  value: '${totalCalories.toInt()}',
                  unit: 'kcal',
                  icon: Icons.local_fire_department_rounded,
                ),
              ),
              Container(height: 30, width: 1, color: Colors.white12),
              Expanded(
                child: _buildBannerStatTile(
                  label: 'เวลารวม',
                  value: '${totalDurationMin.toInt()}',
                  unit: 'นาที',
                  icon: Icons.timer_outlined,
                ),
              ),
              Container(height: 30, width: 1, color: Colors.white12),
              Expanded(
                child: _buildBannerStatTile(
                  label: 'สำเร็จแล้ว',
                  value: '$_completedCount',
                  unit: 'รายการ',
                  icon: Icons.check_circle_outline_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBannerStatTile({
    required String label,
    required String value,
    required String unit,
    required IconData icon,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 13, color: const Color(0xFF90DB89)),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFFA0ACA0),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        RichText(
          text: TextSpan(
            text: value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
            children: [
              TextSpan(
                text: ' $unit',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFFA0ACA0),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- Routine Card จาก Database (Unified Routine Cards แบบใหม่) ---
  Widget _buildRoutineCardFromDb(Map<String, dynamic> routine, int index) {
    final routineId = (routine['nRoutineId'] as num?)?.toInt() ?? 0;
    final title = routine['sTitle']?.toString() ?? 'ไม่มีชื่อ';

    IconData icon = _getRoutineIcon(index);
    if (routine['iconData'] != null) {
      final int codePoint = (routine['iconData'] as num).toInt();
      // ignore: non_const_argument_for_const_parameter
      icon = IconData(codePoint, fontFamily: 'MaterialIcons');
    }

    final targetVal = (routine['targetValue'] as num?)?.toDouble() ?? 1.0;
    final unitText = routine['unit']?.toString() ?? 'ครั้ง';
    final lowerTitle = title.toLowerCase();

    // ดึงประเภทการออกกำลังกายที่เชื่อมไว้
    String matchedType = routine['sLinkedWorkout']?.toString() ?? '';
    if (matchedType.isEmpty) {
      if (lowerTitle.contains('วิ่ง')) matchedType = 'วิ่ง';
      else if (lowerTitle.contains('เดิน')) matchedType = 'เดิน';
      else if (lowerTitle.contains('จักรยาน') || lowerTitle.contains('ปั่น')) matchedType = 'ปั่นจักรยาน';
      else if (lowerTitle.contains('ลู่วิ่ง')) matchedType = 'ลู่วิ่งในร่ม';
    }

    final bool isWorkoutRoutine = matchedType.isNotEmpty ||
        lowerTitle.contains('วิ่ง') ||
        lowerTitle.contains('เดิน') ||
        lowerTitle.contains('จักรยาน') ||
        lowerTitle.contains('ปั่น') ||
        lowerTitle.contains('ลู่วิ่ง');

    double? workoutCurrentVal;
    if (matchedType.isNotEmpty && _todayWorkoutStats.containsKey(matchedType)) {
      final stats = _todayWorkoutStats[matchedType]!;
      if (unitText.contains('กม') || unitText.contains('กิโล') || unitText.contains('km')) {
        workoutCurrentVal = stats['distance'];
      } else if (unitText.contains('นาที') || unitText.contains('min') || unitText.contains('เวลา') || unitText.contains('ชม')) {
        workoutCurrentVal = stats['duration'];
      }
    }

    final isManuallyCompleted = _todayCompletionMap[routineId] ?? false;
    final double accumulatedVal = _todayProgressValues[routineId] ?? (isManuallyCompleted ? targetVal : 0.0);
    final currentVal = workoutCurrentVal ?? accumulatedVal;
    final bool isActuallyCompleted = currentVal >= targetVal || isManuallyCompleted;

    final double progressRatio = targetVal > 0 ? (currentVal / targetVal).clamp(0.0, 1.0) : 0.0;
    final int percent = (progressRatio * 100).toInt();

    String formatValue(double val) =>
        val == val.toInt() ? val.toInt().toString() : val.toStringAsFixed(1);

    final buttonType = _getRoutineButtonType(routine, isWorkoutRoutine);

    Widget actionButton;
    if (buttonType == RoutineButtonType.workout) {
      actionButton = ElevatedButton.icon(
        onPressed: () {
          if (widget.onNavigateToWorkout != null) {
            widget.onNavigateToWorkout!(matchedType);
          }
        },
        icon: const Icon(Icons.play_arrow_rounded, size: 16, color: Colors.white),
        label: const Text(
          'เริ่มเลย',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2E5327), // Forest Green #2E5327
          elevation: 1,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } else if (isActuallyCompleted) {
      actionButton = InkWell(
        onTap: () async {
          setState(() {
            _todayProgressValues[routineId] = 0.0;
          });
          await _toggleRoutineCompletion(routineId);
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF2E5327),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_rounded, size: 14, color: Colors.white),
              const SizedBox(width: 4),
              Text(
                buttonType == RoutineButtonType.stepAdd ? '✓ ครบแล้ว' : '✓ เสร็จแล้ว',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    } else if (buttonType == RoutineButtonType.stepAdd) {
      final stepAmount = _calculateStepAmount(targetVal, unitText);
      final stepStr = formatValue(stepAmount);
      actionButton = InkWell(
        onTap: () => _incrementRoutineValue(routineId, stepAmount, targetVal),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F3EB),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFCBE3D3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add_rounded, size: 14, color: Color(0xFF2E5327)),
              const SizedBox(width: 3),
              Text(
                '+$stepStr $unitText',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E5327),
                ),
              ),
            ],
          ),
        ),
      );
    } else if (buttonType == RoutineButtonType.timer) {
      final durationMin = targetVal > 0 ? targetVal.toInt() : 15;
      actionButton = InkWell(
        onTap: () => _showCountdownTimerDialog(context, routine, durationMin),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F3EB),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFCBE3D3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.timer_outlined, size: 14, color: Color(0xFF2E5327)),
              const SizedBox(width: 4),
              Text(
                '⏱️ $durationMin นาที',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E5327),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      actionButton = InkWell(
        onTap: () => _toggleRoutineCompletion(routineId),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF2E5327).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_task_rounded, size: 14, color: Color(0xFF2E5327)),
              SizedBox(width: 4),
              Text(
                'บันทึก',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E5327),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20), // ขอบมน 20px
        border: Border.all(color: const Color(0xFFE2E9E0), width: 1.2), // ขอบอ่อน #E2E9E0
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ไอคอนทรงกลมพื้นหลังสีเขียวอ่อน #E8F3EB
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F3EB),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFCBE3D3)),
                ),
                child: Icon(icon, color: const Color(0xFF2E5327), size: 24),
              ),
              const SizedBox(width: 14),

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
                              fontSize: 15.5,
                              color: Color(0xFF1E281F),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E5327).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$percent%',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2E5327),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Badge "⚡ Auto-GPS Sync" สำหรับ Active Workout Routines
                    if (isWorkoutRoutine) ...[
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.orange.shade200),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.bolt_rounded, size: 12, color: Colors.orange.shade800),
                                const SizedBox(width: 2),
                                Text(
                                  'Auto-GPS Sync',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange.shade900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'เป้าหมาย: ${formatValue(targetVal)} $unitText',
                              style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      Text(
                        'เป้าหมายประจำวัน: ${formatValue(targetVal)} $unitText',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ],
                ),
              ),

              // ปุ่ม Action ด้านขวา (ปุ่มลัดเริ่มเลย สำหรับ Workout หรือ ปุ่ม dynamic ตามประเภท)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  actionButton,
                  const SizedBox(width: 2),
                  _buildThreeDotsMenu(
                    onEdit: () => _editRoutine(routine),
                    onDelete: () => _deleteRoutine(routineId, title),
                    onPinAsMainGoal: () => _pinAsMainGoal(routine),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Progress bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ความคืบหน้า',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
              Text(
                '${formatValue(currentVal)} / ${formatValue(targetVal)} $unitText ($percent%)',
                style: const TextStyle(
                  fontSize: 11.5,
                  color: Color(0xFF2E5327),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progressRatio,
              minHeight: 7,
              backgroundColor: const Color(0xFFE2E9E0),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2E5327)),
            ),
          ),
        ],
      ),
    );
  }
}

enum RoutineButtonType {
  workout,
  stepAdd,
  timer,
  singleCheck,
}

/// Mini Countdown Timer Dialog Widget
class _RoutineCountdownTimerModal extends StatefulWidget {
  final String title;
  final int durationMinutes;
  final VoidCallback onTimerCompleted;

  const _RoutineCountdownTimerModal({
    required this.title,
    required this.durationMinutes,
    required this.onTimerCompleted,
  });

  @override
  State<_RoutineCountdownTimerModal> createState() => _RoutineCountdownTimerModalState();
}

class _RoutineCountdownTimerModalState extends State<_RoutineCountdownTimerModal> {
  late int _secondsRemaining;
  late int _totalSeconds;
  Timer? _timer;
  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
    _totalSeconds = widget.durationMinutes * 60;
    if (_totalSeconds <= 0) _totalSeconds = 60;
    _secondsRemaining = _totalSeconds;
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _isRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsRemaining > 1) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _timer?.cancel();
        setState(() {
          _secondsRemaining = 0;
          _isRunning = false;
        });
        Navigator.of(context).pop();
        widget.onTimerCompleted();
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() => _isRunning = false);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _formattedTime {
    final minutes = (_secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsRemaining % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final double progress = _totalSeconds > 0 ? (1.0 - (_secondsRemaining / _totalSeconds)) : 1.0;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8F3EB),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.timer_rounded, color: Color(0xFF2E5327), size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'จับเวลาโฟกัส',
                        style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        widget.title,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E281F)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Circular Countdown Display
            SizedBox(
              width: 180,
              height: 180,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 180,
                    height: 180,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 10,
                      backgroundColor: const Color(0xFFE2E9E0),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2E5327)),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _formattedTime,
                        style: const TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF2E5327),
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isRunning ? 'กำลังจับเวลา...' : 'พักชั่วคราว',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _isRunning ? const Color(0xFF2E5327) : Colors.orange.shade800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Play / Pause Button
                ElevatedButton.icon(
                  onPressed: _isRunning ? _pauseTimer : _startTimer,
                  icon: Icon(_isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white),
                  label: Text(_isRunning ? 'พักชั่วคราว' : 'เริ่มต่อ', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E5327),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),

                // Finish early button
                OutlinedButton.icon(
                  onPressed: () {
                    _timer?.cancel();
                    Navigator.of(context).pop();
                    widget.onTimerCompleted();
                  },
                  icon: const Icon(Icons.check_circle_outline, color: Color(0xFF2E5327)),
                  label: const Text('เสร็จแล้ว', style: TextStyle(color: Color(0xFF2E5327), fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    side: const BorderSide(color: Color(0xFF2E5327), width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

