// ส่วนนี้อธิบายบทบาทของไฟล์: โมเดลข้อมูล ในฟีเจอร์ขั้นตอนเริ่มต้นใช้งานและตั้งค่าเป้าหมาย (onboarding goal template)
// คอมเมนท์ภาษาไทยถูกใส่ไว้เป็นส่วนๆ เพื่อช่วยไล่ flow โดยไม่เปลี่ยนพฤติกรรมเดิมของโค้ด

class OnboardingGoalTemplate {
  final String id;
  final String title;
  final String description;
  final String icon;
  final String unit;
  final double targetValue;
  final String linkedWorkout;
  final int days;

  const OnboardingGoalTemplate({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.unit,
    required this.targetValue,
    required this.linkedWorkout,
    this.days = 30,
  });

  static const List<OnboardingGoalTemplate> templates = [
    OnboardingGoalTemplate(
      id: 'running_5k',
      title: 'วิ่งสะสมระยะทาง 5 กม.',
      description: 'เริ่มต้นวิ่งเพื่อสุขภาพหัวใจที่แข็งแรง เชื่อมต่อ GPS เรียลไทม์',
      icon: '🏃',
      unit: 'กม.',
      targetValue: 5.0,
      linkedWorkout: 'วิ่ง',
      days: 14,
    ),
    OnboardingGoalTemplate(
      id: 'burn_500kcal',
      title: 'เผาผลาญพลังงานครบ 500 kcal',
      description: 'เบิร์นไขมันและสร้างความกระปรี้กระเปร่าให้กับร่างกาย',
      icon: '🔥',
      unit: 'แคล',
      targetValue: 500.0,
      linkedWorkout: 'แคลอรี',
      days: 7,
    ),
    OnboardingGoalTemplate(
      id: 'drink_water_2000',
      title: 'ดื่มน้ำครบ 2,000 มล. ต่อวัน',
      description: 'รักษาสมดุลน้ำในร่างกายเพื่อผิวพรรณและการเผาผลาญที่ดี',
      icon: '💧',
      unit: 'มล.',
      targetValue: 2000.0,
      linkedWorkout: 'ดื่มน้ำ',
      days: 30,
    ),
    OnboardingGoalTemplate(
      id: 'meditation_relax',
      title: 'ทำสมาธิผ่อนคลายความเครียด',
      description: 'สร้างความสงบและสมาธิให้จิตใจสะสมครบ 60 นาที',
      icon: '🧘',
      unit: 'นาที',
      targetValue: 60.0,
      linkedWorkout: 'ทำสมาธิ',
      days: 14,
    ),
  ];
}
