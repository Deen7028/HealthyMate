// ส่วนนี้อธิบายบทบาทของไฟล์: วิดเจ็ตย่อยของ UI ในฟีเจอร์กิจวัตรและเป้าหมายประจำวัน (main goal template)
// คอมเมนท์ภาษาไทยถูกใส่ไว้เป็นส่วนๆ เพื่อช่วยไล่ flow โดยไม่เปลี่ยนพฤติกรรมเดิมของโค้ด

/// Data used to configure a predefined main goal in the selection sheet.
class MainGoalTemplate {
  final String title;
  final String icon;
  final String defaultUnit;
  final String linkedWorkout;
  final double defaultTarget;
  const MainGoalTemplate({
    required this.title,
    required this.icon,
    required this.defaultUnit,
    required this.linkedWorkout,
    required this.defaultTarget,
  });
}
