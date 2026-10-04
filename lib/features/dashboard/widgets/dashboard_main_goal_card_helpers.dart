// ส่วนนี้อธิบายบทบาทของไฟล์: วิดเจ็ตย่อยของ UI ในฟีเจอร์แดชบอร์ดสรุปสุขภาพและเป้าหมาย (dashboard main goal card helpers)
// คอมเมนท์ภาษาไทยถูกใส่ไว้เป็นส่วนๆ เพื่อช่วยไล่ flow โดยไม่เปลี่ยนพฤติกรรมเดิมของโค้ด

part of 'dashboard_main_goal_card.dart';

extension _DashboardMainGoalCardHelpers on DashboardMainGoalCard {
  String _formatNum(double val) =>
      val == val.toInt() ? val.toInt().toString() : val.toStringAsFixed(1);

  DateTime? _getGoalDeadline(
    Map<String, dynamic>? goal,
    Map<String, dynamic>? routine,
  ) {
    for (final source in [goal, routine]) {
      if (source == null) continue;
      for (final key in ['dtDeadline', 'deadlineDate']) {
        final value = source[key];
        if (value is DateTime) return value;
        if (value != null) {
          final parsed = DateTime.tryParse(value.toString());
          if (parsed != null) return parsed;
        }
      }
    }

    final remainingText = goal?['sRemainingText']?.toString() ?? '';
    final match = RegExp(
      r'(\d{1,2})/(\d{1,2})/(\d{4})',
    ).firstMatch(remainingText);
    if (match != null) {
      final day = int.parse(match.group(1)!);
      final month = int.parse(match.group(2)!);
      var year = int.parse(match.group(3)!);
      if (year > 2500) {
        year -= 543;
      }
      final parsed = DateTime.tryParse(
        '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}',
      );
      if (parsed != null) return parsed;
    }

    final rawCreatedAt = goal?['dtCreatedAt']?.toString();
    if (rawCreatedAt != null && rawCreatedAt.isNotEmpty) {
      final createdAt = DateTime.tryParse(rawCreatedAt);
      if (createdAt != null) {
        return createdAt.add(const Duration(days: 30));
      }
    } else if (goal != null) {
      return DateTime.now().add(const Duration(days: 30));
    }

    return null;
  }

  Color _getRoutineColor(Map<String, dynamic> routine, int index) {
    if (routine['color'] != null) {
      return Color((routine['color'] as num).toInt());
    }
    final title = routine['sTitle']?.toString().toLowerCase() ?? '';
    if (title.contains('น้ำ') ||
        title.contains('drink') ||
        title.contains('water')) {
      return const Color(0xFF0288D1);
    }
    if (title.contains('วิ่ง') ||
        title.contains('เดิน') ||
        title.contains('work')) {
      return const Color(0xFF4CAF50);
    }
    if (title.contains('สมาธิ') ||
        title.contains('นอน') ||
        title.contains('sleep')) {
      return const Color(0xFF7E57C2);
    }
    if (title.contains('อาหาร') ||
        title.contains('กิน') ||
        title.contains('eat')) {
      return const Color(0xFFFF9800);
    }
    if (title.contains('ยา') ||
        title.contains('pill') ||
        title.contains('health')) {
      return const Color(0xFFE91E63);
    }
    const defaultColors = [
      Color(0xFF0F9C58),
      Color(0xFF0288D1),
      Color(0xFFFF9800),
      Color(0xFF7E57C2),
      Color(0xFFE91E63),
    ];
    return defaultColors[index % defaultColors.length];
  }

  IconData _getRoutineIcon(Map<String, dynamic> routine, int index) {
    if (routine['iconData'] != null) {
      final int codePoint = (routine['iconData'] as num).toInt();
      return DashboardUiHelpers.iconFromCodePoint(codePoint, fallback: Icons.star_rounded);
    }
    final title = routine['sTitle']?.toString().toLowerCase() ?? '';
    if (title.contains('น้ำ') ||
        title.contains('drink') ||
        title.contains('water')) {
      return Icons.water_drop_rounded;
    }
    if (title.contains('วิ่ง') ||
        title.contains('เดิน') ||
        title.contains('work')) {
      return Icons.directions_walk_rounded;
    }
    if (title.contains('สมาธิ') ||
        title.contains('นอน') ||
        title.contains('sleep')) {
      return Icons.self_improvement_rounded;
    }
    if (title.contains('อาหาร') ||
        title.contains('กิน') ||
        title.contains('eat')) {
      return Icons.restaurant_rounded;
    }
    if (title.contains('ยา') ||
        title.contains('pill') ||
        title.contains('health')) {
      return Icons.medical_services_rounded;
    }
    const defaultIcons = [
      Icons.flag_rounded,
      Icons.alarm_rounded,
      Icons.star_rounded,
      Icons.favorite_rounded,
    ];
    return defaultIcons[index % defaultIcons.length];
  }

  Widget _buildGoalStatItem(
    String title,
    String value, {
    IconData? icon,
    String? subValue,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 12, color: Colors.grey),
              const SizedBox(width: 4),
            ],
            Text(
              title,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        if (subValue != null && subValue.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            subValue,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}
