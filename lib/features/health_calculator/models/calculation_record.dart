// ส่วนนี้อธิบายบทบาทของไฟล์: โมเดลข้อมูล ในฟีเจอร์เครื่องคำนวณสุขภาพและบันทึกค่าสุขภาพ (calculation record)
// คอมเมนท์ภาษาไทยถูกใส่ไว้เป็นส่วนๆ เพื่อช่วยไล่ flow โดยไม่เปลี่ยนพฤติกรรมเดิมของโค้ด

import 'package:healthymate/core/utils/health_calculator.dart';

class TbCalculationHistory {
  final String id;
  final DateTime createdAt;
  final Gender gender;
  final int age;
  final double height;
  final double weight;
  final String activityLevelId;
  final String activityLevelTitle;
  final double bmi;
  final String bmiCategory;
  final double bmr;
  final double tdee;
  final int fatLossCalorie;
  final int maintainCalorie;
  final int muscleGainCalorie;

  TbCalculationHistory({
    required this.id,
    required this.createdAt,
    required this.gender,
    required this.age,
    required this.height,
    required this.weight,
    required this.activityLevelId,
    required this.activityLevelTitle,
    required this.bmi,
    required this.bmiCategory,
    required this.bmr,
    required this.tdee,
    required this.fatLossCalorie,
    required this.maintainCalorie,
    required this.muscleGainCalorie,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'createdAt': createdAt.toIso8601String(),
      'gender': gender.name,
      'age': age,
      'height': height,
      'weight': weight,
      'activityLevelId': activityLevelId,
      'activityLevelTitle': activityLevelTitle,
      'bmi': bmi,
      'bmiCategory': bmiCategory,
      'bmr': bmr,
      'tdee': tdee,
      'fatLossCalorie': fatLossCalorie,
      'maintainCalorie': maintainCalorie,
      'muscleGainCalorie': muscleGainCalorie,
    };
  }

  factory TbCalculationHistory.fromMap(Map<String, dynamic> map) {
    return TbCalculationHistory(
      id: map['id'] ?? '',
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      gender: map['gender'] == 'female' ? Gender.female : Gender.male,
      age: (map['age'] as num?)?.toInt() ?? 25,
      height: (map['height'] as num?)?.toDouble() ?? 170.0,
      weight: (map['weight'] as num?)?.toDouble() ?? 65.0,
      activityLevelId: map['activityLevelId'] ?? 'sedentary',
      activityLevelTitle: map['activityLevelTitle'] ?? '',
      bmi: (map['bmi'] as num?)?.toDouble() ?? 0.0,
      bmiCategory: map['bmiCategory'] ?? '',
      bmr: (map['bmr'] as num?)?.toDouble() ?? 0.0,
      tdee: (map['tdee'] as num?)?.toDouble() ?? 0.0,
      fatLossCalorie: (map['fatLossCalorie'] as num?)?.toInt() ?? 0,
      maintainCalorie: (map['maintainCalorie'] as num?)?.toInt() ?? 0,
      muscleGainCalorie: (map['muscleGainCalorie'] as num?)?.toInt() ?? 0,
    );
  }
}
