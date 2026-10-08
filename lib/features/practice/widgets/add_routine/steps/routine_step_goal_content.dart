part of 'routine_step_goal.dart';
//  Step 2: กำหนดระยะเวลาและการเชื่อมโยงกับแอปภายนอก 🔗
extension RoutineStepGoalContent on RoutineStepGoal {
  Widget _buildStepGoal(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = AppTheme.getTextPrimaryColor(isDark);
    final textSecondary = AppTheme.getTextSecondaryColor(isDark);
    final cardBg = AppTheme.getBackgroundColor(isDark);
    final borderColor = AppTheme.getBorderColor(isDark);
    final surfaceBg = AppTheme.getSurfaceColor(isDark);
    final isAutoLinked =
        selectedLinkedWorkout != null && selectedLinkedWorkout!.isNotEmpty;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step 2: เป้าหมาย & เชื่อมโยง GPS ออกกำลังกาย 🔗',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'กำหนดเป้าหมายเชิงปริมาณ',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: surfaceBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                _buildQuickUnitButton(
                  'กม.',
                  'ระยะทาง',
                  isDark,
                  textPrimary,
                  textSecondary,
                ),
                _buildQuickUnitButton(
                  'นาที',
                  'เวลา',
                  isDark,
                  textPrimary,
                  textSecondary,
                ),
                _buildQuickUnitButton(
                  'ครั้ง',
                  'จำนวน',
                  isDark,
                  textPrimary,
                  textSecondary,
                ),
                _buildQuickUnitButton(
                  'มล.',
                  'โภชนาการ',
                  isDark,
                  textPrimary,
                  textSecondary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: targetController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: textPrimary),
                  decoration: InputDecoration(
                    labelText: 'เป้าหมายต่อวัน *',
                    labelStyle: TextStyle(color: textSecondary),
                    hintText: 'เช่น 5, 30, 2000',
                    hintStyle: TextStyle(
                      color: textSecondary.withValues(alpha: 0.6),
                    ),
                    prefixIcon: Icon(
                      Icons.flag_rounded,
                      color: isDark
                          ? AppTheme.primaryLightGreen
                          : const Color(0xFF2E5327),
                    ),
                    filled: true,
                    fillColor: cardBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: isDark
                            ? AppTheme.primaryLightGreen
                            : const Color(0xFF2E5327),
                        width: 1.8,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: TextFormField(
                  controller: unitController,
                  style: TextStyle(color: textPrimary),
                  decoration: InputDecoration(
                    labelText: 'หน่วยวัด',
                    labelStyle: TextStyle(color: textSecondary),
                    filled: true,
                    fillColor: cardBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: isDark
                            ? AppTheme.primaryLightGreen
                            : const Color(0xFF2E5327),
                        width: 1.8,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (showGpsSyncOption) ...[
            const SizedBox(height: 18),
            RoutineGpsSyncOption(
              isDark: isDark,
              isAutoLinked: isAutoLinked,
              surfaceBg: surfaceBg,
              borderColor: borderColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              cardBg: cardBg,
              selectedLinkedWorkout: selectedLinkedWorkout,
              autoDetected: autoDetected,
              onToggleAutoLink: onToggleAutoLink,
            ),
          ],
        ],
      ),
    );
  }
}
