import 'package:flutter/material.dart';
import 'package:healthymate/core/database/app_database.dart';
import 'package:healthymate/core/services/api_service.dart';
import 'package:healthymate/core/utils/health_calculator.dart';
import 'package:healthymate/features/health_calculator/models/activity_level.dart';
import 'package:healthymate/features/health_calculator/models/health_record_model.dart';
import 'package:healthymate/features/health_calculator/models/user_model.dart';

class HealthCalculatorState extends ChangeNotifier {
  final AppDatabase _db = AppDatabase.instance;

  // Active User in TbUsers
  TbUser _currentUser = TbUser(
    nUserId: 1,
    sEmail: 'user@healthymate.app',
    sPasswordHash: '',
    sFirstName: 'ผู้ใช้งาน',
    sLastName: '',
    nAge: 28,
    nHeight: 175.0,
    nWeight: 70.0,
    sGender: 'male',
    sActivityLevel: 'light',
  );

  // Form input state
  Gender _gender = Gender.male;
  int _age = 28;
  double _height = 175.0;
  double _weight = 70.0;
  ActivityLevel _activityLevel = ActivityLevel.options[1]; // light (1-3 days/week)

  // Calculated values
  double _bmi = 22.9;
  double _bmr = 1648.0;
  double _tdee = 2266.0;
  CalorieTargets _targets = const CalorieTargets(
    fatLoss: 1766,
    maintain: 2266,
    muscleGain: 2566,
  );
  late BMICategory _bmiCategory;

  // Synced profile data for Dashboard
  bool _isSyncedToDashboard = true;
  DateTime? _lastSyncedAt = DateTime.now();

  // Calculation History (TbHealthRecords)
  List<TbHealthRecord> _historyList = [];
  bool _isLoading = true;
  String _dataSource = "Database Server";

  HealthCalculatorState() {
    _bmiCategory = HealthCalculator.getBMICategory(22.9);
    loadData();
  }

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. พยายามดึงข้อมูลสดจาก PHP Database Server ก่อน
      final serverRecords = await HealthApiService.fetchHealthRecords(userId: 1);
      if (serverRecords.isNotEmpty) {
        _historyList = serverRecords;
        _dataSource = "PHP MySQL Server (172.18.111.42)";

        // ดึงค่าน้ำหนักล่าสุดจาก Database มาใส่ฟอร์ม
        final latest = serverRecords.first;
        _weight = latest.nWeight;
        _height = latest.nHeight;
      } else {
        // 2. ถ้าเซิร์ฟเวอร์ยังไม่เปิด ให้ดึงจาก Local Database Cache
        _historyList = await _db.getHealthRecords(userId: _currentUser.nUserId);
        _dataSource = "Local Database Cache";

        final user = await _db.getUser(userId: 1);
        if (user != null) {
          _currentUser = user;
          _gender = user.genderEnum;
          _age = user.nAge;
          _height = user.nHeight;
          _weight = user.nWeight;
          _activityLevel = user.activityLevelObj;
        }
      }

      // คำนวณผลลัพธ์จากข้อมูลจริงใน Database
      calculate(recordHistory: false, syncToDb: false);
    } catch (e) {
      debugPrint('Error loading state from database: $e');
    } finally {
      _isLoading = false;
      
    notifyListeners();
    }
  }

  // Getters
  TbUser get currentUser => _currentUser;
  Gender get gender => _gender;
  int get age => _age;
  double get height => _height;
  double get weight => _weight;
  ActivityLevel get activityLevel => _activityLevel;
  double get bmi => _bmi;
  double get bmr => _bmr;
  double get tdee => _tdee;
  CalorieTargets get targets => _targets;
  BMICategory get bmiCategory => _bmiCategory;
  bool get isSyncedToDashboard => _isSyncedToDashboard;
  DateTime? get lastSyncedAt => _lastSyncedAt;
  bool get isLoading => _isLoading;
  String get dataSource => _dataSource;
  List<TbHealthRecord> get historyList => List.unmodifiable(_historyList);

  // Setters / Actions
  void setGender(Gender gender) {
    if (_gender != gender) {
      _gender = gender;
      notifyListeners();
    }
  }

  void setAge(int age) {
    _age = age;
    notifyListeners();
  }

  void setHeight(double height) {
    _height = height;
    notifyListeners();
  }

  void setWeight(double weight) {
    _weight = weight;
    notifyListeners();
  }

  void setActivityLevel(ActivityLevel level) {
    _activityLevel = level;
    notifyListeners();
  }

  void calculate({bool recordHistory = false, bool syncToDb = false}) {
    final calculatedBmi = HealthCalculator.calculateBMI(
      weightKg: _weight,
      heightCm: _height,
    );

    final calculatedBmr = HealthCalculator.calculateBMR(
      gender: _gender,
      weightKg: _weight,
      heightCm: _height,
      age: _age,
    );

    final calculatedTdee = HealthCalculator.calculateTDEE(
      bmr: calculatedBmr,
      activityMultiplier: _activityLevel.multiplier,
    );

    _bmi = double.parse(calculatedBmi.toStringAsFixed(1));
    _bmr = calculatedBmr.roundToDouble();
    _tdee = calculatedTdee.roundToDouble();
    _bmiCategory = HealthCalculator.getBMICategory(_bmi);
    _targets = HealthCalculator.calculateTargets(_tdee);

    if (recordHistory) {
      final newRecord = TbHealthRecord(
        nRecordId: 0,
        nUserId: _currentUser.nUserId,
        nWeight: _weight,
        nHeight: _height,
        nBmi: _bmi,
        nTdee: _tdee,
        dtRecordedAt: DateTime.now(),
        computedBmr: _bmr,
        activityLevelTitle: _activityLevel.title,
      );

      _historyList.insert(0, newRecord);

      // บันทึกลง Local Database & ยิงไปบันทึกบน PHP Database Server
      _db.insertHealthRecord(newRecord);
      HealthApiService.saveHealthRecord(newRecord);
    }

    if (syncToDb) {
      _currentUser = TbUser(
        nUserId: _currentUser.nUserId,
        sEmail: _currentUser.sEmail,
        sPasswordHash: _currentUser.sPasswordHash,
        sFirstName: _currentUser.sFirstName,
        sLastName: _currentUser.sLastName,
        nAge: _age,
        nHeight: _height,
        nWeight: _weight,
        sGender: _gender.name,
        sActivityLevel: _activityLevel.id,
        isDarkMode: _currentUser.isDarkMode,
      );

      // อัปเดตลง Local Database & ส่งไปอัปเดตบน PHP Database Server
      _db.updateUser(_currentUser);
      HealthApiService.updateUserProfile(_currentUser);
    }

    notifyListeners();
  }

  void saveToProfileAndDashboard() {
    calculate(recordHistory: true, syncToDb: true);
    _isSyncedToDashboard = true;
    _lastSyncedAt = DateTime.now();
    notifyListeners();
  }

  Future<void> deleteHistoryItem(int recordId) async {
    _historyList.removeWhere((item) => item.nRecordId == recordId);
    notifyListeners();
    await _db.deleteHealthRecord(recordId);
  }
}
