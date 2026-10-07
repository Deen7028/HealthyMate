import 'dart:async';
import 'package:flutter/material.dart';
import 'package:healthymate/core/database/app_database.dart';
import 'package:healthymate/core/services/api_service.dart';
import 'package:healthymate/core/services/auth_service.dart';
import 'package:healthymate/core/utils/health_calculator.dart';
import 'package:healthymate/core/services/routine_state/routine_state_notifier.dart';
import 'package:healthymate/features/health_calculator/models/activity_level.dart';
import 'package:healthymate/features/health_calculator/models/health_record_model.dart';
import 'package:healthymate/features/health_calculator/models/user_model.dart';

part 'health_calculator_controller_loading.dart';
part 'health_calculator_controller_inputs.dart';
part 'health_calculator_controller_calculation.dart';
part 'health_calculator_controller_persistence.dart';

// คอนโทรลเลอร์คำนวณสุขภาพ (HealthCalculatorController)
// ทำหน้าที่คำนวณ BMI, BMR, TDEE และเป้าหมายแคลอรี พร้อมบันทึกประวัติสุขภาพลง Local DB และเซิร์ฟเวอร์
class HealthCalculatorController extends ChangeNotifier {
  final AppDatabase _db = AppDatabase.instance;
  bool _isDisposed = false;

  // 1. ข้อมูลผู้ใช้ปัจจุบันในระบบ
  TbUser? _currentUser;

  // 2. ค่าอินพุตสำหรับคำนวณ (เพศ, อายุ, ส่วนสูง, น้ำหนัก, ระดับกิจกรรม)
  Gender _gender = Gender.male;
  int _age = 0;
  double _height = 0.0;
  double _weight = 0.0;
  ActivityLevel _activityLevel =
      ActivityLevel.options[1]; // ค่าเริ่มต้น: ออกกำลังกายเบาๆ 1-3 วัน/สัปดาห์

  // 3. ผลลัพธ์จากการคำนวณ (BMI, BMR, TDEE, Calorie Targets)
  double _bmi = 0.0;
  double _bmr = 0.0;
  double _tdee = 0.0;
  CalorieTargets _targets = const CalorieTargets(
    fatLoss: 0,
    maintain: 0,
    muscleGain: 0,
  );
  late BMICategory _bmiCategory;

  // 4. สถานะการซิงค์ข้อมูลกับ Dashboard
  bool _isSyncedToDashboard = false;
  DateTime? _lastSyncedAt;

  // 5. ประวัติการบันทึกสุขภาพ (TbHealthRecords) และสถานะการโหลด
  List<TbHealthRecord> _historyList = [];
  bool _isLoading = true;
  String _dataSource = "Database Server";

  HealthCalculatorController() {
    _bmiCategory = HealthCalculator.getBMICategory(0.0);
    loadData();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  // ฟังก์ชัน: แจ้งเตือนผู้ฟัง (Listeners) อย่างปลอดภัย
  void _safeNotifyListeners() {
    if (!_isDisposed && hasListeners) {
      notifyListeners();
    }
  }
}
