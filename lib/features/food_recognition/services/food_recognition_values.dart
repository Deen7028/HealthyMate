part of 'food_recognition_service.dart';

extension FoodRecognitionValues on FoodRecognitionService {
  double _nonNegative(dynamic value) {
    if (value is! num || !value.isFinite || value < 0) return 0.0;
    return value.toDouble();
  }
}
