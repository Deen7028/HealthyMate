import 'package:flutter/material.dart';
import 'package:healthymate/shared/theme/app_theme.dart';

class RoutineStepStyle extends StatefulWidget {
  final Color btnColor;
  final bool isNotificationEnabled;
  final TextEditingController notificationTimeController;
  final ValueChanged<bool> onToggleNotification;
  final IconData? selectedIcon;
  final Color? selectedColor;
  final List<IconData> availableIcons;
  final List<Color> availableColors;
  final ValueChanged<IconData?> onSelectIcon;
  final ValueChanged<Color?> onSelectColor;

  const RoutineStepStyle({
    super.key,
    required this.btnColor,
    required this.isNotificationEnabled,
    required this.notificationTimeController,
    required this.onToggleNotification,
    required this.selectedIcon,
    required this.selectedColor,
    required this.availableIcons,
    required this.availableColors,
    required this.onSelectIcon,
    required this.onSelectColor,
  });

  @override
  State<RoutineStepStyle> createState() => _RoutineStepStyleState();
}

class _RoutineStepStyleState extends State<RoutineStepStyle> {
  int _selectedModeIndex = 0; // 0: เวลาเดียว, 1: หลายช่วงเวลา, 2: ความถี่
  List<String> _multipleTimes = ['08:00', '12:00', '18:00'];
  String _selectedInterval = 'ทุก 2 ชั่วโมง';

  final List<String> _intervalOptions = [
    'ทุก 1 ชั่วโมง',
    'ทุก 2 ชั่วโมง',
    'ทุก 3 ชั่วโมง',
    'ทุก 4 ชั่วโมง',
  ];

  @override
  void initState() {
    super.initState();
    _parseInitialNotificationText();
  }

  void _parseInitialNotificationText() {
    final text = widget.notificationTimeController.text.trim();
    if (text.startsWith('ทุก ')) {
      _selectedModeIndex = 2;
      if (_intervalOptions.contains(text)) {
        _selectedInterval = text;
      }
    } else if (text.contains(',')) {
      _selectedModeIndex = 1;
      final parts = text.split(',').map((e) => e.replaceAll('น.', '').trim()).where((e) => e.isNotEmpty).toList();
      if (parts.isNotEmpty) {
        _multipleTimes = parts;
      }
    } else {
      _selectedModeIndex = 0;
    }
  }

  void _updateControllerText() {
    if (_selectedModeIndex == 0) {
      if (widget.notificationTimeController.text.isEmpty ||
          widget.notificationTimeController.text.startsWith('ทุก ') ||
          widget.notificationTimeController.text.contains(',')) {
        widget.notificationTimeController.text = '08:00 น.';
      }
    } else if (_selectedModeIndex == 1) {
      widget.notificationTimeController.text = _multipleTimes.map((t) => '$t น.').join(', ');
    } else if (_selectedModeIndex == 2) {
      widget.notificationTimeController.text = _selectedInterval;
    }
  }

  Future<TimeOfDay?> _pickTime(TimeOfDay initialTime) async {
    return await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: widget.btnColor,
              onPrimary: Colors.white,
              onSurface: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          child: child!,
        );
      },
    );
  }

  Widget _buildNotificationModeSelector(bool isDark, Color cardBg, Color borderColor, Color textPrimary, Color textSecondary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildModeTab(0, 'เวลาเดียว', Icons.access_time_rounded, isDark, cardBg, borderColor, textPrimary, textSecondary),
            const SizedBox(width: 6),
            _buildModeTab(1, 'หลายเวลา', Icons.more_time_rounded, isDark, cardBg, borderColor, textPrimary, textSecondary),
            const SizedBox(width: 6),
            _buildModeTab(2, 'ความถี่', Icons.update_rounded, isDark, cardBg, borderColor, textPrimary, textSecondary),
          ],
        ),
        const SizedBox(height: 12),
        if (_selectedModeIndex == 0) _buildSingleTimeMode(isDark, cardBg, borderColor, textPrimary),
        if (_selectedModeIndex == 1) _buildMultipleTimesMode(isDark, cardBg, borderColor, textPrimary, textSecondary),
        if (_selectedModeIndex == 2) _buildIntervalMode(isDark, cardBg, borderColor, textPrimary, textSecondary),
      ],
    );
  }

  Widget _buildModeTab(int index, String label, IconData icon, bool isDark, Color cardBg, Color borderColor, Color textPrimary, Color textSecondary) {
    final isSelected = _selectedModeIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedModeIndex = index;
            _updateControllerText();
          });
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? widget.btnColor : cardBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? widget.btnColor : borderColor,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected ? Colors.white : textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSingleTimeMode(bool isDark, Color cardBg, Color borderColor, Color textPrimary) {
    final currentText = widget.notificationTimeController.text.trim();
    final timeDisplay = (currentText.isNotEmpty && !currentText.startsWith('ทุก ') && !currentText.contains(','))
        ? currentText
        : '08:00 น.';

    return InkWell(
      onTap: () async {
        TimeOfDay initialTime = const TimeOfDay(hour: 8, minute: 0);
        final match = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(timeDisplay);
        if (match != null) {
          initialTime = TimeOfDay(
            hour: int.parse(match.group(1)!),
            minute: int.parse(match.group(2)!),
          );
        }
        final picked = await _pickTime(initialTime);
        if (picked != null) {
          final formattedHour = picked.hour.toString().padLeft(2, '0');
          final formattedMinute = picked.minute.toString().padLeft(2, '0');
          setState(() {
            widget.notificationTimeController.text = '$formattedHour:$formattedMinute น.';
          });
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.access_time_filled_rounded,
                  color: widget.btnColor,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  timeDisplay,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: widget.btnColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'เปลี่ยนเวลา',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: widget.btnColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMultipleTimesMode(bool isDark, Color cardBg, Color borderColor, Color textPrimary, Color textSecondary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ..._multipleTimes.asMap().entries.map((entry) {
              final idx = entry.key;
              final timeStr = entry.value;
              return InkWell(
                onTap: () async {
                  TimeOfDay initialTime = const TimeOfDay(hour: 8, minute: 0);
                  final match = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(timeStr);
                  if (match != null) {
                    initialTime = TimeOfDay(
                      hour: int.parse(match.group(1)!),
                      minute: int.parse(match.group(2)!),
                    );
                  }
                  final picked = await _pickTime(initialTime);
                  if (picked != null) {
                    final formattedHour = picked.hour.toString().padLeft(2, '0');
                    final formattedMinute = picked.minute.toString().padLeft(2, '0');
                    setState(() {
                      _multipleTimes[idx] = '$formattedHour:$formattedMinute';
                      _updateControllerText();
                    });
                  }
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: widget.btnColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: widget.btnColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$timeStr น.',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: widget.btnColor,
                        ),
                      ),
                      if (_multipleTimes.length > 1) ...[
                        const SizedBox(width: 4),
                        InkWell(
                          onTap: () {
                            setState(() {
                              _multipleTimes.removeAt(idx);
                              _updateControllerText();
                            });
                          },
                          child: Icon(
                            Icons.close_rounded,
                            size: 14,
                            color: widget.btnColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
            InkWell(
              onTap: () async {
                final picked = await _pickTime(const TimeOfDay(hour: 12, minute: 0));
                if (picked != null) {
                  final formattedHour = picked.hour.toString().padLeft(2, '0');
                  final formattedMinute = picked.minute.toString().padLeft(2, '0');
                  setState(() {
                    _multipleTimes.add('$formattedHour:$formattedMinute');
                    _updateControllerText();
                  });
                }
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2E3D34) : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, size: 16, color: textPrimary),
                    const SizedBox(width: 2),
                    Text(
                      'เพิ่มเวลา',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildIntervalMode(bool isDark, Color cardBg, Color borderColor, Color textPrimary, Color textSecondary) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _intervalOptions.contains(_selectedInterval) ? _selectedInterval : _intervalOptions.first,
          dropdownColor: cardBg,
          isExpanded: true,
          icon: Icon(Icons.arrow_drop_down_rounded, color: textSecondary),
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _selectedInterval = val;
                _updateControllerText();
              });
            }
          },
          items: _intervalOptions.map((opt) {
            return DropdownMenuItem<String>(
              value: opt,
              child: Row(
                children: [
                  Icon(Icons.sync_rounded, size: 18, color: widget.btnColor),
                  const SizedBox(width: 10),
                  Text(
                    opt,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = AppTheme.getTextPrimaryColor(isDark);
    final textSecondary = AppTheme.getTextSecondaryColor(isDark);
    final cardBg = AppTheme.getBackgroundColor(isDark);
    final borderColor = AppTheme.getBorderColor(isDark);
    final surfaceBg = AppTheme.getSurfaceColor(isDark);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step 3: การแจ้งเตือนและธีมกิจวัตร 🔔🎨',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: surfaceBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          widget.isNotificationEnabled
                              ? Icons.notifications_active_rounded
                              : Icons.notifications_off_rounded,
                          color: widget.isNotificationEnabled
                              ? (isDark ? Colors.amberAccent : Colors.amber.shade800)
                              : textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'การแจ้งเตือนประจำวัน',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: textPrimary,
                          ),
                        ),
                      ],
                    ),
                    Switch(
                      value: widget.isNotificationEnabled,
                      onChanged: widget.onToggleNotification,
                      activeThumbColor: widget.btnColor,
                    ),
                  ],
                ),
                if (widget.isNotificationEnabled) ...[
                  const SizedBox(height: 12),
                  Text(
                    'รูปแบบการแจ้งเตือน',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildNotificationModeSelector(isDark, cardBg, borderColor, textPrimary, textSecondary),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'ไอคอน:',
                style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: widget.availableIcons.length + 1,
                    separatorBuilder: (ctx, idx) => const SizedBox(width: 6),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        final isSelected = widget.selectedIcon == null;
                        return InkWell(
                          onTap: () => widget.onSelectIcon(null),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? (isDark ? const Color(0xFF354E3C) : Colors.grey.shade300)
                                  : (isDark ? surfaceBg : Colors.grey.shade100),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? (isDark ? AppTheme.primaryLightGreen : Colors.grey.shade700)
                                    : borderColor,
                              ),
                            ),
                            child: Icon(Icons.block,
                                size: 18, color: textSecondary),
                          ),
                        );
                      }
                      final icon = widget.availableIcons[index - 1];
                      final isSelected = icon == widget.selectedIcon;
                      return InkWell(
                        onTap: () => widget.onSelectIcon(icon),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? widget.btnColor.withAlpha(50)
                                : (isDark ? surfaceBg : Colors.grey.shade100),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? widget.btnColor : Colors.transparent,
                            ),
                          ),
                          child: Icon(
                            icon,
                            size: 18,
                            color: isSelected ? widget.btnColor : textSecondary,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                'สีประจำ:',
                style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 34,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: widget.availableColors.length + 1,
                    separatorBuilder: (ctx, idx) => const SizedBox(width: 6),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        final isSelected = widget.selectedColor == null;
                        return GestureDetector(
                          onTap: () => widget.onSelectColor(null),
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: cardBg,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? textPrimary
                                    : borderColor,
                              ),
                            ),
                            child: Icon(
                              Icons.format_color_reset_rounded,
                              size: 16,
                              color: textSecondary,
                            ),
                          ),
                        );
                      }
                      final color = widget.availableColors[index - 1];
                      final isSelected = color == widget.selectedColor;
                      return GestureDetector(
                        onTap: () => widget.onSelectColor(color),
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? (isDark ? Colors.white : Colors.black)
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: isSelected
                              ? const Icon(Icons.check,
                                  size: 16, color: Colors.white)
                              : null,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
