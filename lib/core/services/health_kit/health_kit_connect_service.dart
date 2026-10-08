import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import 'package:healthymate/core/database/app_database.dart';
// ดึงข้อมูลสุขภาพ (ขั้นตอน, อัตราการเต้นของหัวใจ, แคลอรี) จาก Health Connect (Android) และ HealthKit (iOS)
class HealthKitConnectService {
  HealthKitConnectService._();
  static final HealthKitConnectService instance = HealthKitConnectService._();

  final Health _health = Health();

  Future<bool> requestPermissions() async {
    final types = [
      HealthDataType.STEPS,
      HealthDataType.HEART_RATE,
      HealthDataType.ACTIVE_ENERGY_BURNED,
    ];
    try {
      bool requested = await _health.requestAuthorization(types);
      return requested;
    } catch (e) {
      debugPrint('HealthKitConnectService permission error: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> fetchTodayHealthData(int userId) async {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);
    int steps = 0;
    double avgHeartRate = 0.0;

    try {
      final types = [
        HealthDataType.STEPS,
        HealthDataType.HEART_RATE,
      ];

      bool authorized = await _health.requestAuthorization(types);
      if (authorized) {
        final healthData = await _health.getHealthDataFromTypes(
          types: types,
          startTime: midnight,
          endTime: now,
        );

        int heartRateCount = 0;
        double heartRateSum = 0.0;

        for (final data in healthData) {
          if (data.type == HealthDataType.STEPS) {
            final val = data.value;
            steps += int.tryParse(val.toString()) ?? 0;
          } else if (data.type == HealthDataType.HEART_RATE) {
            final val = data.value;
            final hr = double.tryParse(val.toString()) ?? 0.0;
            if (hr > 0) {
              heartRateSum += hr;
              heartRateCount++;
            }
          }
        }

        if (heartRateCount > 0) {
          avgHeartRate = heartRateSum / heartRateCount;
        }

        // บันทึกลง TbHealthIntegrations
        await AppDatabase.instance.insertConnectedDevice(
          userId: userId,
          providerName: 'HealthKit / Health Connect (Steps: $steps, HR: ${avgHeartRate.toStringAsFixed(0)})',
          isSynced: true,
        );
      }
    } catch (e) {
      debugPrint('Error fetching HealthKit/Connect data: $e');
    }

    return {
      'steps': steps,
      'heartRate': avgHeartRate,
    };
  }
}
