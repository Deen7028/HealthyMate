part of 'completed_goals_and_routines_page.dart';

extension CompletedGoalsTab on _CompletedGoalsAndRoutinesPageState {
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
          final remaining =
              goal['sRemainingText']?.toString() ?? 'ทำสำเร็จครบ 100%';
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
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 12,
                            color: textSecondary,
                          ),
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
}
