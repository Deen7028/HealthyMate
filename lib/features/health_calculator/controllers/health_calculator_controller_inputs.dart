part of 'health_calculator_controller.dart';

extension HealthCalculatorInputs on HealthCalculatorController {
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
}
