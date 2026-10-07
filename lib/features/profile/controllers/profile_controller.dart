// ส่วนนี้อธิบายบทบาทของไฟล์: คอนโทรลเลอร์และ state ของหน้าจอ ในฟีเจอร์โปรไฟล์ การตั้งค่า และบัญชีผู้ใช้ (profile controller)
// คอมเมนท์ภาษาไทยถูกใส่ไว้เป็นส่วนๆ เพื่อช่วยไล่ flow โดยไม่เปลี่ยนพฤติกรรมเดิมของโค้ด

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:healthymate/core/database/app_database.dart';
import 'package:healthymate/core/services/api_service.dart';
import 'package:healthymate/core/services/auth_service.dart';
import 'package:healthymate/core/services/export/data_export_service.dart';
import 'package:healthymate/core/services/sync/sync_service.dart';
import 'package:healthymate/features/health_calculator/models/user_model.dart';

part 'profile_controller_loading.dart';
part 'profile_controller_images.dart';
part 'profile_controller_preferences.dart';
part 'profile_controller_devices.dart';
part 'profile_controller_account.dart';
part 'profile_controller_api_key.dart';

class ProfileController extends ChangeNotifier {
  void _notifyProfileListeners() => notifyListeners();

  bool isLoading = true;
  bool isUploadingImage = false;
  bool isLocationEnabled = true;
  TbUser? currentUser;

  int workoutCount = 0;
  int activeDays = 0;
  String mainGoalTitle = '';
  double goalProgress = 0.0;
  String goalRemainingText = '';
  List<Map<String, dynamic>> connectedDevices = [];
  String selectedUnit = 'Kilometers, Kilograms';
  String geminiApiKey = '';

  final ImagePicker _picker = ImagePicker();

  /// ตรวจสอบสถานะ GPS Location Service
}
