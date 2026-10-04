// ส่วนนี้อธิบายบทบาทของไฟล์: ชุดทดสอบสำหรับ workout recovery service test เพื่อตรวจพฤติกรรมสำคัญของโปรเจกต์
// คอมเมนท์ภาษาไทยถูกใส่ไว้เป็นส่วนๆ เพื่อช่วยไล่ flow โดยไม่เปลี่ยนพฤติกรรมเดิมของโค้ด

import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:healthymate/features/workout/services/workout_recovery_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('WorkoutRecoveryService Tests', () {
    test('save and restore workout checkpoint', () async {
      final service = WorkoutRecoveryService.instance;

      const userId = 101;
      final points = [
        const LatLng(13.7563, 100.5018),
        const LatLng(13.7565, 100.5020),
      ];

      await service.saveCheckpoint(
        userId: userId,
        categoryId: 'running',
        distanceKm: 2.35,
        secondsElapsed: 720,
        caloriesBurned: 180.5,
        routePoints: points,
      );

      final checkpoint = await service.getCheckpoint(userId);
      expect(checkpoint, isNotNull);
      expect(checkpoint!.userId, equals(userId));
      expect(checkpoint.categoryId, equals('running'));
      expect(checkpoint.distanceKm, equals(2.35));
      expect(checkpoint.secondsElapsed, equals(720));
      expect(checkpoint.caloriesBurned, equals(180.5));
      expect(checkpoint.routePoints.length, equals(2));

      // Test clearing checkpoint
      await service.clearCheckpoint();
      final cleared = await service.getCheckpoint(userId);
      expect(cleared, isNull);
    });
  });
}
