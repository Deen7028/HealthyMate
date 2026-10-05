// ส่วนนี้อธิบายบทบาทของไฟล์: เซอร์วิสเชื่อมต่อข้อมูล/อุปกรณ์/ระบบภายนอก ในฟีเจอร์การวิเคราะห์อาหารจากรูปภาพและข้อมูลโภชนาการ (food recognition parsing)
// คอมเมนท์ภาษาไทยถูกใส่ไว้เป็นส่วนๆ เพื่อช่วยไล่ flow โดยไม่เปลี่ยนพฤติกรรมเดิมของโค้ด

part of 'food_recognition_service.dart';

extension FoodRecognitionParsing on FoodRecognitionService {
  List<DetectedFoodItem> _parseGeminiJson(String text) {
    try {
      var cleanText = text.trim();
      // ตัด markdown code block ออกถ้ามี
      if (cleanText.startsWith('```json')) {
        cleanText = cleanText.substring(7);
      } else if (cleanText.startsWith('```')) {
        cleanText = cleanText.substring(3);
      }
      if (cleanText.endsWith('```')) {
        cleanText = cleanText.substring(0, cleanText.length - 3);
      }
      cleanText = cleanText.trim();

      // ค้นหาขอบเขต JSON ที่เป็น Array [...] หรือ Object {...}
      final startBracket = cleanText.indexOf('[');
      final endBracket = cleanText.lastIndexOf(']');
      if (startBracket != -1 && endBracket != -1 && endBracket > startBracket) {
        cleanText = cleanText.substring(startBracket, endBracket + 1);
      }

      final decoded = jsonDecode(cleanText);
      final rawList = <dynamic>[];

      if (decoded is List) {
        rawList.addAll(decoded);
      } else if (decoded is Map<String, dynamic>) {
        // กรณี Gemini ส่งกลับมาในรูป { "items": [...] } หรือ { "foods": [...] }
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
      if (items.isNotEmpty) return items;
    } catch (e) {
      debugPrint('Error parsing Gemini JSON: $e');
    }
    return [];
  }
}
