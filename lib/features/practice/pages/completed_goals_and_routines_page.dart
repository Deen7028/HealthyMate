import 'package:flutter/material.dart';
import 'package:healthymate/core/database/app_database.dart';
import 'package:healthymate/shared/theme/app_theme.dart';

class CompletedGoalsAndRoutinesPage extends StatefulWidget {
  final int initialTabIndex;

  const CompletedGoalsAndRoutinesPage({
    super.key,
    this.initialTabIndex = 0,
  });

  @override
  State<CompletedGoalsAndRoutinesPage> createState() =>
      _CompletedGoalsAndRoutinesPageState();
}

class _CompletedGoalsAndRoutinesPageState
    extends State<CompletedGoalsAndRoutinesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  List<Map<String, dynamic>> _completedGoals = [];
  List<Map<String, dynamic>> _completedRoutines = [];

  final Color primaryGreen = AppTheme.primaryGreen;
  final Color darkGreen = AppTheme.primaryGreenDark;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    _loadHistoryData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadHistoryData() async {
    setState(() => _isLoading = true);
    try {
      final db = AppDatabase.instance;
      final user = await db.getCurrentUser();
      if (user == null) return;
      final userId = user.nUserId;

      // 1. ดึงประวัติเป้าหมายหลัก
      final allGoals = await db.getAllUserGoalsHistory(userId);
      // กรองเฉพาะเป้าหมายที่ทำสำเร็จ หรือมีความคืบหน้า 100%
      _completedGoals = allGoals.where((g) {
        final progress = (g['nProgress'] as num?)?.toDouble() ?? 0.0;
        final remaining = g['sRemainingText']?.toString() ?? '';
        return progress >= 1.0 || remaining.contains('100%');
      }).toList();

      // 2. ดึงประวัติกิจวัตรที่ทำสำเร็จ
      _completedRoutines =
          await db.getCompletedRoutineLogsHistory(userId: userId);
    } catch (e) {
      debugPrint('Error loading completed history: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatThaiDate(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) return 'ไม่ระบุวันที่';
    try {
      final dt = DateTime.parse(rawDate);
      const thaiMonths = [
        'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
        'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'
      ];
      final thaiYear = dt.year > 2500 ? dt.year : dt.year + 543;
      return '${dt.day} ${thaiMonths[dt.month - 1]} $thaiYear';
    } catch (_) {
      return rawDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = AppTheme.getBackgroundColor(isDark);
    final textPrimary = AppTheme.getTextPrimaryColor(isDark);
    final textSecondary = AppTheme.getTextSecondaryColor(isDark);
    final cardBg = isDark ? const Color(0xFF1E2822) : Colors.white;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E2822) : Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'ประวัติความสำเร็จ 🏆',
          style: TextStyle(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: isDark ? const Color(0xFF90DB89) : darkGreen,
          unselectedLabelColor: textSecondary,
          indicatorColor: isDark ? const Color(0xFF90DB89) : darkGreen,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: [
            Tab(
              icon: const Icon(Icons.flag_rounded, size: 20),
              text: 'เป้าหมายหลัก (${_completedGoals.length})',
            ),
            Tab(
              icon: const Icon(Icons.check_circle_rounded, size: 20),
              text: 'กิจวัตร 7 วันล่าสุด (${_completedRoutines.length})',
            ),
          ],
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: isDark ? const Color(0xFF90DB89) : darkGreen,
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                // แท็บ 1: เป้าหมายหลักที่ทำสำเร็จแล้ว
                _buildCompletedGoalsTab(cardBg, textPrimary, textSecondary, isDark),

                // แท็บ 2: กิจวัตรที่ทำสำเร็จแล้ว
                _buildCompletedRoutinesTab(cardBg, textPrimary, textSecondary, isDark),
              ],
            ),
    );
  }

  Widget _buildCompletedGoalsTab(
    Color cardBg,
    Color textPrimary,
    Color textSecondary,
    bool isDark,
  ) {
    if (_completedGoals.isEmpty) {
      return _buildEmptyState(
        icon: Icons.emoji_events_outlined,
        title: 'ยังไม่มีเป้าหมายหลักที่สำเร็จ 100%',
        subtitle: 'ตั้งใจทำตามเป้าหมายต่อไป คุณทำได้แน่นอนครับ! 💪',
        isDark: isDark,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadHistoryData,
      color: darkGreen,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _completedGoals.length,
        itemBuilder: (context, index) {
          final goal = _completedGoals[index];
          final title = goal['sTitle']?.toString() ?? 'เป้าหมายหลัก';
          final remaining = goal['sRemainingText']?.toString() ?? 'ทำสำเร็จครบ 100%';
          final updatedAt = _formatThaiDate(goal['dtUpdatedAt']?.toString());

          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: primaryGreen.withValues(alpha: isDark ? 0.3 : 0.2),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: primaryGreen.withValues(alpha: isDark ? 0.25 : 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Text('🏆', style: TextStyle(fontSize: 24)),
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
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1E3825)
                                  : const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '100% สำเร็จ',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? const Color(0xFF90DB89)
                                    : darkGreen,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        remaining,
                        style: TextStyle(fontSize: 12.5, color: textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.calendar_today_rounded,
                              size: 12, color: textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            'สำเร็จเมื่อ: $updatedAt',
                            style: TextStyle(
                              fontSize: 11,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCompletedRoutinesTab(
    Color cardBg,
    Color textPrimary,
    Color textSecondary,
    bool isDark,
  ) {
    if (_completedRoutines.isEmpty) {
      return _buildEmptyState(
        icon: Icons.checklist_rtl_rounded,
        title: 'ยังไม่มีประวัติกิจวัตรที่ทำสำเร็จ',
        subtitle: 'เริ่มเช็คกิจวัตรแรกของคุณวันนี้ได้เลย!',
        isDark: isDark,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadHistoryData,
      color: darkGreen,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _completedRoutines.length,
        itemBuilder: (context, index) {
          final r = _completedRoutines[index];
          final title = r['sTitle']?.toString() ?? 'กิจวัตร';
          final dateStr = _formatThaiDate(r['dtLogDate']?.toString());
          final targetVal = (r['targetValue'] as num?)?.toDouble() ?? 1.0;
          final progressVal = (r['nProgressValue'] as num?)?.toDouble() ?? targetVal;
          final unit = r['unit']?.toString() ?? 'ครั้ง';
          final time = r['sTime']?.toString() ?? '';

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? const Color(0xFF2C3930) : const Color(0xFFE2E7DF),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E3825)
                        : const Color(0xFFE8F5E9),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle_rounded,
                    color: isDark ? const Color(0xFF90DB89) : darkGreen,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ทำได้: ${progressVal == progressVal.toInt() ? progressVal.toInt() : progressVal.toStringAsFixed(1)} / ${targetVal == targetVal.toInt() ? targetVal.toInt() : targetVal.toStringAsFixed(1)} $unit ${time.isNotEmpty ? "• $time" : ""}',
                        style: TextStyle(fontSize: 12, color: textSecondary),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF27342C) : const Color(0xFFF3F6F2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    dateStr,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: (isDark ? const Color(0xFF90DB89) : darkGreen)
                    .withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 54,
                color: isDark ? const Color(0xFF90DB89) : darkGreen,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF1E2822),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF8C968E),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
