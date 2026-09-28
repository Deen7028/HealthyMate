import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:healthymate/core/database/app_database.dart';
import 'package:healthymate/features/food_recognition/models/food_recognition_models.dart';

class FoodRecognitionService {
  FoodRecognitionService._();
  static final FoodRecognitionService instance = FoodRecognitionService._();

  /// วิเคราะห์ภาพอาหารด้วย Google Gemini 1.5 Flash Vision หากมี API Key ใน Database
  /// หากไม่มี API Key หรือการเชื่อมต่อไม่สำเร็จ จะคืนผลลัพธ์ที่มีรายการอาหารว่างเปล่า พร้อม error message ที่ชัดเจน (ไม่มีการสุ่ม mock data)
  Future<MealNutritionScanResult> analyzeFoodImage(
    File imageFile, {
    int? userId,
  }) async {
    String? errorMsg;
    bool hasKey = false;

    try {
      final targetUserId =
          userId ?? (await AppDatabase.instance.getUser())?.nUserId ?? 1;
      final apiKey = await AppDatabase.instance.getGeminiApiKey(targetUserId);

      if (apiKey.trim().isNotEmpty) {
        hasKey = true;
        debugPrint(
          'FoodRecognitionService: Analyzing image with Google Gemini 1.5 Flash Vision...',
        );
        final geminiResult = await _callGeminiVisionApi(
          imageFile,
          apiKey.trim(),
        );
        if (geminiResult != null && geminiResult.isNotEmpty) {
          return MealNutritionScanResult(
            imagePath: imageFile.path,
            category: MealCategory.fromCurrentTime(),
            items: geminiResult,
            scannedAt: DateTime.now(),
            hasApiKey: true,
          );
        } else {
          errorMsg = 'AI ตรวจสอบภาพนี้แล้วแต่ไม่สามารถระบุรายการได้';
        }
      } else {
        hasKey = false;
        errorMsg = 'ยังไม่ได้ตั้งค่า Google Gemini API Key';
        debugPrint(
          'FoodRecognitionService: No Gemini API Key configured for user $targetUserId.',
        );
      }
    } catch (e, stack) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      errorMsg = msg;
      debugPrint('FoodRecognitionService: Gemini API failed: $e\n$stack');
    }

    // เมื่อไม่มี API key หรือไม่สามารถตรวจจับได้ ให้คืนค่าผลลัพธ์ว่างเปล่า ไม่สุ่ม mock data
    return MealNutritionScanResult(
      imagePath: imageFile.path,
      category: MealCategory.fromCurrentTime(),
      items: [],
      scannedAt: DateTime.now(),
      errorMessage: errorMsg,
      hasApiKey: hasKey,
    );
  }

  Future<List<DetectedFoodItem>?> _callGeminiVisionApi(
    File imageFile,
    String apiKey,
  ) async {
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    // กำหนด MIME type จากนามสกุลไฟล์
    String mimeType = 'image/jpeg';
    final lowerPath = imageFile.path.toLowerCase();
    if (lowerPath.endsWith('.png')) {
      mimeType = 'image/png';
    } else if (lowerPath.endsWith('.webp')) {
      mimeType = 'image/webp';
    }

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash-lite:generateContent?key=$apiKey',
    );

    const promptText = '''
คุณคือระบบ AI Food & Nutrition Vision ผู้เชี่ยวชาญสูงสุดด้านการจำแนกอาหารทุกชนิด โภชนาการ อาหารไทย สตรีทฟู้ด ขนมขบเคี้ยว ของทานเล่น ผลไม้ เครื่องดื่ม วัตถุดิบ และกับข้าวทุกรูปแบบ

หน้าที่ของคุณ:
ตรวจสอบรูปภาพนี้อย่างละเอียด และระบุสิ่งที่เป็น "ของกิน" หรือ "อาหาร" ทั้งหมดที่ปรากฏในภาพ ไม่ว่าจะเป็น:
- อาหารจานเดียว, กับข้าว, ซุป, ต้ม, แกง, ผัด, ทอด, ปิ้งย่าง
- เนื้อสัตว์ทุกส่วนและทุกเมนู เช่น "ตีนไก่" / "ขาไก่" (ต้มซุปเปอร์, พะโล้, ทอด, ยำเล็บมือนาง), ปีกไก่, น่องไก่, หมูกรอบ, เนื้อวัว, อาหารทะเล
- ขนมขบเคี้ยว, ขนมหวาน, เบเกอรี่, ขนมไทย, ของทานเล่น, อาหารกินเล่น
- ผัก, ผลไม้, ธัญพืช, สลัด, ไข่ต้ม, ไข่ดาว
- เครื่องดื่มทุกชนิด (ชา, กาแฟ, น้ำผลไม้, นม, สมูทตี้)
- วัตถุดิบสดหรือส่วนผสมอาหารที่พร้อมนำไปปรุง

หากในภาพมีอาหารหลายอย่าง ให้แยกแต่ละรายการออกมา (Multi-item detection)
หากมีเพียงอย่างเดียว (เช่น ขาไก่ 1 ชาม หรือ ขนม 1 ซอง) ให้ระบุรายการนั้นออกมาอย่างถูกต้อง

สำหรับแต่ละรายการ ให้ระบุคุณสมบัติดังนี้:
1. name: ชื่ออาหารภาษาไทยที่ตรงกับภาพที่สุด เช่น "ซุปเปอร์ตีนไก่", "ขาไก่พะโล้", "ตีนไก่ทอด", "เล็บมือนางยำ", "อกไก่ย่าง"
2. calories: พลังงานโดยประมาณ (หน่วย kcal จำนวนเต็ม integer)
3. protein: โปรตีนโดยประมาณ (หน่วยกรัม double)
4. carbs: คาร์โบไฮเดรตโดยประมาณ (หน่วยกรัม double)
5. fat: ไขมันโดยประมาณ (หน่วยกรัม double)
6. servingSize: ขนาดหรือปริมาณที่เห็นในภาพ เช่น "1 ชาม (200g)", "1 จาน (250g)", "4-5 ชิ้น (150g)"
7. confidence: ค่าความเชื่อมั่น (0.80 - 0.99)

ข้อกำหนดสำคัญ:
- ส่งกลับผลลัพธ์เป็น JSON Array เท่านั้น
- ห้ามใส่คำอธิบายเพิ่มเติมหรือบทสนทนา ให้คืนค่าเฉพาะ JSON ดังตัวอย่าง:
[
  {
    "name": "ตีนไก่ต้มซุปเปอร์",
    "calories": 215,
    "protein": 19.5,
    "carbs": 3.0,
    "fat": 14.0,
    "servingSize": "1 ชาม (4-5 ชิ้น)",
    "confidence": 0.95
  }
]
''';

    final requestBody = jsonEncode({
      "contents": [
        {
          "parts": [
            {"text": promptText},
            {
              "inline_data": {"mime_type": mimeType, "data": base64Image},
            },
          ],
        },
      ],
      "generationConfig": {
        "temperature": 0.2,
        "response_mime_type": "application/json",
      },
    });

    final response = await http
        .post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: requestBody,
        )
        .timeout(const Duration(seconds: 25));

    if (response.statusCode == 200) {
      final data =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final candidates = data['candidates'] as List?;
      if (candidates != null && candidates.isNotEmpty) {
        final content = candidates[0]['content'];
        final parts = content?['parts'] as List?;
        if (parts != null && parts.isNotEmpty) {
          final text = parts[0]['text']?.toString() ?? '';
          return _parseGeminiJson(text);
        }
      }
    } else {
      String errDetail = 'HTTP ${response.statusCode}';
      try {
        final errJson = jsonDecode(response.body);
        if (errJson is Map && errJson.containsKey('error')) {
          errDetail = errJson['error']['message'] ?? errDetail;
        }
      } catch (_) {}
      debugPrint(
        'Gemini API Error: $errDetail (Status ${response.statusCode})',
      );
      if (response.statusCode == 400 &&
          errDetail.contains('API key not valid')) {
        throw Exception('API Key ไม่ถูกต้อง กรุณาตรวจสอบและตั้งค่าใหม่');
      } else if (response.statusCode == 429) {
        throw Exception('Gemini โควตาการใช้งานเต็มชั่วคราว (Rate limit 429)');
      } else {
        throw Exception('Gemini ตอบกลับข้อผิดพลาด ($errDetail)');
      }
    }
    return null;
  }

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
          if (name.trim().isNotEmpty && name != 'null') {
            items.add(
              DetectedFoodItem(
                id: 'food_ai_${DateTime.now().millisecondsSinceEpoch}_$i',
                name: name,
                calories: (map['calories'] as num?)?.toInt() ?? 100,
                protein: (map['protein'] as num?)?.toDouble() ?? 0.0,
                carbs: (map['carbs'] as num?)?.toDouble() ?? 0.0,
                fat: (map['fat'] as num?)?.toDouble() ?? 0.0,
                servingSize: map['servingSize']?.toString() ?? '1 ที่',
                confidence: (map['confidence'] as num?)?.toDouble() ?? 0.95,
              ),
            );
          }
        }
      }
      if (items.isNotEmpty) return items;
    } catch (e) {
      debugPrint('Error parsing Gemini JSON: $e\nText: $text');
    }
    return [];
  }
}
