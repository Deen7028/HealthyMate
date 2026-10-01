class DetectedFoodItem {
  final String id;
  String name;
  int calories;
  double protein;
  double carbs;
  double fat;
  String servingSize;
  double confidence;

  DetectedFoodItem({
    required this.id,
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.servingSize = '1 จาน (300g)',
    this.confidence = 0.95,
  });

  DetectedFoodItem copyWith({
    String? id,
    String? name,
    int? calories,
    double? protein,
    double? carbs,
    double? fat,
    String? servingSize,
    double? confidence,
  }) {
    return DetectedFoodItem(
      id: id ?? this.id,
      name: name ?? this.name,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      servingSize: servingSize ?? this.servingSize,
      confidence: confidence ?? this.confidence,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'servingSize': servingSize,
      'confidence': confidence,
    };
  }

  factory DetectedFoodItem.fromMap(Map<String, dynamic> map) {
    return DetectedFoodItem(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      calories: (map['calories'] as num?)?.toInt() ?? 0,
      protein: (map['protein'] as num?)?.toDouble() ?? 0.0,
      carbs: (map['carbs'] as num?)?.toDouble() ?? 0.0,
      fat: (map['fat'] as num?)?.toDouble() ?? 0.0,
      servingSize: map['servingSize']?.toString() ?? '1 ที่',
      confidence: (map['confidence'] as num?)?.toDouble() ?? 0.9,
    );
  }
}

enum MealCategory {
  breakfast('breakfast', 'มื้อเช้า', '06:00 - 10:00'),
  lunch('lunch', 'มื้อกลางวัน', '11:00 - 14:00'),
  dinner('dinner', 'มื้อเย็น', '17:00 - 21:00'),
  snack('snack', 'ของว่าง', 'ทานระหว่างวัน');

  final String key;
  final String label;
  final String timeRange;

  const MealCategory(this.key, this.label, this.timeRange);

  static MealCategory fromCurrentTime() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 11) {
      return MealCategory.breakfast;
    } else if (hour >= 11 && hour < 15) {
      return MealCategory.lunch;
    } else if (hour >= 17 && hour < 22) {
      return MealCategory.dinner;
    } else {
      return MealCategory.snack;
    }
  }

  static MealCategory fromKey(String key) {
    return MealCategory.values.firstWhere(
      (element) => element.key == key,
      orElse: () => MealCategory.lunch,
    );
  }
}

class MealNutritionScanResult {
  final String imagePath;
  MealCategory category;
  final List<DetectedFoodItem> items;
  final DateTime scannedAt;
  final String? errorMessage;
  final bool hasApiKey;

  MealNutritionScanResult({
    required this.imagePath,
    required this.category,
    required this.items,
    required this.scannedAt,
    this.errorMessage,
    this.hasApiKey = true,
  });

  int get totalCalories => items.fold(0, (sum, item) => sum + item.calories);
  double get totalProtein => items.fold(0.0, (sum, item) => sum + item.protein);
  double get totalCarbs => items.fold(0.0, (sum, item) => sum + item.carbs);
  double get totalFat => items.fold(0.0, (sum, item) => sum + item.fat);
}
