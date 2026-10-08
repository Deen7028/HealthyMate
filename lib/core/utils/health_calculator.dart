import 'package:flutter/material.dart';
import 'package:healthymate/shared/theme/app_theme.dart';

// เพศสำหรับใช้ในสูตรคำนวณสุขภาพ
enum Gender { male, female }

// คลาสยูทิลิตี้สำหรับคำนวณค่าสุขภาพ (BMI, BMR, TDEE, สัดส่วนร่างกาย และเป้าหมายแคลอรี)
class HealthCalculator {
  // 1. คำนวณดัชนีมวลกาย (BMI) - ระบบเมตริก: น้ำหนัก (กก.) / (ส่วนสูง (ม.) ^ 2)
  static double calculateBMI({required double weightKg, required double heightCm}) {
    if (heightCm <= 0 || weightKg <= 0) return 0.0;
    final heightM = heightCm / 100.0;
    return weightKg / (heightM * heightM);
  }

  // คำนวณดัชนีมวลกาย (BMI) - ระบบอิมพีเรียล: (น้ำหนัก (ปอนด์) / (ส่วนสูง (นิ้ว) ^ 2)) * 703
  static double calculateBMIImperial({required double weightLbs, required double heightInches}) {
    if (heightInches <= 0 || weightLbs <= 0) return 0.0;
    return (weightLbs / (heightInches * heightInches)) * 703.0;
  }

  // จำแนกเกณฑ์ระดับ BMI ตามมาตรฐานเอเชีย (Asian Standard) พร้อมป้ายสถานะ ช่วงค่า และสี
  static BMICategory getBMICategory(double bmi) {
    if (bmi < 18.5) {
      return const BMICategory(
        label: 'น้ำหนักน้อย / ผอม',
        badgeText: 'น้ำหนักน้อย',
        rangeText: '< 18.5',
        color: AppTheme.bmiUnderweight,
        index: 0,
      );
    } else if (bmi <= 22.9) {
      return const BMICategory(
        label: 'สมส่วน / ปกติ',
        badgeText: 'สมส่วน / ปกติ',
        rangeText: '18.5 - 22.9',
        color: AppTheme.bmiNormal,
        index: 1,
      );
    } else if (bmi <= 24.9) {
      return const BMICategory(
        label: 'น้ำหนักเกิน / ท้วม',
        badgeText: 'น้ำหนักเกิน',
        rangeText: '23.0 - 24.9',
        color: AppTheme.bmiOverweight,
        index: 2,
      );
    } else if (bmi <= 29.9) {
      return const BMICategory(
        label: 'อ้วนระดับ 1',
        badgeText: 'อ้วนระดับ 1',
        rangeText: '25.0 - 29.9',
        color: AppTheme.bmiObese,
        index: 3,
      );
    } else {
      return const BMICategory(
        label: 'อ้วนระดับ 2 / อันตราย',
        badgeText: 'อ้วนอันตราย',
        rangeText: '≥ 30.0',
        color: Color(0xFFD32F2F),
        index: 3,
      );
    }
  }

  // 2. คำนวณอัตราการเผาผลาญพลังงานพื้นฐาน (BMR) ตามสมการ Mifflin-St Jeor:
  // เพศชาย: (10 x น้ำหนัก กก.) + (6.25 x ส่วนสูง ซม.) - (5 x อายุ) + 5
  // เพศหญิง: (10 x น้ำหนัก กก.) + (6.25 x ส่วนสูง ซม.) - (5 x อายุ) - 161
  static double calculateBMR({
    required Gender gender,
    required double weightKg,
    required double heightCm,
    required int age,
  }) {
    if (weightKg <= 0 || heightCm <= 0 || age <= 0) return 0.0;
    final base = (10.0 * weightKg) + (6.25 * heightCm) - (5.0 * age);
    return gender == Gender.male ? (base + 5.0) : (base - 161.0);
  }

  // 3. คำนวณพลังงานที่ใช้ทั้งหมดต่อวัน (TDEE)
  // TDEE = BMR * ตัวคูณระดับกิจกรรม (activityMultiplier)
  // 1.2    - นั่งทำงานอยู่กับที่ ไม่ออกกำลังกาย
  // 1.375  - กิจกรรมเบาๆ (ออกกำลังกาย 1-3 วัน/สัปดาห์)
  // 1.55   - กิจกรรมปานกลาง (ออกกำลังกาย 3-5 วัน/สัปดาห์)
  // 1.725  - กิจกรรมหนัก (ออกกำลังกาย 6-7 วัน/สัปดาห์)
  // 1.9    - กิจกรรมหนักมาก (ออกกำลังกายวันละ 2 ครั้ง หรือทำงานใช้แรงงาน)
  static double calculateTDEE({required double bmr, required double activityMultiplier}) {
    return bmr * activityMultiplier;
  }

  // 4. คำนวณสัดส่วนร่างกายอื่นๆ
  // อัตราส่วนรอบเอวต่อส่วนสูง (Waist-to-Height Ratio: WHtR) = รอบเอว / ส่วนสูง
  static double calculateWaistToHeightRatio({required double waistCm, required double heightCm}) {
    if (heightCm <= 0 || waistCm <= 0) return 0.0;
    return waistCm / heightCm;
  }

  // อัตราส่วนรอบเอวต่อสะโพก (Waist-to-Hip Ratio: WHR) = รอบเอว / สะโพก
  static double calculateWaistToHipRatio({required double waistCm, required double hipCm}) {
    if (hipCm <= 0 || waistCm <= 0) return 0.0;
    return waistCm / hipCm;
  }

  // คำนวณค่า BMI Prime = BMI จริง / ค่าตัดบนมาตรฐาน (ค่าเริ่มต้น 23.0 สำหรับเอเชีย, 25.0 สำหรับ WHO)
  static double calculateBMIPrime({required double bmi, double upperCutoff = 23.0}) {
    if (upperCutoff <= 0 || bmi <= 0) return 0.0;
    return bmi / upperCutoff;
  }

  // คำนวณเป้าหมายแคลอรีต่อวัน (ลดน้ำหนัก / รักษาน้ำหนัก / เพิ่มกล้ามเนื้อ)
  static CalorieTargets calculateTargets(double tdee) {
    return CalorieTargets(
      fatLoss: (tdee - 500).round().clamp(1000, 10000),
      maintain: tdee.round(),
      muscleGain: (tdee + 300).round(),
    );
  }
}

// โมเดลสำหรับเก็บข้อมูลผลลัพธ์ระดับ BMI (ชื่อระดับ, ป้ายข้อความ, ช่วงเกณฑ์, สี, และดัชนี)
class BMICategory {
  final String label;
  final String badgeText;
  final String rangeText;
  final Color color;
  final int index; // 0..3 สำหรับไฮไลต์เกจแถบสี

  const BMICategory({
    required this.label,
    required this.badgeText,
    required this.rangeText,
    required this.color,
    required this.index,
  });
}

// โมเดลสำหรับเก็บเป้าหมายแคลอรีต่อวัน (ลดไขมัน, รักษาน้ำหนัก, เพิ่มกล้ามเนื้อ)
class CalorieTargets {
  final int fatLoss;
  final int maintain;
  final int muscleGain;

  const CalorieTargets({
    required this.fatLoss,
    required this.maintain,
    required this.muscleGain,
  });
}
