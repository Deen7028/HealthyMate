part of 'edit_profile_dialog.dart';

extension EditProfileDialogContent on _EditProfileDialogState {
  Widget _buildEditProfileDialog(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isDark = ThemeService.instance.isDarkMode;

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF1E2822) : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              this._buildDialogHeader(context, primaryColor, isDark),
              const SizedBox(height: 20),

              // Full Name Section
              this._buildSectionLabel('ชื่อ - นามสกุล'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: this._buildTextField(
                      controller: _firstCtrl,
                      label: 'ชื่อ',
                      hint: 'ชื่อจริง',
                      prefixIcon: Icons.badge_outlined,
                      primaryColor: primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: this._buildTextField(
                      controller: _lastCtrl,
                      label: 'นามสกุล',
                      hint: 'นามสกุล',
                      prefixIcon: Icons.badge_outlined,
                      primaryColor: primaryColor,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Gender & Age Section
              this._buildSectionLabel('ข้อมูลทั่วไป'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: this._buildGenderDropdown(primaryColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 4,
                    child: this._buildTextField(
                      controller: _ageCtrl,
                      label: 'อายุ',
                      hint: 'เช่น 25',
                      suffixText: 'ปี',
                      prefixIcon: Icons.cake_outlined,
                      keyboardType: TextInputType.number,
                      primaryColor: primaryColor,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Body Metrics Section
              this._buildSectionLabel('สัดส่วนร่างกาย'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: this._buildTextField(
                      controller: _heightCtrl,
                      label: 'ส่วนสูง',
                      hint: 'เช่น 175',
                      suffixText: 'ซม.',
                      prefixIcon: Icons.height_rounded,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      primaryColor: primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: this._buildTextField(
                      controller: _weightCtrl,
                      label: 'น้ำหนัก',
                      hint: 'เช่น 65.5',
                      suffixText: 'กก.',
                      prefixIcon: Icons.monitor_weight_outlined,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      primaryColor: primaryColor,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        side: const BorderSide(color: Color(0xFFE0E5E2)),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'ยกเลิก',
                        style: TextStyle(
                          color: Color(0xFF6F7A72),
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () => this._handleSave(context),
                      child: const Text(
                        'บันทึกข้อมูล',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
