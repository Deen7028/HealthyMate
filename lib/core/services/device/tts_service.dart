import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

// บริการเสียงพูดจำลองผู้ฝึกสอน (TTS Voice Coach Service) สำหรับรายงานผลระหว่างออกกำลังกาย
class TtsService {
  TtsService._();
  static final TtsService instance = TtsService._();

  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;

  // กำหนดค่าเริ่มต้นระบบเสียงพูดภาษาไทย (ภาษา th-TH, ความเร็ว, ระดับเสียง)
  Future<void> init() async {
    if (_isInitialized) return;
    try {
      await _flutterTts.setLanguage('th-TH');
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
      _isInitialized = true;
    } catch (e) {
      debugPrint('TtsService init error: $e');
    }
  }

  // สั่งให้อ่านออกเสียงข้อความที่ระบุ
  Future<void> speak(String text) async {
    try {
      if (!_isInitialized) {
        await init();
      }
      await _flutterTts.stop();
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint('TtsService speak error: $e');
    }
  }

  // ส่งเสียงพูดรายงานความคืบหน้าการออกกำลังกาย (ระยะทางกิโลเมตร, เวลา, เพซเฉลี่ย)
  Future<void> announceWorkoutProgress({
    required double distanceKm,
    required int secondsElapsed,
    required String paceText,
  }) async {
    final kmText = distanceKm.toStringAsFixed(1);
    final minutes = secondsElapsed ~/ 60;
    final seconds = secondsElapsed % 60;

    String timeText = '';
    if (minutes > 0) {
      timeText += '$minutes นาที ';
    }
    if (seconds > 0 || minutes == 0) {
      timeText += '$seconds วินาที';
    }

    final message = 'ครบระยะทาง $kmText กิโลเมตร ใช้เวลา $timeText เพซเฉลี่ย $paceText นาทีต่อกิโลเมตร';
    await speak(message);
  }

  // หยุดการอ่านออกเสียงทันที
  Future<void> stop() async {
    try {
      await _flutterTts.stop();
    } catch (_) {}
  }
}
