// ส่วนนี้อธิบายบทบาทของไฟล์: หน้าจอหลัก ในฟีเจอร์กิจวัตรและเป้าหมายประจำวัน (completed goals page content)
// คอมเมนท์ภาษาไทยถูกใส่ไว้เป็นส่วนๆ เพื่อช่วยไล่ flow โดยไม่เปลี่ยนพฤติกรรมเดิมของโค้ด

part of 'completed_goals_and_routines_page.dart';

extension CompletedGoalsPageContent on _CompletedGoalsAndRoutinesPageState {
  Widget _buildHistoryPage(BuildContext context) {
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
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: textPrimary,
            size: 20,
          ),
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
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
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
                _buildCompletedGoalsTab(
                  cardBg,
                  textPrimary,
                  textSecondary,
                  isDark,
                ),

                // แท็บ 2: กิจวัตรที่ทำสำเร็จแล้ว
                _buildCompletedRoutinesTab(
                  cardBg,
                  textPrimary,
                  textSecondary,
                  isDark,
                ),
              ],
            ),
    );
  }
}
