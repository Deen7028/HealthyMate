import 'package:flutter/material.dart';
import 'package:healthymate/core/theme/app_theme.dart';

enum Gender { male, female }

class HealthCalculator {
  /// Calculate Body Mass Index (BMI)
  /// BMI = weight (kg) / (height (m) ^ 2)
  static double calculateBMI({required double weightKg, required double heightCm}) {
    if (heightCm <= 0 || weightKg <= 0) return 0.0;
    final heightM = heightCm / 100.0;
    return weightKg / (heightM * heightM);
  }

  /// Get BMI Category name and color
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

  /// Calculate Basal Metabolic Rate (BMR) using Mifflin-St Jeor equation:
  /// Male: (10 x weight in kg) + (6.25 x height in cm) - (5 x age in years) + 5
  /// Female: (10 x weight in kg) + (6.25 x height in cm) - (5 x age in years) - 161
  static double calculateBMR({
    required Gender gender,
    required double weightKg,
    required double heightCm,
    required int age,
  }) {
    if (weightKg <= 0 || heightCm <= 0 || age <= 0) return 0.0;
    final base = (10 * weightKg) + (6.25 * heightCm) - (5 * age);
    return gender == Gender.male ? (base + 5) : (base - 161);
  }

  /// Calculate Total Daily Energy Expenditure (TDEE)
  /// TDEE = BMR * activityMultiplier
  static double calculateTDEE({required double bmr, required double activityMultiplier}) {
    return bmr * activityMultiplier;
  }

  /// Calorie targets calculation
  static CalorieTargets calculateTargets(double tdee) {
    return CalorieTargets(
      fatLoss: (tdee - 500).round().clamp(1000, 10000),
      maintain: tdee.round(),
      muscleGain: (tdee + 300).round(),
    );
  }
}

class BMICategory {
  final String label;
  final String badgeText;
  final String rangeText;
  final Color color;
  final int index; // 0..3 for bar highlight

  const BMICategory({
    required this.label,
    required this.badgeText,
    required this.rangeText,
    required this.color,
    required this.index,
  });
}

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
