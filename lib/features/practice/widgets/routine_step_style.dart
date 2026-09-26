import 'package:flutter/material.dart';

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
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Step 3: การแจ้งเตือนและธีมกิจวัตร 🔔🎨',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
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
                              ? Colors.amber.shade800
                              : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'การแจ้งเตือนประจำวัน',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
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
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: () async {
                      final currentText = widget.notificationTimeController.text.trim();
                      TimeOfDay initialTime = const TimeOfDay(hour: 8, minute: 0);
                      final match = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(currentText);
                      if (match != null) {
                        initialTime = TimeOfDay(
                          hour: int.parse(match.group(1)!),
                          minute: int.parse(match.group(2)!),
                        );
                      }

                      final picked = await showTimePicker(
                        context: context,
                        initialTime: initialTime,
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: ColorScheme.light(
                                primary: widget.btnColor,
                                onPrimary: Colors.white,
                                onSurface: const Color(0xFF1E293B),
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );

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
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.access_time_filled_rounded,
                                color: Color(0xFF2E5327),
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                widget.notificationTimeController.text.isNotEmpty
                                    ? widget.notificationTimeController.text
                                    : '08:00 น.',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F3EB),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'เลือกเวลา',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2E5327),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('ไอคอน:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
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
                                  ? Colors.grey.shade300
                                  : Colors.grey.shade100,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? Colors.grey.shade700
                                    : Colors.grey.shade300,
                              ),
                            ),
                            child: const Icon(Icons.block,
                                size: 18, color: Colors.grey),
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
                                : Colors.grey.shade100,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? widget.btnColor : Colors.transparent,
                            ),
                          ),
                          child: Icon(
                            icon,
                            size: 18,
                            color: isSelected ? widget.btnColor : Colors.grey.shade700,
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
              const Text('สีประจำ:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
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
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? Colors.black
                                    : Colors.grey.shade300,
                              ),
                            ),
                            child: const Icon(
                              Icons.format_color_reset_rounded,
                              size: 16,
                              color: Colors.grey,
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
                                  ? Colors.black
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
