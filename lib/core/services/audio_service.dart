import 'package:audioplayers/audioplayers.dart';

class AudioService {
  static final AudioService instance = AudioService._();
  AudioService._();

  // สร้าง Player แยกกันเพื่อไม่ให้เสียงตีกันเวลากดพร้อมกัน
  final AudioPlayer _uiPlayer = AudioPlayer();
  final AudioPlayer _timerPlayer = AudioPlayer();

  Future<void> playSuccess() async {
    // เล่นเสียงความสำเร็จ
    await _uiPlayer.play(AssetSource('sounds/success.mp3'), volume: 0.6);
  }

  Future<void> playWaterDrop() async {
    // เล่นเสียงน้ำแบบรวดเร็ว
    if (_uiPlayer.state == PlayerState.playing) {
      await _uiPlayer.stop(); // หยุดเสียงเก่าถ้ากดรัวๆ
    }
    await _uiPlayer.play(AssetSource('sounds/water.mp3'), volume: 0.8);
  }

  Future<void> playTimerComplete() async {
    // เสียงระฆังยาวๆ
    await _timerPlayer.play(AssetSource('sounds/bell.mp3'));
  }
}