part of 'food_recognition_service.dart';

extension FoodRecognitionAnalysis on FoodRecognitionService {
  Future<MealNutritionScanResult> analyzeFoodImage(
    File imageFile, {
    int? userId,
  }) async {
    String? errorMsg;
    bool hasKey = false;

    try {
      final targetUserId = userId ?? (await AppDatabase.instance.getCurrentUser())?.nUserId;
      if (targetUserId == null) {
        throw Exception('กรุณาเข้าสู่ระบบก่อนใช้การวิเคราะห์อาหาร');
      }
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
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      errorMsg = msg.replaceAll(RegExp(r'key=[^&\s]+'), 'key=REDACTED');
      debugPrint('FoodRecognitionService: Gemini API request failed.');
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
}
