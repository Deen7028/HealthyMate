import 'package:flutter/material.dart';
import 'package:healthymate/core/database/app_database.dart';
import 'package:healthymate/core/services/sync_service.dart';
import 'package:healthymate/core/theme/app_theme.dart';
import '../widgets/index.dart';

/// หน้าแสดงประวัติการออกกำลังกายจากตาราง TbWorkouts
class WorkoutHistoryPage extends StatefulWidget {
  final int userId;

  const WorkoutHistoryPage({super.key, required this.userId});

  @override
  State<WorkoutHistoryPage> createState() => _WorkoutHistoryPageState();
}

class _WorkoutHistoryPageState extends State<WorkoutHistoryPage> {
  bool _isLoading = true;
  bool _isPulling = false;
  List<Map<String, dynamic>> _workouts = [];

  @override
  void initState() {
    super.initState();
    _initWorkoutData();
  }

  /// ตรวจสอบเงื่อนไขการดึงข้อมูลเริ่มต้น (Initial Data Hydration Trigger)
  /// - หาก Local DB ว่างเปล่า (COUNT(*) == 0) จะสั่งดึงข้อมูลจาก Server ลงมาเติมลงเครื่องทันที
  Future<void> _initWorkoutData() async {
    await _loadWorkoutHistory();

    // ตรวจสอบว่า Local DB ว่างเปล่าหรือไม่
    try {
      final count = await AppDatabase.instance.getWorkoutCount(userId: widget.userId);
      if (count == 0 && mounted) {
        debugPrint('WorkoutHistory: Local DB is empty (COUNT == 0). Triggering Initial Pull Sync...');
        await _pullDownstreamData(isInitial: true);
      }
    } catch (e) {
      debugPrint('WorkoutHistory: Error checking workout count: $e');
    }
  }

  /// ฟังก์ชันดึงข้อมูลจากเซิร์ฟเวอร์ลงมา (Pull Downstream Sync)
  Future<void> _pullDownstreamData({bool isInitial = false}) async {
    if (!mounted) return;
    setState(() {
      _isPulling = true;
    });

    try {
      final pulledCount = await SyncService.instance.pullDownstreamWorkouts(
        widget.userId,
        forceInitial: isInitial,
      );

      // โหลดข้อมูลล่าสุดจาก SQLite หลัง Upsert เสร็จ
      final list = await AppDatabase.instance.getWorkouts(userId: widget.userId);
      if (mounted) {
        setState(() {
          _workouts = list;
          _isLoading = false;
          _isPulling = false;
        });

        if (pulledCount > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.cloud_download_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text('ดึงข้อมูลสำเร็จ $pulledCount รายการ'),
                ],
              ),
              backgroundColor: AppTheme.primaryGreen,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('WorkoutHistory: Pull downstream error: $e');
      if (mounted) {
        setState(() {
          _isPulling = false;
        });
      }
    }
  }

  Future<void> _loadWorkoutHistory() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final list = await AppDatabase.instance.getWorkouts(
        userId: widget.userId,
      );
      if (mounted) {
        setState(() {
          _workouts = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F3),
      appBar: AppBar(
        title: const Text(
          'ประวัติการออกกำลังกาย',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: Color(0xFF1C2819),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF1C2819),
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_isPulling)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 14),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF2E5327),
                  ),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.sync_rounded, color: Color(0xFF2E5327)),
              onPressed: () => _pullDownstreamData(isInitial: false),
              tooltip: 'ดึงข้อมูลล่าสุดจากเซิร์ฟเวอร์ (Delta Sync)',
            ),
        ],
      ),
      body: RefreshIndicator(
        color: AppTheme.primaryGreen,
        backgroundColor: Colors.white,
        onRefresh: () => _pullDownstreamData(isInitial: false),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryGreen),
              )
            : _workouts.isEmpty
            ? _buildEmptyState()
            : _buildHistoryList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return WorkoutHistoryEmptyCard(
      onSyncTap: () => _pullDownstreamData(isInitial: true),
    );
  }

  Widget _buildHistoryList() {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(18),
      itemCount: _workouts.length,
      itemBuilder: (context, index) {
        return WorkoutHistoryItemCard(
          workoutItem: _workouts[index],
        );
      },
    );
  }
}


