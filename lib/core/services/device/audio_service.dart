import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

// บริการจัดการเล่นเสียงเอฟเฟกต์ภายในแอป (Audio Feedback Service)
class AudioService {
  static final AudioService instance = AudioService._();
  AudioService._();

  final AudioPlayer _uiPlayer = AudioPlayer();
  final AudioPlayer _timerPlayer = AudioPlayer();

  // เล่นเสียงเมื่อทำภารกิจหรือกิจวัตรสำเร็จ (success.mp3)
  Future<void> playSuccess() async {
    try {
      if (_uiPlayer.state == PlayerState.playing) {
        await _uiPlayer.stop();
      }
      await _uiPlayer.play(AssetSource('sounds/success.mp3'), volume: 0.8);
    } catch (e) {
      debugPrint('AudioService.playSuccess error: $e');
    }
  }

  // เล่นเสียงหยดน้ำเมื่อกดบันทึกการดื่มน้ำ (water.mp3)
  Future<void> playWaterDrop() async {
    try {
      if (_uiPlayer.state == PlayerState.playing) {
        await _uiPlayer.stop();
      }
      await _uiPlayer.play(AssetSource('sounds/water.mp3'), volume: 1.0);
    } catch (e) {
      debugPrint('AudioService.playWaterDrop error: $e');
    }
  }

  // เล่นเสียงกระดิ่งเมื่อนับเวลาถอยหลังเสร็จสิ้น (bell.mp3)
  Future<void> playTimerComplete() async {
    try {
      if (_timerPlayer.state == PlayerState.playing) {
        await _timerPlayer.stop();
      }
      await _timerPlayer.play(AssetSource('sounds/bell.mp3'), volume: 1.0);
    } catch (e) {
      debugPrint('AudioService.playTimerComplete error: $e');
    }
  }
}