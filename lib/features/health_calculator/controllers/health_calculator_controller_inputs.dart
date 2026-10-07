part of 'health_calculator_controller.dart';

// ส่วนจัดการอินพุตของเครื่องคำนวณสุขภาพ (HealthCalculatorInputs)
// ทำหน้าที่รับและอัปเดตค่าเพศ, อายุ, ส่วนสูง, น้ำหนัก และระดับกิจกรรม
extension HealthCalculatorInputs on HealthCalculatorController {
  // ฟังก์ชัน: กำหนดเพศ
  void setGender(Gender gender) {
    if (_gender != gender) {
      _gender = gender;
      _safeNotifyListeners();
    }
  }

  // ฟังก์ชัน: กำหนดอายุ
  void setAge(int age) {
    _age = age;
    _safeNotifyListeners();
  }

  // ฟังก์ชัน: กำหนดส่วนสูง (ซม.)
  void setHeight(double height) {
    _height = height;
    _safeNotifyListeners();
  }

  // ฟังก์ชัน: กำหนดน้ำหนัก (กก.)
  void setWeight(double weight) {
    _weight = weight;
    _safeNotifyListeners();
  }

  // ฟังก์ชัน: กำหนดระดับกิจกรรมประจำวัน
  void setActivityLevel(ActivityLevel level) {
    _activityLevel = level;
    _safeNotifyListeners();
  }
}
