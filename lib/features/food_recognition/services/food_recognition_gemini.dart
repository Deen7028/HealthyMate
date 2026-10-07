part of 'food_recognition_service.dart';

// ส่วนขยายการเรียกใช้งานโมเดลวิสัยทัศน์คอมพิวเตอร์ Google Gemini Vision (Food Recognition Gemini Extension)
extension FoodRecognitionGemini on FoodRecognitionService {
  // ฟังก์ชัน: ส่งคำขอไปยัง Google Gemini Vision API (Call Gemini Vision API)
  Future<List<DetectedFoodItem>?> _callGeminiVisionApi(
    File imageFile,
    String apiKey,
  ) async {
    // 1. ตรวจสอบขนาดไฟล์ภาพไม่ให้เกิน 10 MB
    final fileSize = await imageFile.length();
    if (fileSize > 10 * 1024 * 1024) {
      throw Exception('ไฟล์ภาพใหญ่เกินไป กรุณาเลือกรูปที่มีขนาดไม่เกิน 10 MB');
    }

    // 2. แปลงข้อมูลไฟล์ภาพเป็น Base64
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    // 3. กำหนด MIME type ให้ตรงกับนามสกุลไฟล์
    String mimeType = 'image/jpeg';
    final lowerPath = imageFile.path.toLowerCase();
    if (lowerPath.endsWith('.png')) {
      mimeType = 'image/png';
    } else if (lowerPath.endsWith('.webp')) {
      mimeType = 'image/webp';
    }

    // 4. เตรียม URL ปลายทางของ Gemini 1.5/2.0/3.5 endpoint
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

    // 5. สร้างคำสั่งและโครงสร้าง JSON สำหรับส่งคำขอ
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

    // 6. ส่งคำขอแบบ POST ผ่าน HTTP ไปยัง Gemini Endpoint
    final response = await http
        .post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'x-goog-api-key': apiKey,
          },
          body: requestBody,
        )
        .timeout(const Duration(seconds: 25));

    // 7. ตรวจสอบสถานะการตอบกลับและดึงผลลัพธ์ JSON
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
      // 8. จัดการกรณี API ตอบกลับข้อผิดพลาด (เช่น โควตาหมด หรือคีย์ไม่ถูกต้อง)
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
}
