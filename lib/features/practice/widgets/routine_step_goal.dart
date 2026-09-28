import 'package:flutter/material.dart';
import 'package:healthymate/shared/theme/app_theme.dart';

class RoutineStepGoal extends StatelessWidget {
  final TextEditingController targetController;
  final TextEditingController unitController;
  final String? selectedLinkedWorkout;
  final String? autoDetected;
  final bool showGpsSyncOption;
  final ValueChanged<bool> onToggleAutoLink;
  final ValueChanged<String> onSelectUnit;

  const RoutineStepGoal({
    super.key,
    required this.targetController,
    required this.unitController,
    required this.selectedLinkedWorkout,
    required this.autoDetected,
    this.showGpsSyncOption = true,
    required this.onToggleAutoLink,
    required this.onSelectUnit,
  });

  @override
  Widget build(BuildContext context) {
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
                _buildQuickUnitButton('กม.', 'ระยะทาง', isDark, textPrimary, textSecondary),
                _buildQuickUnitButton('นาที', 'เวลา', isDark, textPrimary, textSecondary),
                _buildQuickUnitButton('ครั้ง', 'จำนวน', isDark, textPrimary, textSecondary),
                _buildQuickUnitButton('มล.', 'โภชนาการ', isDark, textPrimary, textSecondary),
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
                    hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.6)),
                    prefixIcon: Icon(
                      Icons.flag_rounded,
                      color: isDark ? AppTheme.primaryLightGreen : const Color(0xFF2E5327),
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
                        color: isDark ? AppTheme.primaryLightGreen : const Color(0xFF2E5327),
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
                        color: isDark ? AppTheme.primaryLightGreen : const Color(0xFF2E5327),
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
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isAutoLinked
                    ? (isDark ? const Color(0xFF23352A) : const Color(0xFFE8F3EB))
                    : surfaceBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isAutoLinked
                      ? (isDark ? AppTheme.primaryLightGreen : const Color(0xFF2E5327))
                      : borderColor,
                  width: 1.2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              Icons.link_rounded,
                              color: isAutoLinked
                                  ? (isDark ? AppTheme.primaryLightGreen : const Color(0xFF2E5327))
                                  : textSecondary,
                              size: 22,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                '🔗 เชื่อมโยงข้อมูล GPS ออกกำลังกายอัตโนมัติ',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isAutoLinked
                                      ? (isDark ? AppTheme.primaryLightGreen : const Color(0xFF2E5327))
                                      : textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: isAutoLinked,
                        onChanged: onToggleAutoLink,
                        activeThumbColor: isDark ? AppTheme.primaryLightGreen : const Color(0xFF2E5327),
                      ),
                    ],
                  ),
                  if (isAutoLinked) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.bolt_rounded,
                              size: 16, color: Colors.orange),
                          const SizedBox(width: 6),
                          Text(
                            'ตรวจจับกิจกรรม: "${selectedLinkedWorkout ?? autoDetected}" Auto Sync',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppTheme.primaryLightGreen : const Color(0xFF2E5327),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickUnitButton(String unit, String label, bool isDark, Color textPrimary, Color textSecondary) {
    final isSelected = unitController.text.trim() == unit;
    return Expanded(
      child: GestureDetector(
        onTap: () => onSelectUnit(unit),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? const Color(0xFF2E5327) : const Color(0xFF2E5327))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Text(
                unit,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : textPrimary,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: isSelected ? Colors.white70 : textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
