part of 'main_goal_card.dart';

// ส่วน Helper UI แสดงข้อมูลสถิติของเป้าหมายหลัก (_MainGoalCardStatUi)
// ใช้เรนเดอร์ไอเทมสถิติย่อย เช่น สถานะความคืบหน้า และเวลาที่เหลือ
extension _MainGoalCardStatUi on MainGoalCard {
  /// ฟังก์ชัน: สร้าง UI คอลัมน์แสดงสถิติย่อยของเป้าหมาย
  /// - [title]: ชื่อสถิติ (เช่น 'สถานะ', 'เหลือเวลา')
  /// - [value]: ค่าหลัก (เช่น 'กำลังดำเนินการ', 'อีก 5 วัน')
  /// - [primaryColor]: สีข้อความค่าหลัก
  /// - [secondaryColor]: สีข้อความชื่อสถิติและไอคอน
  /// - [icon]: ไอคอนประกอบ
  /// - [subValue]: ค่าเสริมเพิ่มเติม (เช่น วันที่สิ้นสุด 'สิ้นสุด 25/10/2569')
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
        // แถวไอคอน + ชื่อสถิติ
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

        // ข้อความค่าสถิติหลัก
        Text(
          value,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),

        // ข้อความค่าเสริมเพิ่มเติม (ถ้ามี)
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

