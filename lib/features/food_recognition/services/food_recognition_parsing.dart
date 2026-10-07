part of 'food_recognition_service.dart';

// ส่วนขยายการแปลงข้อมูล JSON ผลลัพธ์จากโมเดล AI (Food Recognition Parsing Extension)
extension FoodRecognitionParsing on FoodRecognitionService {
  // ฟังก์ชัน: แปลงข้อความตอบกลับของ Gemini ให้เป็นรายการ DetectedFoodItem (Parse Gemini JSON)
  List<DetectedFoodItem> _parseGeminiJson(String text) {
    try {
      // 1. ทำความสะอาดข้อความและตัดบล็อก Markdown (```json ... ```) ออก
      var cleanText = text.trim();
      if (cleanText.startsWith('```json')) {
        cleanText = cleanText.substring(7);
      } else if (cleanText.startsWith('```')) {
        cleanText = cleanText.substring(3);
      }
      if (cleanText.endsWith('```')) {
        cleanText = cleanText.substring(0, cleanText.length - 3);
      }
      cleanText = cleanText.trim();

      // 2. ค้นหาขอบเขต JSON ที่เป็น Array [...] หรือ Object {...}
      final startBracket = cleanText.indexOf('[');
      final endBracket = cleanText.lastIndexOf(']');
      if (startBracket != -1 && endBracket != -1 && endBracket > startBracket) {
        cleanText = cleanText.substring(startBracket, endBracket + 1);
      }

      // 3. ถอดรหัสโครงสร้าง JSON
      final decoded = jsonDecode(cleanText);
      final rawList = <dynamic>[];

      // 4. แยกข้อมูลกรณีผลลัพธ์เป็น List โดยตรง หรือถูกห่อไว้ใน Object
      if (decoded is List) {
        rawList.addAll(decoded);
      } else if (decoded is Map<String, dynamic>) {
        final possibleList =
            decoded['items'] ??
            decoded['foods'] ??
            decoded['dishes'] ??
            decoded['data'];
        if (possibleList is List) {
          rawList.addAll(possibleList);
        } else if (decoded.containsKey('name')) {
          rawList.add(decoded);
        }
      }

      // 5. แปลง Map ของอาหารแต่ละรายการเป็น Model DetectedFoodItem
      final items = <DetectedFoodItem>[];
      for (int i = 0; i < rawList.length; i++) {
        final map = rawList[i];
        if (map is Map<String, dynamic>) {
          final name = map['name']?.toString() ?? 'อาหารไม่ระบุชื่อ';
          final rawCalories = map['calories'];
          if (name.trim().isNotEmpty && name != 'null' && rawCalories is num && rawCalories >= 0) {
            items.add(
              DetectedFoodItem(
                id: 'food_ai_${DateTime.now().millisecondsSinceEpoch}_$i',
                name: name,
                calories: rawCalories.toInt(),
                protein: _nonNegative(map['protein']),
                carbs: _nonNegative(map['carbs']),
                fat: _nonNegative(map['fat']),
                servingSize: map['servingSize']?.toString() ?? '1 ที่',
                confidence: ((map['confidence'] as num?)?.toDouble() ?? 0.0).clamp(0.0, 1.0),
              ),
            );
          }
        }
      }

      // 6. คืนค่ารายการอาหารที่ตรวจพบ
      if (items.isNotEmpty) return items;
    } catch (e) {
      debugPrint('Error parsing Gemini JSON: $e');
    }
    return [];
  }
}
