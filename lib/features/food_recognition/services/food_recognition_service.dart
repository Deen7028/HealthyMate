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

// ส่วนบริการวิเคราะห์อาหารด้วยระบบ AI (Food Recognition Service)
// บริการหลักในการตรวจจับและจำแนกสารอาหารจากรูปภาพด้วยโมเดล Gemini Vision
class FoodRecognitionService {
  FoodRecognitionService._();
  static final FoodRecognitionService instance = FoodRecognitionService._();

  /// ฟังก์ชัน: วิเคราะห์ภาพอาหารด้วย Google Gemini 3.5 Flash Vision
  /// 1. ตรวจสอบและดึง API Key จากฐานข้อมูลหรือการตั้งค่าสภาพแวดล้อม
  /// 2. ส่งภาพไปยังโมเดลวิเคราะห์ข้อมูลโภชนาการ (แคลอรี โปรตีน คาร์โบไฮเดรต ไขมัน)
  /// 3. หากไม่มี API Key หรือเชื่อมต่อไม่สำเร็จ จะคืนผลลัพธ์ว่างพร้อมข้อความระบุสาเหตุ
}
