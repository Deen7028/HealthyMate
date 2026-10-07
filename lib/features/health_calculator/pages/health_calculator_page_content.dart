part of 'health_calculator_page.dart';
extension _HealthCalculatorPageContent on _HealthCalculatorPageState {
  Widget _buildPage(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = AppTheme.getScaffoldColor(isDark);
    final cardBg = AppTheme.getBackgroundColor(isDark);
    final textPrimary = AppTheme.getTextPrimaryColor(isDark);
    final textSecondary = AppTheme.getTextSecondaryColor(isDark);
    final borderColor = AppTheme.getBorderColor(isDark);
    final surfaceBg = AppTheme.getSurfaceColor(isDark);
    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppTheme.primaryGreen,
          backgroundColor: cardBg,
          onRefresh: () => widget.state.loadData(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section (ใช้ ListenableBuilder เฉพาะส่วนแสดงชื่อผู้ใช้เพื่อลดการ rebuild ทั้งหน้า)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'เครื่องคำนวณสุขภาพ',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          ListenableBuilder(
                            listenable: widget.state,
                            builder: (context, _) {
                              final user = widget.state.currentUser;
                              return Text(
                                user != null
                                    ? 'ข้อมูลของคุณ (${user.sFirstName})'
                                    : 'ติดตามและคำนวณ BMI, BMR และ TDEE ของคุณ',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  color: textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    // History Button (TbCalculationHistory)
                    InkWell(
                      onTap: _openHistorySheet,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: surfaceBg,
                          shape: BoxShape.circle,
                          border: Border.all(color: borderColor),
                        ),
                        child: Icon(
                          Icons.history_rounded,
                          color: textPrimary,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Loading State Banner / Skeleton ระหว่างดึงข้อมูลจาก Server
                ListenableBuilder(
                  listenable: widget.state,
                  builder: (context, _) {
                    if (!widget.state.isLoading) return const SizedBox.shrink();
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: surfaceBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.primaryGreen,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'กำลังโหลดข้อมูลสุขภาพล่าสุดจากเซิร์ฟเวอร์...',
                              style: TextStyle(
                                fontSize: 13,
                                color: textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                // Gender Selector (ฟังเฉพาะ gender state)
                ListenableBuilder(
                  listenable: widget.state,
                  builder: (context, _) => GenderSelector(
                    selectedGender: widget.state.gender,
                    onGenderChanged: (gender) => widget.state.setGender(gender),
                  ),
                ),
                const SizedBox(height: 18),
                ..._buildInputsSection(),

                // Results Section (Smart Reveal: ซ่อนไว้หากยังไม่มีการคำนวณ)
                ListenableBuilder(
                  listenable: widget.state,
                  builder: (context, _) {
                    final hasResult = widget.state.bmi > 0;

                    return AnimatedSize(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOutCubic,
                      child: hasResult
                          ? Column(
                              children: [
                                HealthCalculatorResultSection(
                                  state: widget.state,
                                ),
                                const SizedBox(height: 20),
                                SizedBox(
                                  width: double.infinity,
                                  height: 52,
                                  child: ElevatedButton.icon(
                                    onPressed: _onSaveToDashboard,
                                    icon: const Icon(
                                      Icons.cloud_upload_outlined,
                                      size: 22,
                                    ),
                                    label: const FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        'บันทึกข้อมูลสุขภาพเข้า Dashboard',
                                        style: TextStyle(
                                          fontSize: 15.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isDark
                                          ? const Color(0xFF2E5327)
                                          : const Color(0xFF1E3A24),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 1,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : const SizedBox.shrink(),
                    );
                  },
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
