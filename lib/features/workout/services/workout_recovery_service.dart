// ส่วนนี้อธิบายบทบาทของไฟล์: เซอร์วิสเชื่อมต่อข้อมูล/อุปกรณ์/ระบบภายนอก ในฟีเจอร์การติดตามและประวัติการออกกำลังกาย (workout recovery service)
// คอมเมนท์ภาษาไทยถูกใส่ไว้เป็นส่วนๆ เพื่อช่วยไล่ flow โดยไม่เปลี่ยนพฤติกรรมเดิมของโค้ด

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/utils/route_utils.dart';

/// ข้อมูล State สำหรับการกู้คืนกิจกรรมที่หยุดกะทันหัน (Crash / Force Quit / Battery Out)
class WorkoutCheckpoint {
  final int userId;
  final String categoryId;
  final double distanceKm;
  final int secondsElapsed;
  final double caloriesBurned;
  final List<LatLng> routePoints;
  final DateTime checkpointTime;

  WorkoutCheckpoint({
    required this.userId,
    required this.categoryId,
    required this.distanceKm,
    required this.secondsElapsed,
    required this.caloriesBurned,
    required this.routePoints,
    required this.checkpointTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'categoryId': categoryId,
      'distanceKm': distanceKm,
      'secondsElapsed': secondsElapsed,
      'caloriesBurned': caloriesBurned,
      'encodedRoute': RouteUtils.toEncodedPolyline(routePoints, simplify: false),
      'checkpointTime': checkpointTime.toIso8601String(),
    };
  }

  factory WorkoutCheckpoint.fromMap(Map<String, dynamic> map) {
    final rawRoute = map['encodedRoute']?.toString();
    return WorkoutCheckpoint(
      userId: (map['userId'] as num?)?.toInt() ?? 0,
      categoryId: map['categoryId']?.toString() ?? 'running',
      distanceKm: (map['distanceKm'] as num?)?.toDouble() ?? 0.0,
      secondsElapsed: (map['secondsElapsed'] as num?)?.toInt() ?? 0,
      caloriesBurned: (map['caloriesBurned'] as num?)?.toDouble() ?? 0.0,
      routePoints: RouteUtils.parseRoutePoints(rawRoute),
      checkpointTime: DateTime.tryParse(map['checkpointTime']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

/// บริการจัดการ Auto-Recovery บันทึก State การออกกำลังกายแบบเรียลไทม์
/// ป้องกันข้อมูลสูญหายเมื่อแอปถูกปิดกะทันหัน
class WorkoutRecoveryService {
  WorkoutRecoveryService._();
  static final WorkoutRecoveryService instance = WorkoutRecoveryService._();

  static const String _checkpointKey = 'active_workout_checkpoint';

  /// บันทึก Checkpoint เป็นระยะ (เช่น ทุก 5-10 วินาที หรือเมื่อมีพิกัดใหม่)
  Future<void> saveCheckpoint({
    required int userId,
    required String categoryId,
    required double distanceKm,
    required int secondsElapsed,
    required double caloriesBurned,
    required List<LatLng> routePoints,
  }) async {
    if (userId <= 0 || secondsElapsed < 3) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final checkpoint = WorkoutCheckpoint(
        userId: userId,
        categoryId: categoryId,
        distanceKm: distanceKm,
        secondsElapsed: secondsElapsed,
        caloriesBurned: caloriesBurned,
        routePoints: routePoints,
        checkpointTime: DateTime.now(),
      );

      await prefs.setString(_checkpointKey, jsonEncode(checkpoint.toMap()));
    } catch (e) {
      debugPrint('Error saving workout checkpoint: $e');
    }
  }

  /// ตรวจสอบว่ามี Checkpoint ค้างอยู่ของผู้ใช้นี้หรือไม่
  /// (ตัดทิ้งหาก Checkpoint เก่าเกิน 18 ชั่วโมง)
  Future<WorkoutCheckpoint?> getCheckpoint(int userId) async {
    if (userId <= 0) return null;

    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_checkpointKey);
      if (raw == null || raw.isEmpty) return null;

      final data = jsonDecode(raw) as Map<String, dynamic>;
      final checkpoint = WorkoutCheckpoint.fromMap(data);

      if (checkpoint.userId != userId) return null;

      // ตรวจสอบอายุของ Checkpoint (ไม่เกิน 18 ชั่วโมง)
      final ageHours = DateTime.now().difference(checkpoint.checkpointTime).inHours;
      if (ageHours > 18) {
        await clearCheckpoint();
        return null;
      }

      return checkpoint;
    } catch (e) {
      debugPrint('Error loading workout checkpoint: $e');
      return null;
    }
  }

  /// ล้างข้อมูล Checkpoint เมื่อบันทึกสำเร็จหรือผู้ใช้กดยกเลิก
  Future<void> clearCheckpoint() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_checkpointKey);
    } catch (e) {
      debugPrint('Error clearing workout checkpoint: $e');
    }
  }
}
