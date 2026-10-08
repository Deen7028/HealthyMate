import 'package:flutter/material.dart';
import 'package:healthymate/features/workout/models/workout_models.dart';
import 'package:healthymate/shared/theme/app_theme.dart';
import 'package:healthymate/features/workout/controllers/workout_history_controller.dart';
import '../widgets/index.dart';

/// หน้าแสดงประวัติการออกกำลังกายย้อนหลังของผู้ใช้ (Workout History Page)
/// ดึงข้อมูลจากฐานข้อมูล SQLite Local (`TbWorkouts`) และรองรับการดึงข้อมูลจาก Server (Delta Sync)
class WorkoutHistoryPage extends StatefulWidget {
  /// รหัสผู้ใช้ (UserId)
  final int userId;

  const WorkoutHistoryPage({super.key, required this.userId});

  @override
  State<WorkoutHistoryPage> createState() => _WorkoutHistoryPageState();
}

class _WorkoutHistoryPageState extends State<WorkoutHistoryPage> {
  /// คอนโทรลเลอร์บริหารจัดการดึงประวัติการออกกำลังกายและ Sync ข้อมูล
  late final WorkoutHistoryController _controller;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = WorkoutHistoryController();
    _controller.addListener(_onControllerChanged);
    _controller.init(widget.userId);
  }

  /// อัปเดต UI เมื่อ Controller มีการเปลี่ยนแปลงสถานะข้อมูล
  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  /// จัดการการรีเฟรชดึงข้อมูลล่าสุดจากเซิร์ฟเวอร์ (Delta Sync / Downstream)
  Future<void> _handlePullSync({bool isInitial = false}) async {
    final pulledCount = await _controller.pullDownstreamData(
      isInitial: isInitial,
    );
    if (pulledCount > 0 && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.cloud_download_rounded,
                color: Colors.white,
                size: 20,
              ),
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

  String _formatTotalDuration(int totalSecs) {
    final hrs = totalSecs ~/ 3600;
    final mins = (totalSecs % 3600) ~/ 60;
    if (hrs > 0) {
      return '$hrs ชม. $mins น.';
    }
    return '$mins นาที';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = AppTheme.getScaffoldColor(isDark);
    final cardBg = AppTheme.getBackgroundColor(isDark);
    final textPrimary = AppTheme.getTextPrimaryColor(isDark);

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: Text(
          'ประวัติการออกกำลังกาย',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: textPrimary,
          ),
        ),
        backgroundColor: cardBg,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: textPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_controller.isPulling)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: isDark
                        ? AppTheme.primaryLightGreen
                        : const Color(0xFF2E5327),
                  ),
                ),
              ),
            )
          else
            IconButton(
              icon: Icon(
                Icons.sync_rounded,
                color: isDark
                    ? AppTheme.primaryLightGreen
                    : const Color(0xFF2E5327),
              ),
              onPressed: () => _handlePullSync(isInitial: false),
              tooltip: 'ดึงข้อมูลล่าสุดจากเซิร์ฟเวอร์ (Delta Sync)',
            ),
        ],
      ),
      body: RefreshIndicator(
        color: AppTheme.primaryGreen,
        backgroundColor: cardBg,
        onRefresh: () => _handlePullSync(isInitial: false),
        child: _controller.isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryGreen),
              )
            : _controller.workouts.isEmpty
            ? _buildEmptyState()
            : _buildHistoryContent(isDark, cardBg, textPrimary),
      ),
    );
  }
  // ปุ่มดึงข้อมูลล่าสุดจากเซิร์ฟเวอร์ (Delta Sync)
  Widget _buildEmptyState() {
    return WorkoutHistoryEmptyCard(
      onSyncTap: () => _handlePullSync(isInitial: true),
    );
  }
  // กล่องสรุปผลรวม (Summary Header: ทั้งหมด, ระยะทางรวม, เผาผลาญรวม, เวลารวม)
  Widget _buildHistoryContent(
    bool isDark,
    Color cardBg,
    Color textPrimary,
  ) {
    final textSecondary = AppTheme.getTextSecondaryColor(isDark);
    final borderColor = AppTheme.getBorderColor(isDark);
    final filtered = _controller.filteredWorkouts;

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // 1. กล่องสรุปผลรวม (Summary Header: ทั้งหมด, ระยะทางรวม, เผาผลาญรวม, เวลารวม)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
            child: _buildSummaryOverviewCard(
              isDark,
              cardBg,
              textPrimary,
              textSecondary,
              borderColor,
            ),
          ),
        ),

        // 2. ช่องค้นหาข้อความ และตัวเลือกหมวดหมู่ (Search & Category Chips)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ช่องกรอกค้นหา
                Container(
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: borderColor),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(color: textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'ค้นหาชื่อกิจกรรม...',
                      hintStyle: TextStyle(
                        color: textSecondary.withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: textSecondary,
                        size: 20,
                      ),
                      suffixIcon: _controller.searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.clear_rounded,
                                color: textSecondary,
                                size: 18,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                _controller.setSearchQuery('');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 14,
                      ),
                    ),
                    onChanged: (val) => _controller.setSearchQuery(val),
                  ),
                ),
                const SizedBox(height: 12),

                // แถบเลือกหมวดหมู่กิจกรรม (Category Filter Chips)
                _buildCategoryFilterRow(isDark, cardBg, borderColor, textPrimary),
                const SizedBox(height: 14),
              ],
            ),
          ),
        ),

        // 3. รายการการ์ดประวัติกิจกรรม
        if (filtered.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.filter_alt_off_rounded,
                      size: 48,
                      color: textSecondary.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'ไม่พบกิจกรรมในหมวดหมู่นี้',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 400),
                    curve: Interval(
                      (index * 0.06).clamp(0.0, 1.0),
                      1.0,
                      curve: Curves.easeOutCubic,
                    ),
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, 20 * (1 - value)),
                          child: child,
                        ),
                      );
                    },
                    child: WorkoutHistoryItemCard(
                      workoutItem: filtered[index],
                    ),
                  );
                },
                childCount: filtered.length,
              ),
            ),
          ),
      ],
    );
  }

  /// การ์ดสรุปภาพรวม: จำนวนครั้งทั้งหมด, ระยะทางรวม, เผาผลาญรวม, เวลาสะสม
  Widget _buildSummaryOverviewCard(
    bool isDark,
    Color cardBg,
    Color textPrimary,
    Color textSecondary,
    Color borderColor,
  ) {
    final totalCount = _controller.totalCount;
    final totalDist = _controller.totalDistanceKm;
    final totalCal = _controller.totalCaloriesBurned;
    final totalDuration = _controller.totalDurationSeconds;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF23352A) : const Color(0xFFE8F3EB),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.insights_rounded,
                  size: 18,
                  color: isDark ? AppTheme.primaryLightGreen : const Color(0xFF2E5327),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'ภาพรวมการออกกำลังกาย',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              // 1. รายการทั้งหมด
              Expanded(
                child: _buildSummaryStatItem(
                  icon: Icons.fitness_center_rounded,
                  iconColor: const Color(0xFF3B82F6),
                  title: 'ทั้งหมด',
                  value: '$totalCount ครั้ง',
                  isDark: isDark,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
              ),
              Container(height: 36, width: 1, color: borderColor),
              // 2. ระยะทางรวม
              Expanded(
                child: _buildSummaryStatItem(
                  icon: Icons.route_rounded,
                  iconColor: const Color(0xFF10B981),
                  title: 'ระยะทางรวม',
                  value: '${totalDist.toStringAsFixed(1)} km',
                  isDark: isDark,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: borderColor),
          const SizedBox(height: 12),
          Row(
            children: [
              // 3. เผาผลาญรวม
              Expanded(
                child: _buildSummaryStatItem(
                  icon: Icons.local_fire_department_rounded,
                  iconColor: const Color(0xFFEF4444),
                  title: 'เผาผลาญรวม',
                  value: '${totalCal.toStringAsFixed(0)} kcal',
                  isDark: isDark,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
              ),
              Container(height: 36, width: 1, color: borderColor),
              // 4. เวลาสะสม
              Expanded(
                child: _buildSummaryStatItem(
                  icon: Icons.timer_outlined,
                  iconColor: const Color(0xFFF59E0B),
                  title: 'เวลาสะสม',
                  value: _formatTotalDuration(totalDuration),
                  isDark: isDark,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStatItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 11, color: textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// ตัวเลือก Filter หมวดหมู่ (All, วิ่ง, เดิน, ปั่นจักรยาน, ทำสมาธิ, โยคะ)
  Widget _buildCategoryFilterRow(
    bool isDark,
    Color cardBg,
    Color borderColor,
    Color textPrimary,
  ) {
    final categories = [
      {'id': 'all', 'title': 'ทั้งหมด', 'icon': Icons.grid_view_rounded},
      ...WorkoutCategory.categories.map((c) => {
            'id': c.id,
            'title': c.title.split(' ').first,
            'icon': c.icon,
          }),
    ];

    final activeId = _controller.selectedCategoryFilter;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((cat) {
          final catId = cat['id'] as String;
          final catTitle = cat['title'] as String;
          final catIcon = cat['icon'] as IconData;
          final isSelected = activeId == catId;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => _controller.setSelectedCategoryFilter(catId),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark ? const Color(0xFF23352A) : const Color(0xFF2E5327))
                      : cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? (isDark ? AppTheme.primaryLightGreen : const Color(0xFF2E5327))
                        : borderColor,
                    width: 1.2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      catIcon,
                      size: 16,
                      color: isSelected
                          ? (isDark ? AppTheme.primaryLightGreen : Colors.white)
                          : textPrimary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      catTitle,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? (isDark ? AppTheme.primaryLightGreen : Colors.white)
                            : textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
