part of 'food_recognition_service.dart';

// ส่วนขยายการวิเคราะห์รูปภาพอาหาร (Food Recognition Analysis Extension)
extension FoodRecognitionAnalysis on FoodRecognitionService {
  // ฟังก์ชัน: วิเคราะห์ภาพอาหารและคำนวณโภชนาการ (Analyze Food Image)
  Future<MealNutritionScanResult> analyzeFoodImage(
    File imageFile, {
    int? userId,
  }) async {
    String? errorMsg;
    bool hasKey = false;

    try {
      // 1. ระบุผู้ใช้งานปัจจุบันเพื่อดึงข้อมูลการตั้งค่า API Key
      final targetUserId = userId ?? (await AppDatabase.instance.getCurrentUser())?.nUserId;
      if (targetUserId == null) {
        throw Exception('กรุณาเข้าสู่ระบบก่อนใช้การวิเคราะห์อาหาร');
      }

      // 2. ตรวจสอบ API Key จาก AppConfig หรือดึงจาก SQLite Database
      final envKey = AppConfig.geminiApiKey;
      final apiKey = envKey.isNotEmpty
          ? envKey
          : await AppDatabase.instance.getGeminiApiKey(targetUserId);

      // 3. หากมี API Key ให้เริ่มส่งภาพไปยัง Google Gemini 1.5 Flash Vision
      if (apiKey.trim().isNotEmpty) {
        hasKey = true;
        debugPrint(
          'FoodRecognitionService: Analyzing image with Google Gemini 1.5 Flash Vision...',
        );
        final geminiResult = await _callGeminiVisionApi(
          imageFile,
          apiKey.trim(),
        );

        // 4. หากวิเคราะห์ผลสำเร็จ คืนค่าข้อมูลอาหารพร้อมหมวดมื้ออาหารตามช่วงเวลา
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
    } catch (e) {
      // 5. จัดการข้อผิดพลาดและซ่อน API Key ออกจากข้อความแสดงผล
      final msg = e.toString().replaceFirst('Exception: ', '');
      errorMsg = msg.replaceAll(RegExp(r'key=[^&\s]+'), 'key=REDACTED');
      debugPrint('FoodRecognitionService: Gemini API request failed.');
    }

    // 6. เมื่อไม่มี API Key หรือพบข้อผิดพลาด คืนค่าผลลัพธ์ว่างโดยไม่สุ่มข้อมูลจำลอง
    return MealNutritionScanResult(
      imagePath: imageFile.path,
      category: MealCategory.fromCurrentTime(),
      items: [],
      scannedAt: DateTime.now(),
      errorMessage: errorMsg,
      hasApiKey: hasKey,
    );
  }
}
