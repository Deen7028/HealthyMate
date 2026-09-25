import 'package:flutter/material.dart';
import 'package:healthymate/core/database/app_database.dart';
import 'package:healthymate/core/services/api_service.dart';
import 'package:healthymate/features/health_calculator/models/user_model.dart';
import 'package:healthymate/features/health_calculator/models/health_record_model.dart';
import '../widgets/index.dart';
import '../controllers/dashboard_controller.dart';

class DashboardPageUpdated extends StatefulWidget {
  final bool isActive;
  final VoidCallback? onNavigateToCalculator;
  final VoidCallback? onNavigateToPractice;
  final VoidCallback? onNavigateToWorkout;
  final VoidCallback? onStartWorkout;

  const DashboardPageUpdated({
    super.key,
    this.isActive = true,
    this.onNavigateToCalculator,
    this.onNavigateToPractice,
    this.onNavigateToWorkout,
    this.onStartWorkout,
  });

  @override
  State<DashboardPageUpdated> createState() => _DashboardPageUpdatedState();
}

class _DashboardPageUpdatedState extends State<DashboardPageUpdated> {
  // สีหลักอ้างอิงจากดีไซน์
  final Color primaryGreen = const Color(0xFF0F9C58);
  final Color darkGreen = const Color(0xFF006432);
  final Color lightBg = const Color(0xFFF7F9FB);

  // ---------- Database-driven state ----------
  bool _isLoading = true;
  TbUser? _user;
  TbHealthRecord? _latestRecord;
  int _workoutCount = 0;
  double _totalDistanceKm = 0.0;
  double _totalCaloriesBurned = 0.0;
  Map<String, dynamic>? _userGoal;

  // กิจวัตรและสถิติที่เกี่ยวข้อง
  List<Map<String, dynamic>> _routines = [];
  Map<int, bool> _todayCompletionMap = {};
  Map<String, Map<String, double>> _todayWorkoutStats = {};

  // วันในสัปดาห์ปัจจุบัน
  final DateTime _now = DateTime.now();

  @override
  void didUpdateWidget(covariant DashboardPageUpdated oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _loadDashboardData();
    }
  }

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      final db = AppDatabase.instance;

      // 1. หา userId จาก Session
      final email = await db.getLoggedInUserEmail();
      TbUser? user;
      if (email != null && email.isNotEmpty) {
        user = await db.getUserByEmail(email);
      }
      user ??= await db.getUser(userId: 1);

      if (user == null) {
        debugPrint('[Dashboard] ❌ ไม่พบข้อมูลผู้ใช้ใน DB');
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final userId = user.nUserId;
      debugPrint(
        '[Dashboard] ✅ โหลดข้อมูลผู้ใช้: ${user.sFullName} (ID=$userId)',
      );

      // 2. ดึง Health Record ล่าสุด
      final records = await db.getHealthRecords(userId: userId);
      final latestRecord = records.isNotEmpty ? records.first : null;
      debugPrint('[Dashboard] 📋 HealthRecords: ${records.length} รายการ');

      // 3. ดึงข้อมูล Workouts
      final workouts = await db.getWorkouts(userId: userId);
      final workoutCount = workouts.length;
      double totalDist = 0.0;
      double totalCal = 0.0;
      for (final w in workouts) {
        totalDist += (w['nDistance'] as num?)?.toDouble() ?? 0.0;
        totalCal += (w['nCaloriesBurned'] as num?)?.toDouble() ?? 0.0;
      }
      debugPrint(
        '[Dashboard] 🏃 Workouts: $workoutCount | ระยะทาง: ${totalDist.toStringAsFixed(1)} km | แคล: ${totalCal.toStringAsFixed(0)}',
      );

      // 4. ดึง Nutrition วันนี้
      final nutritionToday = await db.getNutritionLogsToday(userId);
      int todayCal = 0;
      for (final n in nutritionToday) {
        todayCal += (n['nCalories'] as num?)?.toInt() ?? 0;
      }
      debugPrint(
        '[Dashboard] 🍽️ Nutrition วันนี้: $todayCal kcal (${nutritionToday.length} รายการ)',
      );

      // 5. ดึงข้อมูล Routines และ Completion สำหรับวันนี้
      final routines = await db.getRoutines(userId: userId);
      final todayStr =
          '${_now.year}-${_now.month.toString().padLeft(2, '0')}-${_now.day.toString().padLeft(2, '0')}';
      final Map<int, bool> completionMap = {};
      for (final r in routines) {
        final rId = (r['nRoutineId'] as num?)?.toInt() ?? 0;
        final log = await db.getRoutineLogForDate(
          routineId: rId,
          dateStr: todayStr,
        );
        completionMap[rId] = (log?['isCompleted'] as num?)?.toInt() == 1;
      }

      // 6. แยกข้อมูล Workout วันนี้สำหรับ Routines ที่ลิงก์ไว้
      final Map<String, Map<String, double>> todayStats = {};
      for (final w in workouts) {
        final workoutDate = w['dtWorkoutDate']?.toString() ?? '';
        if (workoutDate.startsWith(todayStr)) {
          final type = w['sType']?.toString() ?? 'อื่นๆ';
          final dist = (w['nDistance'] as num?)?.toDouble() ?? 0.0;
          final duration = (w['nDuration'] as num?)?.toDouble() ?? 0.0;
          if (!todayStats.containsKey(type)) {
            todayStats[type] = {'distance': 0.0, 'duration': 0.0};
          }
          todayStats[type]!['distance'] =
              (todayStats[type]!['distance'] ?? 0) + dist;
          todayStats[type]!['duration'] =
              (todayStats[type]!['duration'] ?? 0) + duration;
        }
      }

      // 7. ดึงเป้าหมายหลัก
      final goal = await db.getUserGoal(userId);
      debugPrint('[Dashboard] 🎯 Goal: ${goal?['sTitle'] ?? 'ยังไม่มี'}');

      if (mounted) {
        setState(() {
          _user = user;
          _latestRecord = latestRecord;
          _workoutCount = workoutCount;
          _totalDistanceKm = totalDist;
          _totalCaloriesBurned = totalCal;
          _routines = routines;
          _todayCompletionMap = completionMap;
          _todayWorkoutStats = todayStats;
          _userGoal = goal;
          _isLoading = false;
        });
      }

      // 6. Sync จาก Server (background - ไม่ block UI)
      _syncFromServer(userId);
    } catch (e, stack) {
      debugPrint('[Dashboard] ❌ Error loading data: $e');
      debugPrint('[Dashboard] Stack: $stack');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// ดึงข้อมูลจาก Server แบบ background แล้วอัปเดต UI ถ้ามีข้อมูลใหม่
  Future<void> _syncFromServer(int userId) async {
    try {
      debugPrint('[Dashboard] 🌐 กำลังซิงค์จาก Server...');
      final serverData = await HealthApiService.fetchDashboardData(
        userId: userId,
      );

      if (serverData == null) {
        debugPrint('[Dashboard] 🌐 Server ไม่ตอบ — ใช้ข้อมูล Local');
        return;
      }

      debugPrint('[Dashboard] 🌐 ✅ ได้ข้อมูลจาก Server สำเร็จ');

      // แกะข้อมูล workout stats จาก server
      final wsMap = serverData['workoutStats'] as Map<String, dynamic>?;
      final serverWorkoutCount = (wsMap?['totalCount'] as num?)?.toInt() ?? 0;
      final serverDistance =
          (wsMap?['totalDistance'] as num?)?.toDouble() ?? 0.0;
      final serverCalories =
          (wsMap?['totalCalories'] as num?)?.toDouble() ?? 0.0;

      // แกะ goal
      final goalMap = serverData['goal'] as Map<String, dynamic>?;

      // แกะ health record
      final hrMap = serverData['latestHealthRecord'] as Map<String, dynamic>?;
      TbHealthRecord? serverRecord;
      if (hrMap != null) {
        serverRecord = TbHealthRecord.fromMap(hrMap);
      }

      // แกะ user
      final userMap = serverData['user'] as Map<String, dynamic>?;
      TbUser? serverUser;
      if (userMap != null) {
        serverUser = TbUser.fromMap(userMap);
      }

      // ซิงค์ข้อมูลกับ UI โดยอัปเดตจาก Server (ไม่ใช้บังคับเลือกค่าที่มากกว่า เพื่อเปิดให้ผู้ใช้ลบรายการได้)
      if (mounted) {
        setState(() {
          if (serverUser != null) _user = serverUser;
          if (serverRecord != null) _latestRecord = serverRecord;
          _workoutCount = serverWorkoutCount;
          _totalDistanceKm = serverDistance;
          _totalCaloriesBurned = serverCalories;
          if (goalMap != null) _userGoal = goalMap;
        });
        debugPrint('[Dashboard] 🌐 ✅ อัปเดต UI จาก Server เรียบร้อย');
      }
    } catch (e) {
      debugPrint('[Dashboard] 🌐 ❌ Sync error (ใช้ local data): $e');
    }
  }

  void _handleStartWorkout() {
    if (widget.onNavigateToWorkout != null) {
      widget.onNavigateToWorkout!();
    } else if (widget.onStartWorkout != null) {
      widget.onStartWorkout!();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('กำลังเข้าสู่โหมดมินิมาราธอน... 🏃‍♂️'),
          backgroundColor: darkGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ---------- Greeting ตามเวลา ----------
  String _getGreeting() {
    final hour = _now.hour;
    if (hour < 12) return 'อรุณสวัสดิ์';
    if (hour < 17) return 'สวัสดีตอนบ่าย';
    return 'สวัสดีตอนเย็น';
  }

  String _getGreetingEmoji() {
    final hour = _now.hour;
    if (hour < 12) return '☀️';
    if (hour < 17) return '🌤️';
    return '🌙';
  }

  // ---------- สัปดาห์ปัจจุบัน ----------
  int get _weekOfMonth {
    final firstDayOfMonth = DateTime(_now.year, _now.month, 1);
    return ((_now.day + firstDayOfMonth.weekday - 2) / 7).ceil();
  }

  String get _thaiDayName {
    const days = [
      'จันทร์',
      'อังคาร',
      'พุธ',
      'พฤหัสบดี',
      'ศุกร์',
      'เสาร์',
      'อาทิตย์',
    ];
    return days[_now.weekday - 1];
  }

  String get _thaiMonthName {
    const months = [
      'มกราคม',
      'กุมภาพันธ์',
      'มีนาคม',
      'เมษายน',
      'พฤษภาคม',
      'มิถุนายน',
      'กรกฎาคม',
      'สิงหาคม',
      'กันยายน',
      'ตุลาคม',
      'พฤศจิกายน',
      'ธันวาคม',
    ];
    return months[_now.month - 1];
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: lightBg,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: primaryGreen),
              const SizedBox(height: 16),
              Text(
                'กำลังโหลดข้อมูลสุขภาพ...',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: lightBg, // สีพื้นหลังโทนสว่าง
      body: SafeArea(
        child: RefreshIndicator(
          color: primaryGreen,
          onRefresh: _loadDashboardData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Top Header
                  _buildHeader(),
                  const SizedBox(height: 24),

                  // 2. แถบปฏิทินกิจวัตรประจำสัปดาห์ (Calendar Strip)
                  _buildCalendarStrip(),
                  const SizedBox(height: 20),

                  // 3. ข้อมูลสุขภาพส่วนบุคคล (Health Summary Card)
                  _buildHealthSummaryCard(),
                  const SizedBox(height: 20),

                  // 3. เป้าหมายหลักของฉัน (Main Goal Card)
                  _buildMainGoalCard(),
                  const SizedBox(height: 20),

                  // 4. ปุ่มลัดเริ่มออกกำลังกาย
                  _buildActionButtons(),
                  const SizedBox(height: 20),

                  // 5. เป้าหมายอื่นๆ (Other Goals & Routines)
                  _buildOtherGoalsCard(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- Widget ส่วนบน (Header) ---
  Widget _buildHeader() {
    return DashboardHeader(
      userName: _user?.sFirstName ?? 'ผู้ใช้งาน',
      profilePath: _user?.sProfileImagePath ?? '',
      thaiDayName: _thaiDayName,
      weekOfMonth: _weekOfMonth,
      greetingText: _getGreeting(),
      greetingEmoji: _getGreetingEmoji(),
      primaryGreen: primaryGreen,
      darkGreen: darkGreen,
    );
  }

  // --- Calendar Strip ---
  Widget _buildCalendarStrip() {
    return CalendarStripWidget(
      now: _now,
      thaiMonthName: _thaiMonthName,
      workoutCount: _workoutCount,
      totalDistanceKm: _totalDistanceKm,
      totalCaloriesBurned: _totalCaloriesBurned,
      darkGreen: darkGreen,
    );
  }

  // --- Widget การ์ดข้อมูลสุขภาพ (Card 1) ---
  Widget _buildHealthSummaryCard() {
    return DashboardHealthSummaryCard(
      user: _user,
      latestRecord: _latestRecord,
      now: _now,
      totalCaloriesBurned: _totalCaloriesBurned,
      onNavigateToCalculator: widget.onNavigateToCalculator,
      primaryGreen: primaryGreen,
      darkGreen: darkGreen,
    );
  }

  // --- Widget การ์ดเป้าหมายหลัก (Card 2) ---
  Widget _buildMainGoalCard() {
    final controller = DashboardController()
      ..userGoal = _userGoal
      ..routines = _routines
      ..todayCompletionMap = _todayCompletionMap
      ..todayWorkoutStats = _todayWorkoutStats;

    return MainGoalCard(
      controller: controller,
      onNavigateToPractice: widget.onNavigateToPractice,
    );
  }

  // --- Widget ปุ่ม Action (Start Workout) ---
  Widget _buildActionButtons() {
    return DashboardActionButtons(
      userGoal: _userGoal,
      onStartWorkout: _handleStartWorkout,
      onNavigateToWorkout: widget.onNavigateToWorkout,
      darkGreen: darkGreen,
    );
  }

  // --- Widget เป้าหมายอื่นๆ (Card 3) ---
  Widget _buildOtherGoalsCard() {
    return DashboardOtherGoalsCard(
      userGoal: _userGoal,
      routines: _routines,
      todayCompletionMap: _todayCompletionMap,
      todayWorkoutStats: _todayWorkoutStats,
      now: _now,
      darkGreen: darkGreen,
      lightBg: lightBg,
      onNavigateToPractice: widget.onNavigateToPractice,
      onRoutineToggled: (routineId, isDone) {
        setState(() {
          _todayCompletionMap[routineId] = isDone;
        });
      },
    );
  }
}