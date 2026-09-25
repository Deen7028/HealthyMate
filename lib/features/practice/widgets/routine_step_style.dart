import 'package:flutter/material.dart';

class RoutineStepStyle extends StatelessWidget {
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
                          isNotificationEnabled
                              ? Icons.notifications_active_rounded
                              : Icons.notifications_off_rounded,
                          color: isNotificationEnabled
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
                      value: isNotificationEnabled,
                      onChanged: onToggleNotification,
                      activeThumbColor: btnColor,
                    ),
                  ],
                ),
                if (isNotificationEnabled) ...[
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: notificationTimeController,
                    decoration: InputDecoration(
                      labelText: 'เวลา / ความถี่การแจ้งเตือน',
                      hintText: 'เช่น 08:00 น. หรือ ทุก 2 ชั่วโมง',
                      prefixIcon: const Icon(Icons.access_time_rounded),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
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
                    itemCount: availableIcons.length + 1,
                    separatorBuilder: (ctx, idx) => const SizedBox(width: 6),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        final isSelected = selectedIcon == null;
                        return InkWell(
                          onTap: () => onSelectIcon(null),
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
                      final icon = availableIcons[index - 1];
                      final isSelected = icon == selectedIcon;
                      return InkWell(
                        onTap: () => onSelectIcon(icon),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? btnColor.withAlpha(50)
                                : Colors.grey.shade100,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? btnColor : Colors.transparent,
                            ),
                          ),
                          child: Icon(
                            icon,
                            size: 18,
                            color: isSelected ? btnColor : Colors.grey.shade700,
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
                    itemCount: availableColors.length + 1,
                    separatorBuilder: (ctx, idx) => const SizedBox(width: 6),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        final isSelected = selectedColor == null;
                        return GestureDetector(
                          onTap: () => onSelectColor(null),
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
                      final color = availableColors[index - 1];
                      final isSelected = color == selectedColor;
                      return GestureDetector(
                        onTap: () => onSelectColor(color),
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
