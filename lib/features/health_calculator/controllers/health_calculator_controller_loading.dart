part of 'health_calculator_controller.dart';

extension HealthCalculatorLoading on HealthCalculatorController {
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
        debugPrint(
          'HealthCalculatorState: No valid authenticated user found, forcing logout.',
        );
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
      final serverRecords = await HealthRecordApiService.fetchHealthRecords(
        userId: activeUserId,
      );
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
}
