import 'dart:async';
import 'package:flutter/material.dart';
import 'package:healthymate/core/database/app_database.dart';
import 'package:healthymate/core/services/api_service.dart';
import 'package:healthymate/core/services/auth_service.dart';
import 'package:healthymate/core/services/sync_service.dart';
import 'package:healthymate/core/utils/health_calculator.dart';
import 'package:healthymate/features/health_calculator/models/activity_level.dart';
import 'package:healthymate/features/health_calculator/models/health_record_model.dart';
import 'package:healthymate/features/health_calculator/models/user_model.dart';

class HealthCalculatorController extends ChangeNotifier {
  final AppDatabase _db = AppDatabase.instance;
  bool _isDisposed = false;

  // Active User in TbUsers (starts unpopulated until loadData)
  TbUser? _currentUser;

  // Form input state
  Gender _gender = Gender.male;
  int _age = 0;
  double _height = 0.0;
  double _weight = 0.0;
  ActivityLevel _activityLevel = ActivityLevel.options[1]; // light (1-3 days/week)

  // Calculated values
  double _bmi = 0.0;
  double _bmr = 0.0;
  double _tdee = 0.0;
  CalorieTargets _targets = const CalorieTargets(
    fatLoss: 0,
    maintain: 0,
    muscleGain: 0,
  );
  late BMICategory _bmiCategory;

  // Synced profile data for Dashboard
  bool _isSyncedToDashboard = false;
  DateTime? _lastSyncedAt;

  // Calculation History (TbHealthRecords)
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

  void _safeNotifyListeners() {
    if (!_isDisposed && hasListeners) {
      notifyListeners();
    }
  }

  Future<void> loadData() async {
    _isLoading = true;
    _safeNotifyListeners();

    try {
      // 1. ระบุผู้ใช้ปัจจุบันจาก Session / AuthService
      String? loggedInEmail = AuthService.instance.currentUserEmail;
      if (loggedInEmail.isEmpty) {
        loggedInEmail = await _db.getLoggedInUserEmail();
      }

      TbUser? user;
      if (loggedInEmail != null && loggedInEmail.isNotEmpty) {
        user = await _db.getUserByEmail(loggedInEmail);
      }

      // ป้องกันช่องโหว่ Hardcode User ID: หากไม่มี valid user ให้ logout
      if (user == null) {
        debugPrint('HealthCalculatorState: No valid authenticated user found, forcing logout.');
        await AuthService.instance.logout();
        return;
      }

      _currentUser = user;
      _gender = user.genderEnum;
      _age = user.nAge ?? 0;
      _height = user.nHeight ?? 0.0;
      _weight = user.nWeight ?? 0.0;
      _activityLevel = user.activityLevelObj;

      final activeUserId = user.nUserId;

      // 2. ดึงประวัติสุขภาพของคนนั้นๆ (แยกตาม userId)
      final serverRecords = await HealthApiService.fetchHealthRecords(userId: activeUserId);
      if (serverRecords.isNotEmpty) {
        _historyList = serverRecords;
        _dataSource = "PHP MySQL Server";

        // ดึงค่าน้ำหนักล่าสุดจาก Database มาใส่ฟอร์ม
        final latest = serverRecords.first;
        if (latest.nWeight > 0) _weight = latest.nWeight;
        if (latest.nHeight > 0) _height = latest.nHeight;
      } else {
        // ดึงจาก Local Database Cache ตาม userId ของแต่ละคน
        _historyList = await _db.getHealthRecords(userId: activeUserId);
        _dataSource = "Local Database Cache";

        if (_historyList.isNotEmpty) {
          final latest = _historyList.first;
          _weight = latest.nWeight;
          _height = latest.nHeight;
        }
      }

      // 3. คำนวณผลลัพธ์จากข้อมูลจริงของผู้ใช้คนนั้น
      if (_weight > 0 && _height > 0 && _age > 0) {
        await calculate(recordHistory: false, syncToDb: false);
      } else {
        _bmi = 0.0;
        _bmr = 0.0;
        _tdee = 0.0;
        _targets = const CalorieTargets(fatLoss: 0, maintain: 0, muscleGain: 0);
        _bmiCategory = HealthCalculator.getBMICategory(0.0);
      }
    } catch (e) {
      debugPrint('Error loading state from database: $e');
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  // Getters
  // Getters
  TbUser? get currentUser => _currentUser;
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
      _safeNotifyListeners();
    }
  }

  void setAge(int age) {
    _age = age;
    _safeNotifyListeners();
  }

  void setHeight(double height) {
    _height = height;
    _safeNotifyListeners();
  }

  void setWeight(double weight) {
    _weight = weight;
    _safeNotifyListeners();
  }

  void setActivityLevel(ActivityLevel level) {
    _activityLevel = level;
    _safeNotifyListeners();
  }

  Future<void> calculate({bool recordHistory = false, bool syncToDb = false}) async {
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

    final activeUserId = _currentUser?.nUserId;
    if (activeUserId == null) {
      _safeNotifyListeners();
      return;
    }

    if (recordHistory) {
      final newRecord = TbHealthRecord(
        nRecordId: 0,
        nUserId: activeUserId,
        nWeight: _weight,
        nHeight: _height,
        nBmi: _bmi,
        nTdee: _tdee,
        dtRecordedAt: DateTime.now(),
        computedBmr: _bmr,
        activityLevelTitle: _activityLevel.title,
      );

      _historyList.insert(0, newRecord);

      // บันทึกลง Local Database (isSynced = 0) แล้วซิงค์ขึ้น Cloud
      try {
        final savedRecord = await _db.insertHealthRecord(newRecord);
        if (!_isDisposed) {
          final index = _historyList.indexOf(newRecord);
          if (index != -1) {
            _historyList[index] = savedRecord;
            notifyListeners();
          }
        }
        // ซิงค์ขึ้น Cloud ในเบื้องหลังทันที
        await SyncService.instance.updatePendingCount();
        unawaited(SyncService.instance.syncPendingData());
      } catch (e) {
        debugPrint('Error saving health record to local db: $e');
      }
    }

    if (syncToDb) {
      _currentUser = TbUser(
        nUserId: activeUserId,
        sEmail: _currentUser?.sEmail ?? AuthService.instance.currentUserEmail,
        sPasswordHash: _currentUser?.sPasswordHash ?? '',
        sFirstName: _currentUser?.sFirstName ?? 'ผู้ใช้งาน',
        sLastName: _currentUser?.sLastName ?? '',
        nAge: _age,
        nHeight: _height,
        nWeight: _weight,
        sGender: _gender.name,
        sActivityLevel: _activityLevel.id,
        isDarkMode: _currentUser?.isDarkMode ?? false,
      );

      // อัปเดตลง Local Database & ส่งไปอัปเดตบน PHP Database Server
      final userToUpdate = _currentUser!;
      try {
        await _db.updateUser(userToUpdate);
      } catch (e) {
        debugPrint('Error updating user locally: $e');
      }
      try {
        await HealthApiService.updateUserProfile(userToUpdate);
      } catch (e) {
        debugPrint('Error updating user profile to API: $e');
      }
    }

    _safeNotifyListeners();
  }

  Future<void> saveToProfileAndDashboard() async {
    await calculate(recordHistory: true, syncToDb: true);
    _isSyncedToDashboard = true;
    _lastSyncedAt = DateTime.now();
    _safeNotifyListeners();
  }

  Future<void> deleteHistoryItem(int recordId) async {
    try {
      await _db.deleteHealthRecord(recordId);
      _historyList.removeWhere((item) => item.nRecordId == recordId);
      _safeNotifyListeners();
    } catch (e) {
      debugPrint('Error deleting health record from db: $e');
    }
  }
}
