import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:healthymate/core/database/app_database.dart';
import 'package:healthymate/features/food_recognition/models/food_recognition_models.dart';

class FoodRecognitionService {
  FoodRecognitionService._();
  static final FoodRecognitionService instance = FoodRecognitionService._();

  // Knowledge base อาหารไทยและอาหารเพื่อสุขภาพยอดนิยม สำหรับ Multi-item recognition
  static final List<List<DetectedFoodItem>> _mockCombos = [
    // Combo 1: ข้าวมันไก่ + น้ำซุปฟัก
    [
      DetectedFoodItem(
        id: 'item_1',
        name: 'ข้าวมันไก่ตอนเนื้อน่อง',
        calories: 540,
        protein: 28.5,
        carbs: 62.0,
        fat: 20.0,
        servingSize: '1 จาน (300g)',
        confidence: 0.96,
      ),
      DetectedFoodItem(
        id: 'item_2',
        name: 'น้ำซุปฟักต้มโครงไก่',
        calories: 45,
        protein: 2.0,
        carbs: 4.5,
        fat: 1.8,
        servingSize: '1 ถ้วย (150ml)',
        confidence: 0.91,
      ),
    ],
    // Combo 2: ข้าวผัดกะเพราอกไก่ + ไข่ดาวไม่สุก
    [
      DetectedFoodItem(
        id: 'item_3',
        name: 'กะเพราอกไก่ผัดพริกสด',
        calories: 380,
        protein: 34.0,
        carbs: 42.0,
        fat: 8.5,
        servingSize: '1 จาน (280g)',
        confidence: 0.98,
      ),
      DetectedFoodItem(
        id: 'item_4',
        name: 'ไข่ดาวทอดกรอบ',
        calories: 120,
        protein: 6.5,
        carbs: 0.8,
        fat: 10.2,
        servingSize: '1 ฟอง (50g)',
        confidence: 0.95,
      ),
    ],
    // Combo 3: สเต๊กอกไก่ย่าง + สลัดผักรวม + มันบด
    [
      DetectedFoodItem(
        id: 'item_5',
        name: 'สเต๊กอกไก่ย่างพริกไทยดำ',
        calories: 260,
        protein: 38.0,
        carbs: 2.0,
        fat: 6.0,
        servingSize: '1 ชิ้น (200g)',
        confidence: 0.97,
      ),
      DetectedFoodItem(
        id: 'item_6',
        name: 'สลัดผักสดน้ำสลัดบัลซามิก',
        calories: 75,
        protein: 2.2,
        carbs: 8.5,
        fat: 3.5,
        servingSize: '1 ถ้วยเล็ก (120g)',
        confidence: 0.93,
      ),
      DetectedFoodItem(
        id: 'item_7',
        name: 'มันบดโฮมเมดสูตรเนยน้อย',
        calories: 140,
        protein: 2.8,
        carbs: 24.0,
        fat: 4.0,
        servingSize: '1 ลูก (100g)',
        confidence: 0.90,
      ),
    ],
    // Combo 4: ข้าวกล้อง + ต้มยำกุ้งน้ำใส + ไข่ต้ม
    [
      DetectedFoodItem(
        id: 'item_8',
        name: 'ข้าวกล้องหอมมะลิ',
        calories: 160,
        protein: 3.5,
        carbs: 34.0,
        fat: 1.2,
        servingSize: '1 ทัพพี (100g)',
        confidence: 0.96,
      ),
      DetectedFoodItem(
        id: 'item_9',
        name: 'ต้มยำกุ้งแม่น้ำ (น้ำใส)',
        calories: 145,
        protein: 22.0,
        carbs: 5.0,
        fat: 3.5,
        servingSize: '1 ถ้วย (250ml)',
        confidence: 0.94,
      ),
      DetectedFoodItem(
        id: 'item_10',
        name: 'ไข่ต้มยางมะตูม',
        calories: 75,
        protein: 6.5,
        carbs: 0.6,
        fat: 5.0,
        servingSize: '1 ฟอง (50g)',
        confidence: 0.98,
      ),
    ],
    // Combo 5: ส้มตำไทย + ไก่ย่างไม่ติดหนัง
    [
      DetectedFoodItem(
        id: 'item_11',
        name: 'ส้มตำไทยรสจัด',
        calories: 120,
        protein: 4.0,
        carbs: 22.0,
        fat: 2.5,
        servingSize: '1 จาน (200g)',
        confidence: 0.95,
      ),
      DetectedFoodItem(
        id: 'item_12',
        name: 'ไก่ย่างสมุนไพรไม่เอาหนัง',
        calories: 220,
        protein: 32.0,
        carbs: 1.5,
        fat: 7.0,
        servingSize: '1 น่องติดสะโพก (180g)',
        confidence: 0.92,
      ),
    ],
  ];

  /// วิเคราะห์ภาพอาหารด้วย Google Gemini 1.5 Flash Vision หากมี API Key ใน Database
  /// หรือ Fallback สลับไปใช้ Local Mock Engine หากไม่มี Key หรือเกิดข้อผิดพลาดในการเชื่อมต่อ
  Future<MealNutritionScanResult> analyzeFoodImage(File imageFile, {int userId = 1}) async {
    try {
      final apiKey = await AppDatabase.instance.getGeminiApiKey(userId);
      if (apiKey.trim().isNotEmpty) {
        debugPrint('FoodRecognitionService: Analyzing image with Google Gemini 1.5 Flash Vision...');
        final geminiResult = await _callGeminiVisionApi(imageFile, apiKey.trim());
        if (geminiResult != null && geminiResult.isNotEmpty) {
          return MealNutritionScanResult(
            imagePath: imageFile.path,
            category: MealCategory.fromCurrentTime(),
            items: geminiResult,
            scannedAt: DateTime.now(),
          );
        }
      }
    } catch (e, stack) {
      debugPrint('FoodRecognitionService: Gemini API failed: $e\n$stack');
    }

    // Fallback: ใช้ Local Knowledge Base เมื่อไม่ได้ตั้ง Key หรือเกิดปัญหาการเชื่อมต่อ
    return _fallbackMockAnalysis(imageFile);
  }

  Future<List<DetectedFoodItem>?> _callGeminiVisionApi(File imageFile, String apiKey) async {
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
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey',
    );

    const promptText = '''
คุณคือระบบ AI Vision ผู้เชี่ยวชาญด้านโภชนาการและอาหารไทย
กรุณาวิเคราะห์รูปภาพอาหารนี้อย่างละเอียด โดยสามารถแยกอาหารแต่ละรายการในจาน/มื้อได้ (Multi-item detection) เช่น หากมี ข้าว, ไก่ทอด, น้ำจิ้ม ให้แยกเป็นแต่ละรายการ
สำหรับแต่ละรายการ ให้ระบุ:
1. name: ชื่ออาหารภาษาไทย (เช่น "ข้าวมันไก่ตอน", "ไข่ต้มยางมะตูม")
2. calories: แคลอรีโดยประมาณ (หน่วย kcal เป็นจำนวนเต็ม integer)
3. protein: โปรตีนโดยประมาณ (หน่วยกรัม gram เป็น double)
4. carbs: คาร์โบไฮเดรตโดยประมาณ (หน่วยกรัม gram เป็น double)
5. fat: ไขมันโดยประมาณ (หน่วยกรัม gram เป็น double)
6. servingSize: ขนาดหน่วยบริโภค เช่น "1 จาน (300g)", "1 ฟอง (50g)"
7. confidence: ความมั่นใจ (0.80 - 0.99)

ส่งกลับเฉพาะ JSON Array เท่านั้น ในรูปแบบ:
[
  {
    "name": "ชื่ออาหาร",
    "calories": 350,
    "protein": 25.0,
    "carbs": 40.0,
    "fat": 10.0,
    "servingSize": "1 จาน (250g)",
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
              "inline_data": {
                "mime_type": mimeType,
                "data": base64Image,
              }
            }
          ]
        }
      ],
      "generationConfig": {
        "temperature": 0.2,
        "response_mime_type": "application/json"
      }
    });

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: requestBody,
    ).timeout(const Duration(seconds: 25));

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
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
      debugPrint('Gemini API Error: Status ${response.statusCode}, Body: ${response.body}');
    }
    return null;
  }

  List<DetectedFoodItem> _parseGeminiJson(String text) {
    try {
      // ตัด markdown code block ออกถ้ามี
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

      final decoded = jsonDecode(cleanText);
      if (decoded is List) {
        final items = <DetectedFoodItem>[];
        for (int i = 0; i < decoded.length; i++) {
          final map = decoded[i];
          if (map is Map<String, dynamic>) {
            items.add(
              DetectedFoodItem(
                id: 'food_ai_${DateTime.now().millisecondsSinceEpoch}_$i',
                name: map['name']?.toString() ?? 'อาหารไม่ระบุชื่อ',
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
        if (items.isNotEmpty) return items;
      }
    } catch (e) {
      debugPrint('Error parsing Gemini JSON: $e\nText: $text');
    }
    return [];
  }

  Future<MealNutritionScanResult> _fallbackMockAnalysis(File imageFile) async {
    await Future.delayed(const Duration(milliseconds: 900));

    final random = Random();
    final selectedComboTemplate = _mockCombos[random.nextInt(_mockCombos.length)];

    final detectedItems = selectedComboTemplate.map((template) {
      return template.copyWith(
        id: 'food_${DateTime.now().microsecondsSinceEpoch}_${random.nextInt(999)}',
      );
    }).toList();

    return MealNutritionScanResult(
      imagePath: imageFile.path,
      category: MealCategory.fromCurrentTime(),
      items: detectedItems,
      scannedAt: DateTime.now(),
    );
  }
}
