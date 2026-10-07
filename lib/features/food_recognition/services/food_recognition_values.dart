part of 'food_recognition_service.dart';

// ส่วนขยายตรวจสอบและปรับเทียบค่าตัวเลขโภชนาการ (Food Recognition Values Extension)
extension FoodRecognitionValues on FoodRecognitionService {
  // ฟังก์ชัน: ตรวจสอบและแปลงค่าตัวเลขไม่ให้เป็นลบหรือค่าที่ไม่ถูกต้อง (Ensure Non-Negative Number)
  double _nonNegative(dynamic value) {
    if (value is! num || !value.isFinite || value < 0) return 0.0;
    return value.toDouble();
  }
}
