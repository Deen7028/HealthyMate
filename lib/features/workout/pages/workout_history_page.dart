import 'package:flutter/material.dart';
import 'package:healthymate/core/theme/app_theme.dart';
import 'package:healthymate/features/workout/controllers/workout_history_controller.dart';
import '../widgets/index.dart';

/// หน้าแสดงประวัติการออกกำลังกายจากตาราง TbWorkouts
class WorkoutHistoryPage extends StatefulWidget {
  final int userId;

  const WorkoutHistoryPage({super.key, required this.userId});

  @override
  State<WorkoutHistoryPage> createState() => _WorkoutHistoryPageState();
}

class _WorkoutHistoryPageState extends State<WorkoutHistoryPage> {
  late final WorkoutHistoryController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WorkoutHistoryController();
    _controller.addListener(_onControllerChanged);
    _controller.init(widget.userId);
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handlePullSync({bool isInitial = false}) async {
    final pulledCount = await _controller.pullDownstreamData(isInitial: isInitial);
    if (pulledCount > 0 && mounted) {
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
          if (_controller.isPulling)
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
              onPressed: () => _handlePullSync(isInitial: false),
              tooltip: 'ดึงข้อมูลล่าสุดจากเซิร์ฟเวอร์ (Delta Sync)',
            ),
        ],
      ),
      body: RefreshIndicator(
        color: AppTheme.primaryGreen,
        backgroundColor: Colors.white,
        onRefresh: () => _handlePullSync(isInitial: false),
        child: _controller.isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryGreen),
              )
            : _controller.workouts.isEmpty
                ? _buildEmptyState()
                : _buildHistoryList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return WorkoutHistoryEmptyCard(
      onSyncTap: () => _handlePullSync(isInitial: true),
    );
  }

  Widget _buildHistoryList() {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(18),
      itemCount: _controller.workouts.length,
      itemBuilder: (context, index) {
        return WorkoutHistoryItemCard(
          workoutItem: _controller.workouts[index],
        );
      },
    );
  }
}
