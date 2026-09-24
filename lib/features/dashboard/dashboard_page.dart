// ignore_for_file: non_const_argument_for_const_parameter
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:healthymate/shared/widgets/sync_status_badge.dart';
import 'package:healthymate/core/database/app_database.dart';
import 'package:healthymate/core/services/api_service.dart';
import 'package:healthymate/core/utils/health_calculator.dart';
import 'package:healthymate/features/health_calculator/models/user_model.dart';
import 'package:healthymate/features/health_calculator/models/health_record_model.dart';
import 'package:healthymate/features/health_calculator/models/activity_level.dart';

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
  int _totalWorkoutDurationSec = 0;
  int _todayNutritionCalories = 0;
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
      int totalDur = 0;
      for (final w in workouts) {
        totalDist += (w['nDistance'] as num?)?.toDouble() ?? 0.0;
        totalCal += (w['nCaloriesBurned'] as num?)?.toDouble() ?? 0.0;
        totalDur += (w['nDuration'] as num?)?.toInt() ?? 0;
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
          _totalWorkoutDurationSec = totalDur;
          _todayNutritionCalories = todayCal;
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
      final serverDuration = (wsMap?['totalDuration'] as num?)?.toInt() ?? 0;

      // แกะ nutrition วันนี้
      final ntMap = serverData['nutritionToday'] as Map<String, dynamic>?;
      final serverNutritionCal =
          (ntMap?['totalCalories'] as num?)?.toInt() ?? 0;

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

      // ใช้ค่าที่มากกว่า (Server อาจมีข้อมูลจากหลายเครื่อง)
      if (mounted) {
        setState(() {
          if (serverUser != null) _user = serverUser;
          if (serverRecord != null) _latestRecord = serverRecord;
          if (serverWorkoutCount > _workoutCount)
            _workoutCount = serverWorkoutCount;
          if (serverDistance > _totalDistanceKm)
            _totalDistanceKm = serverDistance;
          if (serverCalories > _totalCaloriesBurned)
            _totalCaloriesBurned = serverCalories;
          if (serverDuration > _totalWorkoutDurationSec)
            _totalWorkoutDurationSec = serverDuration;
          if (serverNutritionCal > _todayNutritionCalories)
            _todayNutritionCalories = serverNutritionCal;
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

  // ---------- Helper จัดรูปแบบตัวเลข ----------
  String _formatNumber(double val) {
    if (val >= 1000) {
      return NumberFormat('#,##0', 'th').format(val.round());
    }
    return val.toStringAsFixed(val.truncateToDouble() == val ? 0 : 1);
  }

  String _formatInt(int val) {
    return NumberFormat('#,##0', 'th').format(val);
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
    final userName = _user?.sFirstName ?? 'ผู้ใช้งาน';
    final profilePath = _user?.sProfileImagePath ?? '';

    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: primaryGreen.withValues(alpha: 0.2),
                    backgroundImage: profilePath.isNotEmpty
                        ? (profilePath.startsWith('http')
                              ? NetworkImage(profilePath)
                              : null)
                        : null,
                    child: profilePath.isEmpty
                        ? Text(
                            userName.isNotEmpty
                                ? userName[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              color: darkGreen,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'HealthyMate',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: primaryGreen,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(Icons.circle, color: primaryGreen, size: 8),
                          const SizedBox(width: 4),
                          Text(
                            'เข้าสู่วัน$_thaiDayName • สัปดาห์ที่ $_weekOfMonth',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  const SyncStatusBadge(),
                  const SizedBox(width: 6),
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () {},
                    color: Colors.black87,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          RichText(
            text: TextSpan(
              style: const TextStyle(color: Colors.black87, fontSize: 24),
              children: [
                TextSpan(
                  text:
                      '${_getGreeting()}, $userName! ${_getGreetingEmoji()}\n',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const TextSpan(
                  text: 'พร้อมออกไปวิ่งรับพลังงานและดูแลสุขภาพที่ดีหรือยัง?',
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Calendar Strip ---
  Widget _buildCalendarStrip() {
    // คำนวณวันในสัปดาห์ปัจจุบัน (จันทร์ - อาทิตย์)
    final monday = _now.subtract(Duration(days: _now.weekday - 1));
    final days = List.generate(7, (i) => monday.add(Duration(days: i)));
    const dayLabels = ['จ.', 'อ.', 'พ.', 'พฤ.', 'ศ.', 'ส.', 'อา.'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.blueGrey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'สัปดาห์นี้ • $_thaiMonthName ${_now.year + 543}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Text(
                      '🏃 ',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade400,
                      ),
                    ),
                    Text(
                      '$_workoutCount ครั้งออกกำลังกาย',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.orange.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Days Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final isToday =
                  days[i].day == _now.day &&
                  days[i].month == _now.month &&
                  days[i].year == _now.year;
              final isPast = days[i].isBefore(
                DateTime(_now.year, _now.month, _now.day),
              );
              return _buildDayItem(
                dayLabels[i],
                '${days[i].day}',
                isToday,
                isPast,
              );
            }),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.fitness_center,
                    size: 14,
                    color: Colors.teal,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'ออกกำลังกายแล้ว $_workoutCount ครั้ง | ${_totalDistanceKm.toStringAsFixed(1)} กม.',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.teal,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Text(
                '${_totalCaloriesBurned.toStringAsFixed(0)} kcal',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.teal,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDayItem(String day, String date, bool isSelected, bool isPast) {
    return Column(
      children: [
        Text(
          day,
          style: TextStyle(
            fontSize: 12,
            color: isSelected ? darkGreen : Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 32,
          height: 40,
          decoration: BoxDecoration(
            color: isSelected ? darkGreen : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              date,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 4,
          height: 4,
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.greenAccent
                : (isPast ? darkGreen : Colors.grey.shade300),
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }

  // --- Widget การ์ดข้อมูลสุขภาพ (Card 1) ---
  Widget _buildHealthSummaryCard() {
    // ดึงข้อมูลจาก user หรือ health record
    final weight = _latestRecord?.nWeight ?? _user?.nWeight ?? 0.0;
    final height = _latestRecord?.nHeight ?? _user?.nHeight ?? 0.0;
    final bmi =
        _latestRecord?.nBmi ??
        (weight > 0 && height > 0
            ? HealthCalculator.calculateBMI(weightKg: weight, heightCm: height)
            : 0.0);
    final bmiCategory = HealthCalculator.getBMICategory(bmi);

    // คำนวณ BMR / TDEE
    final age = _user?.nAge ?? 0;
    final gender = _user?.genderEnum ?? Gender.male;
    final activityLevel = _user?.activityLevelObj ?? ActivityLevel.options[1];

    double bmr = _latestRecord?.computedBmr ?? 0.0;
    double tdee = _latestRecord?.nTdee ?? 0.0;

    if (bmr <= 0 && weight > 0 && height > 0 && age > 0) {
      bmr = HealthCalculator.calculateBMR(
        gender: gender,
        weightKg: weight,
        heightCm: height,
        age: age,
      );
    }
    if (tdee <= 0 && bmr > 0) {
      tdee = HealthCalculator.calculateTDEE(
        bmr: bmr,
        activityMultiplier: activityLevel.multiplier,
      );
    }

    // เวลาที่คำนวณล่าสุด
    String lastRecordText = 'ยังไม่มีข้อมูล';
    if (_latestRecord != null) {
      final diff = _now.difference(_latestRecord!.dtRecordedAt);
      if (diff.inMinutes < 60) {
        lastRecordText = 'คำนวณล่าสุดเมื่อ ${diff.inMinutes} นาทีที่แล้ว';
      } else if (diff.inHours < 24) {
        lastRecordText = 'คำนวณล่าสุดเมื่อ ${diff.inHours} ชม. ที่แล้ว';
      } else {
        lastRecordText = 'คำนวณล่าสุดเมื่อ ${diff.inDays} วันที่แล้ว';
      }
    }

    // เป้าหมายเผาผลาญ (ถ้ามี TDEE จะคำนวณ ~20% ของ TDEE)
    final burnTarget = tdee > 0 ? (tdee * 0.2).round() : 400;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.health_and_safety, color: darkGreen),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ข้อมูลสุขภาพส่วนบุคคล',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        lastRecordText,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: widget.onNavigateToCalculator,
                icon: const Icon(Icons.sync, size: 16, color: Colors.blue),
                label: const Text(
                  'อัปเดตข้อมูล',
                  style: TextStyle(color: Colors.blue, fontSize: 12),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade50,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // สถิติย่อย 4 ช่อง
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem(
                'น้ำหนัก / ส่วนสูง',
                weight > 0
                    ? '${_formatNumber(weight)} กก. | ${_formatNumber(height)} ซม.'
                    : 'ยังไม่ระบุ',
              ),
              _buildStatItemWithBadge(
                'ดัชนีมวลกาย',
                bmi > 0 ? bmi.toStringAsFixed(1) : '-',
                bmi > 0 ? bmiCategory.badgeText : 'ยังไม่ระบุ',
                bmi > 0 ? bmiCategory.color : Colors.grey,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem(
                'BMR พลังงานพื้นฐาน',
                bmr > 0 ? '${_formatInt(bmr.round())} kcal' : '- kcal',
                icon: Icons.bolt,
              ),
              _buildStatItem(
                'TDEE ต้องการต่อวัน',
                tdee > 0 ? '${_formatInt(tdee.round())} kcal' : '- kcal',
                icon: Icons.local_fire_department,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // กล่องเป้าหมายเผาผลาญ
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.track_changes, color: primaryGreen),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'เป้าหมายเผาผลาญจากการออกกำลังกาย',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        'เผาผลาญแล้ววันนี้ ${_totalCaloriesBurned.toStringAsFixed(0)} kcal',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '$burnTarget\nkcal/วัน',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: primaryGreen,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Widget ย่อยสำหรับการ์ดข้อมูลสุขภาพ ---
  Widget _buildStatItem(String title, String value, {IconData? icon}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              if (icon != null) ...[
                const SizedBox(width: 4),
                Icon(icon, size: 14, color: Colors.orange),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItemWithBadge(
    String title,
    String value,
    String badgeText,
    Color badgeColor,
  ) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatNum(double val) =>
      val == val.toInt() ? val.toInt().toString() : val.toStringAsFixed(1);

  Color _getRoutineColor(Map<String, dynamic> routine, int index) {
    if (routine['color'] != null) {
      return Color((routine['color'] as num).toInt());
    }
    final title = routine['sTitle']?.toString().toLowerCase() ?? '';
    if (title.contains('น้ำ') ||
        title.contains('drink') ||
        title.contains('water')) {
      return const Color(0xFF0288D1);
    }
    if (title.contains('วิ่ง') ||
        title.contains('เดิน') ||
        title.contains('work')) {
      return const Color(0xFF4CAF50);
    }
    if (title.contains('สมาธิ') ||
        title.contains('นอน') ||
        title.contains('sleep')) {
      return const Color(0xFF7E57C2);
    }
    if (title.contains('อาหาร') ||
        title.contains('กิน') ||
        title.contains('eat')) {
      return const Color(0xFFFF9800);
    }
    if (title.contains('ยา') ||
        title.contains('pill') ||
        title.contains('health')) {
      return const Color(0xFFE91E63);
    }
    const defaultColors = [
      Color(0xFF0F9C58),
      Color(0xFF0288D1),
      Color(0xFFFF9800),
      Color(0xFF7E57C2),
      Color(0xFFE91E63),
    ];
    return defaultColors[index % defaultColors.length];
  }

  IconData _getRoutineIcon(Map<String, dynamic> routine, int index) {
    if (routine['iconData'] != null) {
      final int codePoint = (routine['iconData'] as num).toInt();
      return IconData(codePoint, fontFamily: 'MaterialIcons');
    }
    final title = routine['sTitle']?.toString().toLowerCase() ?? '';
    if (title.contains('น้ำ') ||
        title.contains('drink') ||
        title.contains('water')) {
      return Icons.water_drop_rounded;
    }
    if (title.contains('วิ่ง') ||
        title.contains('เดิน') ||
        title.contains('work')) {
      return Icons.directions_walk_rounded;
    }
    if (title.contains('สมาธิ') ||
        title.contains('นอน') ||
        title.contains('sleep')) {
      return Icons.self_improvement_rounded;
    }
    if (title.contains('อาหาร') ||
        title.contains('กิน') ||
        title.contains('eat')) {
      return Icons.restaurant_rounded;
    }
    if (title.contains('ยา') ||
        title.contains('pill') ||
        title.contains('health')) {
      return Icons.medical_services_rounded;
    }
    const defaultIcons = [
      Icons.flag_rounded,
      Icons.alarm_rounded,
      Icons.star_rounded,
      Icons.favorite_rounded,
    ];
    return defaultIcons[index % defaultIcons.length];
  }

  // --- Widget การ์ดเป้าหมายหลัก (Card 2) ---
  Widget _buildMainGoalCard() {
    // 1. ตรวจสอบว่ามีเป้าหมายที่ปักหมุดไว้หรือไม่
    final hasPinnedGoal = _userGoal != null;
    final pinnedRoutineId = (_userGoal?['nRoutineId'] as num?)?.toInt() ?? 0;

    // ค้นหากิจวัตรที่ตรงกับ ID ที่ปักหมุดไว้ (ถ้ามี)
    Map<String, dynamic>? pinnedRoutine;
    if (hasPinnedGoal) {
      for (final r in _routines) {
        final rId = (r['nRoutineId'] as num?)?.toInt() ?? 0;
        if ((pinnedRoutineId > 0 && rId == pinnedRoutineId) ||
            (r['sTitle'] == _userGoal!['sTitle'])) {
          pinnedRoutine = r;
          break;
        }
      }
    }

    final double progress;
    final String displayTitle;
    final String displayDetail;
    final Color goalColor;
    final IconData goalIcon;
    bool isCompleted = false;
    bool isWorkoutGoal = false;

    if (pinnedRoutine != null) {
      final title = pinnedRoutine['sTitle']?.toString() ?? 'เป้าหมายหลัก';
      final targetVal =
          (pinnedRoutine['targetValue'] as num?)?.toDouble() ?? 1.0;
      final unitText = pinnedRoutine['unit']?.toString() ?? 'ครั้ง';
      goalColor = _getRoutineColor(pinnedRoutine, 0);
      goalIcon = _getRoutineIcon(pinnedRoutine, 0);

      final lowerTitle = title.toLowerCase();
      String matchedType = pinnedRoutine['sLinkedWorkout']?.toString() ?? '';
      if (matchedType.isEmpty) {
        if (lowerTitle.contains('วิ่ง'))
          matchedType = 'วิ่ง';
        else if (lowerTitle.contains('เดิน'))
          matchedType = 'เดิน';
        else if (lowerTitle.contains('จักรยาน') || lowerTitle.contains('ปั่น'))
          matchedType = 'ปั่นจักรยาน';
        else if (lowerTitle.contains('ลู่วิ่ง'))
          matchedType = 'ลู่วิ่งในร่ม';
      }

      double? workoutVal;

      if (matchedType.isNotEmpty) {
        isWorkoutGoal = true;
      }

      if (matchedType.isNotEmpty &&
          _todayWorkoutStats.containsKey(matchedType)) {
        final stats = _todayWorkoutStats[matchedType]!;
        if (unitText.contains('กม') ||
            unitText.contains('กิโล') ||
            unitText.contains('km')) {
          workoutVal = stats['distance'];
        } else if (unitText.contains('นาที') ||
            unitText.contains('min') ||
            unitText.contains('เวลา') ||
            unitText.contains('ชม')) {
          workoutVal = stats['duration'];
        }
      }

      final routineId = (pinnedRoutine['nRoutineId'] as num?)?.toInt() ?? 0;
      final isDone = _todayCompletionMap[routineId] ?? false;
      final currentVal =
          workoutVal ??
          (isDone
              ? targetVal
              : ((pinnedRoutine['currentValue'] as num?)?.toDouble() ?? 0.0));

      progress = targetVal > 0 ? (currentVal / targetVal).clamp(0.0, 1.0) : 0.0;
      final percent = (progress * 100).toInt();
      isCompleted = progress >= 1.0 || isDone;
      displayTitle = title;
      displayDetail =
          'ความคืบหน้าวันนี้: ${_formatNum(currentVal)} / ${_formatNum(targetVal)} $unitText ($percent%)';
    } else if (hasPinnedGoal) {
      final goalTitle = _userGoal!['sTitle']?.toString() ?? 'เป้าหมายหลัก';
      final goalProgress = (_userGoal!['nProgress'] as num?)?.toDouble() ?? 0.0;
      final goalRemaining = _userGoal!['sRemainingText']?.toString() ?? '';
      progress = goalProgress.clamp(0.0, 1.0);
      goalColor = primaryGreen;
      goalIcon = Icons.flag_rounded;
      isCompleted = progress >= 1.0;
      displayTitle = goalTitle;
      displayDetail = goalRemaining.isNotEmpty
          ? goalRemaining
          : 'ทำสำเร็จแล้ว ${(progress * 100).toInt()}%';
    } else {
      progress = 0.0;
      goalColor = primaryGreen;
      goalIcon = Icons.push_pin_outlined;
      displayTitle = 'ยังไม่ได้ปักหมุดเป้าหมายหลัก';
      displayDetail =
          'เลือกปักหมุดกิจวัตรสำคัญจากหน้ากิจวัตรเพื่อติดตามความคืบหน้า';
    }

    // คำนวณวันที่เหลือจนจบเดือน
    final lastDayOfMonth = DateTime(_now.year, _now.month + 1, 0);
    final daysRemaining = lastDayOfMonth.difference(_now).inDays;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasPinnedGoal
              ? goalColor.withValues(alpha: 0.25)
              : Colors.grey.shade200,
          width: hasPinnedGoal ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    hasPinnedGoal
                        ? Icons.flag_rounded
                        : Icons.push_pin_outlined,
                    color: hasPinnedGoal ? Colors.orange : Colors.grey,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'เป้าหมายหลักของฉัน',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              if (hasPinnedGoal)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: goalColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.push_pin, size: 12, color: goalColor),
                      const SizedBox(width: 4),
                      Text(
                        'ปักหมุดแล้ว',
                        style: TextStyle(
                          color: goalColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'เหลืออีก $daysRemaining วัน',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),

          if (hasPinnedGoal) ...[
            // Circular Progress
            CircularPercentIndicator(
              radius: 64.0,
              lineWidth: 12.0,
              percent: progress,
              center: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "${(progress * 100).toInt()}%",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                      color: goalColor,
                    ),
                  ),
                  Text(
                    isCompleted ? "สำเร็จแล้ว 🎉" : "ความคืบหน้า",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isCompleted ? darkGreen : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              progressColor: goalColor,
              backgroundColor: goalColor.withValues(alpha: 0.12),
              circularStrokeCap: CircularStrokeCap.round,
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(goalIcon, color: goalColor, size: 20),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    displayTitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      color: Color(0xFF1E293B),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              displayDetail,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              textAlign: TextAlign.center,
            ),
            if (isCompleted) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Colors.green,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'ยินดีด้วย! คุณทำเป้าหมายหลักวันนี้สำเร็จแล้ว',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ] else ...[
            // Empty Pinned State
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              decoration: BoxDecoration(
                color: lightBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: primaryGreen.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.push_pin_rounded,
                      color: primaryGreen,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'ยังไม่ได้เลือกเป้าหมายหลัก',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ไปที่หน้ากิจวัตร แล้วกดปุ่มสามจุด ⋮ บนกิจวัตรที่ต้องการเพื่อ "ปักหมุดเป็นเป้าหมายหลัก"',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    onPressed: widget.onNavigateToPractice,
                    icon: const Icon(Icons.touch_app_rounded, size: 16),
                    label: const Text('ไปเลือกปักหมุดที่หน้ากิจวัตร'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 15),

          if (isWorkoutGoal) ...[
            const SizedBox(height: 15),
            // --- สถิติจากข้อมูล Workout ---
            Row(
              children: [
                Expanded(
                  child: _buildGoalStatItem(
                    icon: Icons.straighten,
                    label: 'ระยะทาง',
                    value: '${_totalDistanceKm.toStringAsFixed(2)} km',
                    color: primaryGreen,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildGoalStatItem(
                    icon: Icons.local_fire_department,
                    label: 'แคลอรี่',
                    value: '${_totalCaloriesBurned.toStringAsFixed(0)} kcal',
                    color: Colors.redAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildGoalStatItem(
                    icon: Icons.fitness_center,
                    label: 'ออกกำลังกาย',
                    value: '$_workoutCount ครั้ง',
                    color: Colors.blueAccent,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildGoalStatItem(
                    icon: Icons.timer,
                    label: 'เวลารวม',
                    value: _totalWorkoutDurationSec >= 3600
                        ? '${_totalWorkoutDurationSec ~/ 3600} ชม. ${(_totalWorkoutDurationSec % 3600) ~/ 60} น.'
                        : '${(_totalWorkoutDurationSec % 3600) ~/ 60} นาที',
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  // --- Widget ปุ่ม Action (Start Workout) ---
  Widget _buildActionButtons() {
    final pinnedTitle = _userGoal?['sTitle']?.toString() ?? '';
    String buttonText = 'เริ่มวิ่งมินิมาราธอน (30 นาที)';
    IconData buttonIcon = Icons.bolt;

    if (pinnedTitle.isNotEmpty) {
      final lower = pinnedTitle.toLowerCase();
      if (lower.contains('จักรยาน') || lower.contains('ปั่น')) {
        buttonText = 'เริ่ม$pinnedTitle';
        buttonIcon = Icons.directions_bike;
      } else if (lower.contains('สมาธิ') || lower.contains('ฝึกสติ')) {
        buttonText = 'จับเวลา$pinnedTitle';
        buttonIcon = Icons.self_improvement;
      } else if (lower.contains('น้ำ') || lower.contains('ดื่ม')) {
        buttonText = 'บันทึก$pinnedTitle';
        buttonIcon = Icons.water_drop;
      } else if (lower.contains('วิ่ง') ||
          lower.contains('เดิน') ||
          lower.contains('ออกกำลัง')) {
        buttonText = 'เริ่ม$pinnedTitle';
        buttonIcon = Icons.directions_run;
      } else {
        buttonText = 'เริ่ม$pinnedTitle';
        buttonIcon = Icons.play_arrow_rounded;
      }
    }

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _handleStartWorkout,
            style: ElevatedButton.styleFrom(
              backgroundColor: darkGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(buttonIcon, color: Colors.yellow),
                const SizedBox(width: 8),
                Text(
                  buttonText,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: OutlinedButton(
            onPressed: widget.onNavigateToWorkout ?? () {},
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.grey.shade300),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              backgroundColor: Colors.white,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.swap_calls, color: Colors.black54),
                SizedBox(width: 8),
                Text(
                  'เลือกประเภทอื่น',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- Widget เป้าหมายอื่นๆ (Card 3) ---
  // แสดงกิจวัตรอื่นๆ ทั้งหมดที่ไม่ได้ถูกปักหมุดเป็นเป้าหมายหลัก
  Widget _buildOtherGoalsCard() {
    final pinnedRoutineId = (_userGoal?['nRoutineId'] as num?)?.toInt() ?? 0;
    final pinnedTitle = _userGoal?['sTitle']?.toString() ?? '';

    // กรองเอากิจวัตรอื่นๆ ที่ไม่ได้ปักหมุด
    final otherRoutines = _routines.where((r) {
      final rId = (r['nRoutineId'] as num?)?.toInt() ?? 0;
      final rTitle = r['sTitle']?.toString() ?? '';
      if (pinnedRoutineId > 0 && rId == pinnedRoutineId) return false;
      if (pinnedRoutineId == 0 &&
          pinnedTitle.isNotEmpty &&
          rTitle == pinnedTitle)
        return false;
      return true;
    }).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.format_list_bulleted_rounded,
                    color: Colors.blueGrey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    otherRoutines.isNotEmpty
                        ? 'เป้าหมายอื่นๆ (${otherRoutines.length})'
                        : 'เป้าหมายอื่นๆ',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: widget.onNavigateToPractice,
                child: const Text(
                  'ดูทั้งหมด >',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (otherRoutines.isNotEmpty) ...[
            // แสดงรายการกิจวัตรอื่นๆ ที่ดึงมาจากหน้ากิจวัตร
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: otherRoutines.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final routine = otherRoutines[index];
                final rId = (routine['nRoutineId'] as num?)?.toInt() ?? 0;
                final title = routine['sTitle']?.toString() ?? 'ไม่มีชื่อ';
                final targetVal =
                    (routine['targetValue'] as num?)?.toDouble() ?? 1.0;
                final unitText = routine['unit']?.toString() ?? 'ครั้ง';
                final color = _getRoutineColor(routine, index);
                final icon = _getRoutineIcon(routine, index);

                final lowerTitle = title.toLowerCase();
                String matchedType =
                    routine['sLinkedWorkout']?.toString() ?? '';
                if (matchedType.isEmpty) {
                  if (lowerTitle.contains('วิ่ง'))
                    matchedType = 'วิ่ง';
                  else if (lowerTitle.contains('เดิน'))
                    matchedType = 'เดิน';
                  else if (lowerTitle.contains('จักรยาน') ||
                      lowerTitle.contains('ปั่น'))
                    matchedType = 'ปั่นจักรยาน';
                  else if (lowerTitle.contains('ลู่วิ่ง'))
                    matchedType = 'ลู่วิ่งในร่ม';
                }

                double? workoutVal;
                if (matchedType.isNotEmpty &&
                    _todayWorkoutStats.containsKey(matchedType)) {
                  final stats = _todayWorkoutStats[matchedType]!;
                  if (unitText.contains('กม') ||
                      unitText.contains('กิโล') ||
                      unitText.contains('km')) {
                    workoutVal = stats['distance'];
                  } else if (unitText.contains('นาที') ||
                      unitText.contains('min') ||
                      unitText.contains('เวลา') ||
                      unitText.contains('ชม')) {
                    workoutVal = stats['duration'];
                  }
                }

                final isDone = _todayCompletionMap[rId] ?? false;
                final currentVal =
                    workoutVal ??
                    (isDone
                        ? targetVal
                        : ((routine['currentValue'] as num?)?.toDouble() ??
                              0.0));
                final progress = targetVal > 0
                    ? (currentVal / targetVal).clamp(0.0, 1.0)
                    : 0.0;

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDone
                        ? Colors.green.shade50.withValues(alpha: 0.5)
                        : lightBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDone
                          ? Colors.green.shade200
                          : Colors.grey.shade200,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isDone
                                  ? Colors.green.withValues(alpha: 0.2)
                                  : color.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isDone ? Icons.check_circle : icon,
                              color: isDone ? Colors.green.shade700 : color,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: isDone
                                        ? Colors.grey.shade600
                                        : const Color(0xFF1E293B),
                                    decoration: isDone
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${_formatNum(currentVal)} / ${_formatNum(targetVal)} $unitText',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          // Quick Check-off Button
                          InkWell(
                            onTap: () async {
                              final messenger = ScaffoldMessenger.of(context);
                              final updatedState = await AppDatabase.instance
                                  .toggleRoutineLog(
                                    routineId: rId,
                                    dateStr:
                                        '${_now.year}-${_now.month.toString().padLeft(2, '0')}-${_now.day.toString().padLeft(2, '0')}',
                                  );
                              if (!mounted) return;
                              setState(() {
                                _todayCompletionMap[rId] = updatedState;
                              });
                              messenger.hideCurrentSnackBar();
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      Icon(
                                        updatedState
                                            ? Icons.check_circle
                                            : Icons.refresh,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          updatedState
                                              ? 'เช็คทำรายการ "$title" เรียบร้อยแล้ว! 🎉'
                                              : 'ยกเลิกการเช็ค "$title" แล้ว',
                                        ),
                                      ),
                                    ],
                                  ),
                                  backgroundColor: updatedState
                                      ? darkGreen
                                      : Colors.grey.shade800,
                                  duration: const Duration(seconds: 2),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: isDone
                                    ? Colors.green.shade100
                                    : color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isDone
                                      ? Colors.green.shade300
                                      : color.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isDone
                                        ? Icons.check_circle_rounded
                                        : Icons.check_circle_outline_rounded,
                                    size: 14,
                                    color: isDone
                                        ? Colors.green.shade800
                                        : color,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isDone ? 'สำเร็จแล้ว' : 'ทำรายการ',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isDone
                                          ? Colors.green.shade800
                                          : color,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isDone ? Colors.green : color,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ] else ...[
            // กรณีไม่มีกิจวัตรอื่นๆ ให้เปลี่ยนจาก _buildFallbackHealthGoals() เป็นข้อความว่างๆ
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32.0),
              child: Center(
                child: Text(
                  'ยังไม่ได้เพิ่มเป้าหมายอื่นๆ',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildFallbackHealthGoals() {
    final weight = _latestRecord?.nWeight ?? _user?.nWeight ?? 0.0;
    final height = _latestRecord?.nHeight ?? _user?.nHeight ?? 0.0;
    final age = _user?.nAge ?? 0;
    final gender = _user?.genderEnum ?? Gender.male;
    final activityLevel = _user?.activityLevelObj ?? ActivityLevel.options[1];

    double tdee = _latestRecord?.nTdee ?? 0.0;
    if (tdee <= 0 && weight > 0 && height > 0 && age > 0) {
      final bmr = HealthCalculator.calculateBMR(
        gender: gender,
        weightKg: weight,
        heightCm: height,
        age: age,
      );
      tdee = HealthCalculator.calculateTDEE(
        bmr: bmr,
        activityMultiplier: activityLevel.multiplier,
      );
    }

    final calorieTarget = tdee > 0 ? tdee.round() : 2000;
    final nutritionPercent = calorieTarget > 0
        ? (_todayNutritionCalories / calorieTarget).clamp(0.0, 1.0)
        : 0.0;

    final workoutMinutes = (_totalWorkoutDurationSec / 60).round();
    const workoutTargetMinutes = 150;
    final workoutPercent = (workoutMinutes / workoutTargetMinutes).clamp(
      0.0,
      1.0,
    );

    const distanceTarget = 50.0;
    final distancePercent = (_totalDistanceKm / distanceTarget).clamp(0.0, 1.0);

    return Column(
      children: [
        _buildMiniGoalProgress(
          icon: Icons.restaurant,
          color: Colors.blue,
          title: 'แคลอรี่วันนี้',
          current: _formatInt(_todayNutritionCalories),
          target: '${_formatInt(calorieTarget)} kcal',
          percent: nutritionPercent,
        ),
        const SizedBox(height: 16),
        _buildMiniGoalProgress(
          icon: Icons.timer,
          color: Colors.orange,
          title: 'เวลาออกกำลังกาย',
          current: '$workoutMinutes',
          target: '$workoutTargetMinutes นาที/สัปดาห์',
          percent: workoutPercent,
        ),
        const SizedBox(height: 16),
        _buildMiniGoalProgress(
          icon: Icons.directions_run,
          color: Colors.purple,
          title: 'ระยะทางวิ่งสะสม',
          current: _totalDistanceKm.toStringAsFixed(1),
          target: '${distanceTarget.toInt()} กม./เดือน',
          percent: distancePercent,
        ),
      ],
    );
  }

  Widget _buildMiniGoalProgress({
    required IconData icon,
    required Color color,
    required String title,
    required String current,
    required String target,
    required double percent,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Text(
                  '$current / $target',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(width: 8),
                Text(
                  '${(percent * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearPercentIndicator(
          lineHeight: 8.0,
          percent: percent,
          progressColor: color,
          backgroundColor: Colors.grey.shade200,
          barRadius: const Radius.circular(4),
          padding: EdgeInsets.zero,
        ),
      ],
    );
  }

  // --- Widget สถิติย่อยในเป้าหมายหลัก ---
  Widget _buildGoalStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
