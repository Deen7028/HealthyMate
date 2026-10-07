import 'package:flutter/material.dart';
import 'package:healthymate/features/workout/models/workout_models.dart';

class WorkoutMapTypeSelector {
  static void openMapTypeSelector({
    required BuildContext context,
    required AppMapType currentType,
    required bool showTraffic,
    required ValueChanged<AppMapType> onSelectType,
    required ValueChanged<bool> onToggleTraffic,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'ประเภทแผนที่ (Map Type)',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1C2819),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: AppMapType.values.map((type) {
                  final isSelected = currentType == type;
                  return GestureDetector(
                    onTap: () {
                      onSelectType(type);
                      setSheetState(() {});
                      Navigator.of(ctx).pop();
                    },
                    child: Column(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: getMapTypePreviewColor(type),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF2E5327)
                                  : const Color(0xFFE2E9E0),
                              width: isSelected ? 3 : 1.2,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF2E5327,
                                      ).withValues(alpha: 0.25),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Icon(
                            type.icon,
                            color:
                                type == AppMapType.satellite ||
                                    type == AppMapType.hybrid
                                ? Colors.white
                                : const Color(0xFF2E5327),
                            size: 32,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          getShortMapName(type),
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected
                                ? const Color(0xFF2E5327)
                                : const Color(0xFF5A665A),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),
              const Divider(height: 1, color: Color(0xFFE8EFE8)),
              const SizedBox(height: 14),

              const Text(
                'รายละเอียดแผนที่เพิ่มเติม',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1C2819),
                ),
              ),
              const SizedBox(height: 8),

              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeThumbColor: const Color(0xFF2E5327),
                secondary: const Icon(
                  Icons.traffic_rounded,
                  color: Color(0xFF2E5327),
                ),
                title: const Text(
                  'เส้นทางการจราจร (Traffic)',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'แสดงสภาพการจราจรแบบเรียลไทม์บนเส้นทาง',
                  style: TextStyle(fontSize: 12, color: Color(0xFF7A887A)),
                ),
                value: showTraffic,
                onChanged: (val) {
                  onToggleTraffic(val);
                  setSheetState(() {});
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Color getMapTypePreviewColor(AppMapType type) {
    switch (type) {
      case AppMapType.standard:
        return const Color(0xFFE3EDE1);
      case AppMapType.satellite:
        return const Color(0xFF213A28);
      case AppMapType.hybrid:
        return const Color(0xFFDED0B6);
    }
  }

  static String getShortMapName(AppMapType type) {
    switch (type) {
      case AppMapType.standard:
        return 'เริ่มต้น';
      case AppMapType.satellite:
        return 'ดาวเทียม';
      case AppMapType.hybrid:
        return 'ไฮบริด';
    }
  }
}
