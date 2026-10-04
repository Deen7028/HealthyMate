// ส่วนนี้อธิบายบทบาทของไฟล์: เซอร์วิสเชื่อมต่อข้อมูล/อุปกรณ์/ระบบภายนอก ในฟีเจอร์การวิเคราะห์อาหารจากรูปภาพและข้อมูลโภชนาการ (food recognition values)
// คอมเมนท์ภาษาไทยถูกใส่ไว้เป็นส่วนๆ เพื่อช่วยไล่ flow โดยไม่เปลี่ยนพฤติกรรมเดิมของโค้ด

part of 'food_recognition_service.dart';

extension FoodRecognitionValues on FoodRecognitionService {
  double _nonNegative(dynamic value) {
    if (value is! num || !value.isFinite || value < 0) return 0.0;
    return value.toDouble();
  }
}
