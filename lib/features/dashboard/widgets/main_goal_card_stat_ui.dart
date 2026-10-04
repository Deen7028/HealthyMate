// ส่วนนี้อธิบายบทบาทของไฟล์: วิดเจ็ตย่อยของ UI ในฟีเจอร์แดชบอร์ดสรุปสุขภาพและเป้าหมาย (main goal card stat ui)
// คอมเมนท์ภาษาไทยถูกใส่ไว้เป็นส่วนๆ เพื่อช่วยไล่ flow โดยไม่เปลี่ยนพฤติกรรมเดิมของโค้ด

part of 'main_goal_card.dart';

extension _MainGoalCardStatUi on MainGoalCard {
  Widget _buildGoalStatItem(
    String title,
    String value,
    Color primaryColor,
    Color secondaryColor, {
    IconData? icon,
    String? subValue,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 12, color: secondaryColor),
              const SizedBox(width: 4),
            ],
            Text(title, style: TextStyle(fontSize: 10, color: secondaryColor)),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),
        if (subValue != null && subValue.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            subValue,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              color: secondaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}
