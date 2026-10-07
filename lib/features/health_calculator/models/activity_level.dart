class ActivityLevel {
  final String id;
  final String title;
  final String description;
  final double multiplier;

  const ActivityLevel({
    required this.id,
    required this.title,
    required this.description,
    required this.multiplier,
  });

  static const List<ActivityLevel> options = [
    ActivityLevel(
      id: 'sedentary',
      title: 'ไม่ออกกำลังกายเลย',
      description: 'นั่งทำงานอยู่กับที่เป็นส่วนใหญ่',
      multiplier: 1.2,
    ),
    ActivityLevel(
      id: 'light',
      title: 'ออกกำลังกายเบาๆ',
      description: '1-3 วัน / สัปดาห์ (เดินเร็ว, โยคะเบาๆ)',
      multiplier: 1.375,
    ),
    ActivityLevel(
      id: 'moderate',
      title: 'ออกกำลังกายปานกลาง',
      description: '3-5 วัน / สัปดาห์ (เวทเทรนนิ่ง, วิ่ง)',
      multiplier: 1.55,
    ),
    ActivityLevel(
      id: 'heavy',
      title: 'ออกกำลังกายหนัก',
      description: '6-7 วัน / สัปดาห์ หรือนักกีฬา',
      multiplier: 1.725,
    ),
    ActivityLevel(
      id: 'very_heavy',
      title: 'ออกกำลังกายหนักมาก',
      description: 'ฝึกซ้อม 2 เวลา / ทำงานใช้แรงงานหนัก',
      multiplier: 1.9,
    ),
  ];
}

