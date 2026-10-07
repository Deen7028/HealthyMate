import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:healthymate/core/config/app_config.dart';
import 'package:healthymate/core/database/app_database.dart';
import 'package:healthymate/features/food_recognition/models/food_recognition_models.dart';

part 'food_recognition_analysis.dart';
part 'food_recognition_gemini.dart';
part 'food_recognition_parsing.dart';
part 'food_recognition_values.dart';

class FoodRecognitionService {
  FoodRecognitionService._();
  static final FoodRecognitionService instance = FoodRecognitionService._();

  /// วิเคราะห์ภาพอาหารด้วย Google Gemini 1.5 Flash Vision หากมี API Key ใน Database
  /// หากไม่มี API Key หรือการเชื่อมต่อไม่สำเร็จ จะคืนผลลัพธ์ที่มีรายการอาหารว่างเปล่า พร้อม error message ที่ชัดเจน (ไม่มีการสุ่ม mock data)
}
