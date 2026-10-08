import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

// ฟังก์ชัน Entry-Point สำหรับ Background Isolate ทำงานเบื้องหลัง
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });

    service.on('updateNotification').listen((event) {
      if (event != null) {
        final title = event['title']?.toString() ?? 'HealthyMate กำลังติดตามกิจกรรม';
        final content = event['content']?.toString() ?? 'กำลังบันทึกระยะทางและเส้นทาง GPS...';
        service.setForegroundNotificationInfo(
          title: title,
          content: content,
        );
      }
    });
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  LocationSettings locationSettings;
  if (!kIsWeb && Platform.isAndroid) {
    locationSettings = AndroidSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 2,
      intervalDuration: const Duration(seconds: 1),
    );
  } else if (!kIsWeb && Platform.isIOS) {
    locationSettings = AppleSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 2,
      activityType: ActivityType.fitness,
      pauseLocationUpdatesAutomatically: false,
      showBackgroundLocationIndicator: true,
      allowBackgroundLocationUpdates: true,
    );
  } else {
    locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 2,
    );
  }

  // ดักฟังพิกัด GPS แบบ Stream และส่งข้อมูลกลับไปยัง UI Isolate
  Geolocator.getPositionStream(locationSettings: locationSettings).listen(
    (Position position) {
      service.invoke('updateLocation', {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'speed': position.speed,
        'accuracy': position.accuracy,
        'altitude': position.altitude,
        'timestamp': position.timestamp.toIso8601String(),
      });
    },
    onError: (e) {
      debugPrint('Background location stream error: $e');
    },
  );
}

// ฟังก์ชัน Entry-Point สำหรับ iOS Background Fetch
@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  return true;
}

// บริการติดตามพิกัดตำแหน่ง GPS ขณะออกกำลังกายแบบเบื้องหลัง (Background Location Tracking Service)
class LocationBackgroundService {
  LocationBackgroundService._();
  static final LocationBackgroundService instance = LocationBackgroundService._();

  // กำหนดค่าเริ่มต้นของระบบ Background Service ทั้ง Android และ iOS
  Future<void> initialize() async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      return;
    }

    try {
      final service = FlutterBackgroundService();

      await service.configure(
        androidConfiguration: AndroidConfiguration(
          onStart: onStart,
          autoStart: false,
          isForegroundMode: false,
        ),
        iosConfiguration: IosConfiguration(
          autoStart: false,
          onForeground: onStart,
          onBackground: onIosBackground,
        ),
      );
    } catch (e) {
      debugPrint('Error initializing LocationBackgroundService: $e');
    }
  }

  // ขอสิทธิ์ยกเว้น Battery Optimization บน Android (ป้องกันระบบฆ่าแอปขณะปิดหน้าจอ)
  Future<void> requestBatteryOptimizationExemption() async {
    if (!kIsWeb && Platform.isAndroid) {
      try {
        final status = await Permission.ignoreBatteryOptimizations.status;
        if (!status.isGranted) {
          await Permission.ignoreBatteryOptimizations.request();
        }
      } catch (e) {
        debugPrint('Failed to request ignoreBatteryOptimizations: $e');
      }
    }
  }

  // เริ่มต้นติดตามตำแหน่ง GPS ในโหมด Foreground Service
  Future<void> startTracking() async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      return;
    }
    try {
      final service = FlutterBackgroundService();
      if (!await service.isRunning()) {
        await service.startService();
      }
      if (Platform.isAndroid) {
        service.invoke('setAsForeground');
      }
    } catch (e, stack) {
      debugPrint('Error starting location background service: $e\n$stack');
    }
  }

  // อัปเดตข้อความบนแถบ Notification แจ้งเตือนขณะแอปทำงานเบื้องหลัง
  void updateNotification({required String title, required String content}) {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      return;
    }
    try {
      final service = FlutterBackgroundService();
      service.invoke('updateNotification', {
        'title': title,
        'content': content,
      });
    } catch (_) {}
  }

  // หยุดการทำงานของ Background Service เมื่อออกกำลังกายเสร็จสิ้น
  Future<void> stopTracking() async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      return;
    }
    try {
      final service = FlutterBackgroundService();
      if (await service.isRunning()) {
        service.invoke('stopService');
      }
    } catch (e) {
      debugPrint('Error stopping location background service: $e');
    }
  }
}
