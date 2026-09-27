import 'dart:async';
import 'package:flutter/material.dart';
import 'package:healthymate/core/services/routine_state_notifier.dart';
import '../models/routine_item.dart';
import '../widgets/index.dart';
import '../controllers/routine_controller.dart';

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
  late final RoutineController _controller;

  final Color primaryGreen = const Color(0xFF0F9C58);
  final Color darkGreen = const Color(0xFF006432);
  final Color lightBg = const Color(0xFFF7F9FB);
  final Color cardGreenBg = const Color(0xFFE8F5E9);

  @override
  void initState() {
    super.initState();
    _controller = RoutineController()..loadData();
    RoutineStateNotifier.instance.addListener(_onStateChanged);
  }

  void _onStateChanged() {
    if (mounted) {
      _controller.loadData();
    }
  }

  @override
  void didUpdateWidget(covariant MyRoutinesPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _controller.loadData();
    }
  }

  @override
  void dispose() {
    RoutineStateNotifier.instance.removeListener(_onStateChanged);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openAddMainGoalBottomSheet() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => const AddMainGoalBottomSheet(),
    );

    if (result != null) {
      await _controller.setCustomMainGoal(
        title: result['title']?.toString() ?? '',
        icon: result['icon']?.toString() ?? '🚩',
        unit: result['unit']?.toString() ?? '',
        targetValue: (result['targetValue'] as num?)?.toDouble() ?? 1.0,
        linkedWorkout: result['linkedWorkout']?.toString() ?? '',
        deadlineDate: result['deadlineDate'] as DateTime? ?? DateTime.now().add(const Duration(days: 30)),
      );
      _showSnackBar('ตั้งเป้าหมายหลัก "${result['title']}" เรียบร้อย!');
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

    if (newRoutine != null) {
      await _controller.addRoutine(newRoutine);
      _showSnackBar('เพิ่ม "${newRoutine.title}" ในกิจวัตรสำเร็จ!');
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
      await _controller.deleteRoutine(routineId, title);
      _showSnackBar('ลบ "$title" เรียบร้อย');
    }
  }

  Future<void> _editRoutine(Map<String, dynamic> routine) async {
    final routineId = (routine['nRoutineId'] as num?)?.toInt() ?? 0;

    final RoutineItem? updatedRoutine = await showModalBottomSheet<RoutineItem>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => AddRoutineDialog(initialRoutine: routine),
    );

    if (updatedRoutine != null) {
      await _controller.editRoutine(routineId, updatedRoutine);
      _showSnackBar('อัปเดตกิจวัตรเรียบร้อยแล้ว');
    }
  }

  RoutineButtonType _getRoutineButtonType(
    Map<String, dynamic> routine,
    bool isWorkoutRoutine,
  ) {
    if (isWorkoutRoutine) return RoutineButtonType.workout;

    final unit = (routine['unit']?.toString() ?? '').toLowerCase();
    final title = (routine['sTitle']?.toString() ?? '').toLowerCase();
    final targetVal = (routine['targetValue'] as num?)?.toDouble() ?? 1.0;

    if (unit.contains('นาที') ||
        unit.contains('min') ||
        unit.contains('ชม') ||
        unit.contains('hr') ||
        title.contains('สมาธิ') ||
        title.contains('หายใจ') ||
        title.contains('โฟกัส')) {
      return RoutineButtonType.timer;
    }

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
    if (u.contains('มื้อ') ||
        u.contains('แก้ว') ||
        u.contains('จาน') ||
        u.contains('ครั้ง') ||
        u.contains('หน้า')) {
      return 1.0;
    }
    if (targetVal <= 5) return 1.0;
    if (targetVal <= 20) return 2.0;
    return (targetVal / 4).roundToDouble().clamp(1.0, targetVal);
  }

  void _showCountdownTimerDialog(
    BuildContext context,
    Map<String, dynamic> routine,
    int durationMinutes,
  ) {
    final title = routine['sTitle']?.toString() ?? 'จับเวลาทำกิจกรรม';
    final routineId = (routine['nRoutineId'] as num?)?.toInt() ?? 0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return RoutineCountdownTimerModal(
          title: title,
          durationMinutes: durationMinutes,
          onTimerCompleted: () async {
            if (mounted) {
              await _controller.toggleRoutineCompletion(routineId);
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

  IconData _getRoutineIcon(int index) =>
      _routineIcons[index % _routineIcons.length];

  String _getTimeBlock(String? time) {
    if (time == null || time.isEmpty) return 'other';
    final match = RegExp(r'(\d{1,2})[:\.](\d{2})').firstMatch(time);
    if (match != null) {
      final hour = int.tryParse(match.group(1) ?? '') ?? 12;
      if (hour < 12) return 'morning';
      if (hour < 18) return 'afternoon';
      return 'night';
    }
    if (time.contains('เช้า') || time.contains('Morning')) return 'morning';
    if (time.contains('บ่าย') || time.contains('Afternoon')) return 'afternoon';
    if (time.contains('เย็น') || time.contains('คืน') || time.contains('Night')) {
      return 'night';
    }
    return 'other';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        if (_controller.isLoading) {
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

        final pinnedRoutineId = (_controller.userGoal?['nRoutineId'] as num?)?.toInt() ?? 0;
        final pinnedTitle = _controller.userGoal?['sTitle']?.toString() ?? '';

        final displayRoutines = _controller.routines.where((r) {
          final rId = (r['nRoutineId'] as num?)?.toInt() ?? 0;
          final rTitle = r['sTitle']?.toString() ?? '';
          if (pinnedRoutineId > 0 && rId == pinnedRoutineId) return false;
          if (pinnedRoutineId == 0 && pinnedTitle.isNotEmpty && rTitle == pinnedTitle) return false;
          return true;
        }).toList();

        final displayCompletedCount = displayRoutines.where((r) {
          final rId = (r['nRoutineId'] as num?)?.toInt() ?? 0;
          return _controller.todayCompletionMap[rId] ?? false;
        }).length;

        final morningRoutines = <Map<String, dynamic>>[];
        final afternoonRoutines = <Map<String, dynamic>>[];
        final nightRoutines = <Map<String, dynamic>>[];
        final otherRoutines = <Map<String, dynamic>>[];

        for (final r in displayRoutines) {
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
              onRefresh: _controller.loadData,
              child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RoutineTopOverviewBanner(
                      completedCount: displayCompletedCount,
                      totalCount: displayRoutines.length,
                      todayWorkoutStats: _controller.todayWorkoutStats,
                      overallProgressRatio: _controller.overallProgressRatio,
                    ),
                    const SizedBox(height: 20),

                    RoutineMainGoalCard(
                      userGoal: _controller.userGoal,
                      completedCount: displayCompletedCount,
                      totalRoutinesCount: displayRoutines.length,
                      onSetMainGoal: _openAddMainGoalBottomSheet,
                      onUnpin: () async {
                        await _controller.unpinMainGoal();
                        _showSnackBar('ยกเลิกการปักหมุดเป้าหมายหลักแล้ว');
                      },
                      cardGreenBg: cardGreenBg,
                      primaryGreen: primaryGreen,
                      darkGreen: darkGreen,
                    ),


                    _buildDailyRoutinesHeader(),
                    const SizedBox(height: 16),
                    if (displayRoutines.isEmpty) _buildEmptyState(),

                    if (morningRoutines.isNotEmpty) ...[
                      _buildTimeBlockHeader(
                        '☀️ ช่วงเช้า (Morning)',
                        '06:00 - 11:00',
                      ),
                      ...morningRoutines.map(
                        (r) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildRoutineCardFromDb(r, displayRoutines.indexOf(r)),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],

                    if (afternoonRoutines.isNotEmpty) ...[
                      _buildTimeBlockHeader(
                        '🏃 ระหว่างวัน (Afternoon)',
                        '12:00 - 18:00',
                      ),
                      ...afternoonRoutines.map(
                        (r) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildRoutineCardFromDb(r, displayRoutines.indexOf(r)),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],

                    if (nightRoutines.isNotEmpty) ...[
                      _buildTimeBlockHeader('🌙 ก่อนนอน (Night)', '21:00 - 23:00'),
                      ...nightRoutines.map(
                        (r) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildRoutineCardFromDb(r, displayRoutines.indexOf(r)),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],

                    if (otherRoutines.isNotEmpty) ...[
                      _buildTimeBlockHeader('⭐ กิจวัตรอื่นๆ', 'ตลอดทั้งวัน'),
                      ...otherRoutines.map(
                        (r) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildRoutineCardFromDb(r, displayRoutines.indexOf(r)),
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
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final userName = _controller.user?.sFirstName ?? 'ผู้ใช้งาน';
    final profilePath = _controller.user?.sProfileImagePath ?? '';

    ImageProvider? imageProvider;
    if (profilePath.isNotEmpty) {
      if (profilePath.startsWith('http')) {
        imageProvider = NetworkImage(profilePath);
      }
    }

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
            backgroundImage: imageProvider,
            child: imageProvider == null
                ? Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
        ),
      ],
    );
  }


  Widget _buildEmptyState() {
    return const RoutineEmptyView();
  }

  Widget _buildDailyRoutinesHeader() {
    int timeBlockCount = 0;
    final times = _controller.routines
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
          _controller.routines.isEmpty ? 'ยังไม่มี' : '$timeBlockCount ช่วง\nเวลา',
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

  Widget _buildRoutineCardFromDb(Map<String, dynamic> routine, int index) {
    final routineId = (routine['nRoutineId'] as num?)?.toInt() ?? 0;
    final title = routine['sTitle']?.toString() ?? 'ไม่มีชื่อ';

    IconData icon = _getRoutineIcon(index);
    if (routine['iconData'] != null) {
      final int codePoint = (routine['iconData'] as num).toInt();
      // ignore: non_const_argument_for_const_parameter
      icon = IconData(codePoint, fontFamily: 'MaterialIcons');
    }

    final targetVal = (routine['targetValue'] as num?)?.toDouble() ?? 
                      (routine['nTargetValue'] as num?)?.toDouble() ?? 1.0;
    final unitText = routine['unit']?.toString() ?? 
                     routine['sUnit']?.toString() ?? 'ครั้ง';
    final lowerTitle = title.toLowerCase();

    const workoutKeywords = ['วิ่ง', 'เดิน', 'ปั่นจักรยาน', 'จักรยาน', 'ลู่วิ่ง', 'คาร์ดิโอ', 'ออกกำลังกาย'];
    final bool hasWorkoutKeyword = workoutKeywords.any((kw) => lowerTitle.contains(kw));
    final bool isNonWorkout = !hasWorkoutKeyword && (
        lowerTitle.contains('น้ำ') ||
        lowerTitle.contains('สมาธิ') ||
        lowerTitle.contains('นอน') ||
        lowerTitle.contains('กิน') ||
        lowerTitle.contains('อาหาร') ||
        lowerTitle.contains('ยา') ||
        lowerTitle.contains('อ่าน')
    );

    String matchedType = routine['sLinkedWorkout']?.toString() ?? '';
    if (matchedType.isEmpty && !isNonWorkout) {
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

    final bool isWorkoutRoutine = !isNonWorkout &&
        (matchedType.isNotEmpty ||
            workoutKeywords.any((kw) => lowerTitle.contains(kw)));

    double? workoutCurrentVal;
    if (isWorkoutRoutine &&
        matchedType.isNotEmpty &&
        _controller.todayWorkoutStats.containsKey(matchedType)) {
      final stats = _controller.todayWorkoutStats[matchedType]!;
      if (unitText.contains('กม') ||
          unitText.contains('กิโล') ||
          unitText.contains('km')) {
        workoutCurrentVal = stats['distance'];
      } else if (unitText.contains('ชม') ||
          unitText.contains('ชั่วโมง') ||
          unitText.contains('hour') ||
          unitText.contains('hr')) {
        workoutCurrentVal = (stats['duration'] ?? 0.0) / 60.0;
      } else if (unitText.contains('นาที') ||
          unitText.contains('min') ||
          unitText.contains('เวลา')) {
        workoutCurrentVal = stats['duration'];
      } else if (unitText.contains('แคล') || unitText.contains('cal')) {
        workoutCurrentVal = stats['caloriesBurned'];
      }
    }

    final isManuallyCompleted = _controller.todayCompletionMap[routineId] ?? false;
    final double accumulatedVal =
        _controller.todayProgressValues[routineId] ??
        (isManuallyCompleted ? targetVal : 0.0);
    final currentVal = workoutCurrentVal ?? accumulatedVal;
    final bool isActuallyCompleted =
        currentVal >= targetVal || isManuallyCompleted;

    final double progressRatio = targetVal > 0
        ? (currentVal / targetVal).clamp(0.0, 1.0)
        : 0.0;
    final int percent = (progressRatio * 100).toInt();

    String formatValue(double val) =>
        val == val.toInt() ? val.toInt().toString() : val.toStringAsFixed(2);

    final buttonType = _getRoutineButtonType(routine, isWorkoutRoutine);

    Color cardColor = const Color(0xFF2E5327);
    final colorVal = (routine['color'] as num?)?.toInt() ?? (routine['nColor'] as num?)?.toInt();
    if (colorVal != null && colorVal != 0) {
      cardColor = Color(colorVal);
    }

    Widget actionButton;
    if (isActuallyCompleted) {
      actionButton = Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_rounded, size: 14, color: Colors.white),
            const SizedBox(width: 4),
            Text(
              buttonType == RoutineButtonType.stepAdd
                  ? ' ครบแล้ว'
                  : ' เสร็จแล้ว',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      );
    } else if (buttonType == RoutineButtonType.workout) {
      actionButton = ElevatedButton.icon(
        onPressed: () {
          if (widget.onNavigateToWorkout != null) {
            widget.onNavigateToWorkout!(matchedType);
          }
        },
        icon: const Icon(
          Icons.play_arrow_rounded,
          size: 16,
          color: Colors.white,
        ),
        label: const Text(
          'เริ่มเลย',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: cardColor,
          elevation: 1,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } else if (buttonType == RoutineButtonType.stepAdd) {

      final stepAmount = _calculateStepAmount(targetVal, unitText);
      final stepStr = formatValue(stepAmount);
      actionButton = InkWell(
        onTap: () => _controller.incrementRoutineValue(routineId, stepAmount),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: cardColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: cardColor.withValues(alpha: 0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_rounded, size: 14, color: cardColor),
              const SizedBox(width: 3),
              Text(
                '+$stepStr $unitText',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: cardColor,
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
            color: cardColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: cardColor.withValues(alpha: 0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.timer_outlined,
                size: 14,
                color: cardColor,
              ),
              const SizedBox(width: 4),
              Text(
                '⏱️ $durationMin นาที',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: cardColor,
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      actionButton = InkWell(
        onTap: () => _controller.toggleRoutineCompletion(routineId),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: cardColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_task_rounded, size: 14, color: cardColor),
              const SizedBox(width: 4),
              Text(
                'บันทึก',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: cardColor,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RoutineCardWidget(
      routine: routine,
      icon: icon,
      title: title,
      targetVal: targetVal,
      unitText: unitText,
      currentVal: currentVal,
      isWorkoutRoutine: isWorkoutRoutine,
      percent: percent,
      progressRatio: progressRatio,
      cardColor: cardColor,
      actionButton: actionButton,
      threeDotsMenu: _buildThreeDotsMenu(
        onEdit: () => _editRoutine(routine),
        onDelete: () => _deleteRoutine(routineId, title),
      ),
    );
  }
}