import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:healthymate/core/config/app_config.dart';

/// Supabase Service จัดการการเชื่อมต่อ Database, Auth และ Storage โดยตรง
class SupabaseService {
  static final SupabaseService instance = SupabaseService._internal();
  SupabaseService._internal();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  SupabaseClient? get client => _isInitialized ? Supabase.instance.client : null;

  /// เริ่มต้นการเชื่อมต่อกับ Supabase
  Future<void> init() async {
    if (_isInitialized) return;

    final url = AppConfig.supabaseUrl;
    final anonKey = AppConfig.supabaseAnonKey;

    if (url.isEmpty || anonKey.isEmpty) {
      debugPrint('⚠️ SupabaseService: SUPABASE_URL หรือ SUPABASE_ANON_KEY ยังไม่ได้ตั้งค่าใน .env');
      return;
    }

    try {
      await Supabase.initialize(
        url: url,
        // ignore: deprecated_member_use
        anonKey: anonKey,
        debug: kDebugMode,
      );
      _isInitialized = true;
      debugPrint('🚀 SupabaseService: Initialized successfully with $url');
    } catch (e) {
      debugPrint('❌ SupabaseService: Initialization failed: $e');
    }
  }

  // ==========================================
  // AUTH & USER OPERATIONS
  // ==========================================

  /// ค้นหา User ตาม Email จาก TbUsers
  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    if (!_isInitialized || client == null) return null;
    try {
      final response = await client!
          .from('TbUsers')
          .select()
          .eq('sEmail', email.trim().toLowerCase())
          .maybeSingle();
      return response;
    } catch (e) {
      debugPrint('SupabaseService.getUserByEmail Error: $e');
      return null;
    }
  }

  /// บันทึกหรืออัปเดตข้อมูล User ใน TbUsers
  Future<bool> upsertUser(Map<String, dynamic> userData) async {
    if (!_isInitialized || client == null) return false;
    try {
      final email = userData['sEmail']?.toString().trim().toLowerCase();
      final userId = userData['nUserId'];

      // ตรวจสอบว่ามีผู้ใช้อยู่แล้วหรือไม่
      Map<String, dynamic>? existing;
      if (email != null && email.isNotEmpty) {
        existing = await getUserByEmail(email);
      } else if (userId != null) {
        existing = await client!
            .from('TbUsers')
            .select()
            .eq('nUserId', userId)
            .maybeSingle();
      }

      final payload = Map<String, dynamic>.from(userData);
      // ถ้าไม่มี passwordHash และเป็นการอัปเดต ให้ลบ key ออกเพื่อไม่ให้ติด null constraint
      if (existing != null) {
        payload.remove('sPasswordHash');
        if (email != null && email.isNotEmpty) {
          await client!.from('TbUsers').update(payload).eq('sEmail', email);
        } else if (userId != null) {
          await client!.from('TbUsers').update(payload).eq('nUserId', userId);
        }
        return true;
      }

      // กรณีสร้างใหม่ ถ้าไม่มี sPasswordHash ให้ใส่ค่า default ว่างไว้ (เช่น Login ด้วย Google)
      if (!payload.containsKey('sPasswordHash') || payload['sPasswordHash'] == null) {
        payload['sPasswordHash'] = '';
      }

      await client!.from('TbUsers').upsert(
            payload,
            onConflict: 'sEmail',
          );
      return true;
    } catch (e) {
      debugPrint('SupabaseService.upsertUser Error: $e');
      return false;
    }
  }

  // ==========================================
  // OTP OPERATIONS (TbEmailOtps)
  // ==========================================

  /// บันทึก OTP รหัสยืนยันลง TbEmailOtps
  Future<bool> saveEmailOtp({
    required String email,
    required String otpCode,
    required DateTime expiresAt,
  }) async {
    if (!_isInitialized || client == null) return false;
    try {
      await client!.from('TbEmailOtps').insert({
        'sEmail': email.trim().toLowerCase(),
        'sOtpCode': otpCode,
        'dtExpiresAt': expiresAt.toIso8601String(),
        'isUsed': false,
        'nAttempts': 0,
      });
      return true;
    } catch (e) {
      debugPrint('SupabaseService.saveEmailOtp Error: $e');
      return false;
    }
  }

  /// ตรวจสอบและใช้งาน OTP จาก TbEmailOtps
  Future<bool> verifyEmailOtp({
    required String email,
    required String otpCode,
  }) async {
    if (!_isInitialized || client == null) return false;
    try {
      final now = DateTime.now().toIso8601String();
      final records = await client!
          .from('TbEmailOtps')
          .select()
          .eq('sEmail', email.trim().toLowerCase())
          .eq('sOtpCode', otpCode)
          .eq('isUsed', false)
          .gte('dtExpiresAt', now)
          .order('dtCreatedAt', ascending: false)
          .limit(1);

      if (records.isNotEmpty) {
        final otpId = records.first['nOtpId'];
        if (otpId != null) {
          await client!
              .from('TbEmailOtps')
              .update({'isUsed': true}).eq('nOtpId', otpId);
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('SupabaseService.verifyEmailOtp Error: $e');
      return false;
    }
  }

  // ==========================================
  // SYNC & CRUD OPERATIONS
  // ==========================================

  /// ซิงค์บันทึกประวัติสุขภาพ (TbHealthRecords)
  Future<bool> upsertHealthRecord(Map<String, dynamic> recordData) async {
    if (!_isInitialized || client == null) return false;
    try {
      await client!.from('TbHealthRecords').upsert(recordData);
      return true;
    } catch (e) {
      debugPrint('SupabaseService.upsertHealthRecord Error: $e');
      return false;
    }
  }

  /// ซิงค์กิจวัตร (TbRoutines)
  Future<bool> upsertRoutine(Map<String, dynamic> routineData) async {
    if (!_isInitialized || client == null) return false;
    try {
      await client!.from('TbRoutines').upsert(routineData);
      return true;
    } catch (e) {
      debugPrint('SupabaseService.upsertRoutine Error: $e');
      return false;
    }
  }

  /// ซิงค์การออกกำลังกาย (TbWorkouts)
  Future<bool> upsertWorkout(Map<String, dynamic> workoutData) async {
    if (!_isInitialized || client == null) return false;
    try {
      await client!.from('TbWorkouts').upsert(workoutData);
      return true;
    } catch (e) {
      debugPrint('SupabaseService.upsertWorkout Error: $e');
      return false;
    }
  }

  /// ซิงค์โภชนาการ (TbNutritionLogs)
  Future<bool> upsertNutritionLog(Map<String, dynamic> nutritionData) async {
    if (!_isInitialized || client == null) return false;
    try {
      await client!.from('TbNutritionLogs').upsert(nutritionData);
      return true;
    } catch (e) {
      debugPrint('SupabaseService.upsertNutritionLog Error: $e');
      return false;
    }
  }

  /// ซิงค์เป้าหมาย (TbGoals)
  Future<bool> upsertGoal(Map<String, dynamic> goalData) async {
    if (!_isInitialized || client == null) return false;
    try {
      await client!.from('TbGoals').upsert(goalData);
      return true;
    } catch (e) {
      debugPrint('SupabaseService.upsertGoal Error: $e');
      return false;
    }
  }

  /// อัปโหลดรูปภาพขึ้น Supabase Storage Bucket
  Future<String?> uploadImage(
    String localPath, {
    String bucketName = 'healthymate-uploads',
    String folder = 'images',
  }) async {
    if (!_isInitialized || client == null) return null;
    try {
      final file = File(localPath);
      if (!await file.exists()) return null;

      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.uri.pathSegments.last}';
      final storagePath = '$folder/$fileName';

      await client!.storage.from(bucketName).upload(
            storagePath,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );

      final publicUrl = client!.storage.from(bucketName).getPublicUrl(storagePath);
      return publicUrl;
    } catch (e) {
      debugPrint('SupabaseService.uploadImage Error: $e');
      return null;
    }
  }
}
