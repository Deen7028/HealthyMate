part of 'profile_page.dart';

extension ProfilePageContent on _ProfilePageState {
  Widget _buildProfilePage(BuildContext context) {
    final isDark = ThemeService.instance.isDarkMode;
    final primaryColor = Theme.of(context).colorScheme.primary;

    if (_controller.isLoading) {
      return Scaffold(
        backgroundColor: isDark
            ? const Color(0xFF131915)
            : const Color(0xFFF3F6F2),
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: primaryColor),
                const SizedBox(height: 16),
                const Text(
                  'กำลังโหลดข้อมูลโปรไฟล์...',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF5A6559),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final user = _controller.currentUser;
    final userName = (user != null && user.sFullName.trim().isNotEmpty)
        ? user.sFullName.trim()
        : 'ผู้ใช้งาน';
    final userEmail = (user != null && user.sEmail.isNotEmpty)
        ? user.sEmail
        : (AuthService.instance.currentUserEmail.isNotEmpty
              ? AuthService.instance.currentUserEmail
              : '');
    final avatarProvider = _controller.getAvatarImageProvider();
    final activeDeviceCount = _controller.connectedDevices
        .where((d) => (d['isSynced'] as num?)?.toInt() == 1)
        .length;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF131915)
          : const Color(0xFFF3F6F2),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top App Bar (Avatar + Title + Bell)
              ProfileTopBar(avatarProvider: avatarProvider),

              // 2. Main Profile Card (Avatar + Name + Email + Goal)
              ProfileHeaderCard(
                avatarProvider: avatarProvider,
                name: userName,
                email: userEmail,
                goalTitle: _controller.mainGoalTitle,
                goalProgress: _controller.goalProgress,
                goalRemainingText: _controller.goalRemainingText,
                isUploadingImage: _controller.isUploadingImage,
                onAvatarTap: this._pickAndSaveProfileImage,
                onEditProfileTap: this._showEditProfileDialog,
                onGoalTap: widget.onNavigateToPractice,
              ),

              const SizedBox(height: 16),

              // 3. Quick Stats (สถิติย่อ)
              QuickStatsCard(
                workoutCount: _controller.workoutCount,
                activeDays: _controller.activeDays,
              ),

              const SizedBox(height: 20),

              // 4. Settings Section (การตั้งค่า)
              this._buildSectionHeader('การตั้งค่า'),
              const SizedBox(height: 8),
              SettingsCard(
                isLocationEnabled: _controller.isLocationEnabled,
                selectedUnit: _controller.selectedUnit,
                hasGeminiApiKey: _controller.geminiApiKey.isNotEmpty,
                onDarkModeChanged: (val) async {
                  await ThemeService.instance.setDarkMode(val);
                  setState(() {});
                },
                onLocationTap: () async {
                  await _controller.handleLocationTap();
                },
                onUnitPickerTap: this._showUnitPicker,
                onGeminiApiKeyTap: () {
                  if (user == null) return;
                  GeminiApiKeyDialog.show(
                    context,
                    userId: user.nUserId,
                    currentKey: _controller.geminiApiKey,
                    onSaved: (newKey) {
                      _controller.updateGeminiApiKey(newKey);
                    },
                  );
                },
              ),

              const SizedBox(height: 20),

              // 5. Account Section (บัญชี)
              this._buildSectionHeader('บัญชี'),
              const SizedBox(height: 8),
              AccountCard(
                activeDeviceCount: activeDeviceCount,
                onPersonalInfoTap: this._showPersonalInfoBottomSheet,
                onConnectedDevicesTap: this._showConnectedDevicesBottomSheet,
                onExportPdfTap: this._handleExportPdf,
                onDeleteAccountTap: this._handleDeleteAccount,
                onLogoutTap: this._handleLogout,
              ),

              const SizedBox(height: 28),

              // 6. App Info Footer
              ProfileFooter(
                onPrivacyPolicyTap: () {
                  this._showPolicyDialog(
                    'นโยบายความเป็นส่วนตัว (Privacy Policy)',
                    'HealthyMate ให้ความสำคัญสูงสุดกับความเป็นส่วนตัวของข้อมูลสุขภาพและพิกัดการออกกำลังกายของคุณ ข้อมูลทั้งหมดจะถูกเก็บรักษาอย่างปลอดภัยในอุปกรณ์ของคุณ และจะไม่มีการส่งต่อข้อมูลส่วนบุคคลไปยังบุคคลภายนอกโดยไม่ได้รับอนุญาต',
                  );
                },
                onTermsTap: () {
                  this._showPolicyDialog(
                    'ข้อกำหนดและเงื่อนไขการใช้งาน (Terms of Service)',
                    'การใช้งานแอปพลิเคชัน HealthyMate ถือว่าท่านยอมรับการประมวลผลข้อมูลทางสถิติการออกกำลังกาย คำแนะนำด้านสุขภาพและการคำนวณ BMI/TDEE เป็นข้อมูลเพื่อการดูแลสุขภาพเบื้องต้นเท่านั้น มิได้ใช้แทนคำแนะนำของแพทย์ผู้เชี่ยวชาญ',
                  );
                },
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Color(0xFF5A6559),
        ),
      ),
    );
  }
}
