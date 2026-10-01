import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class AudioService {
  static final AudioService instance = AudioService._();
  AudioService._();

  final AudioPlayer _uiPlayer = AudioPlayer();
  final AudioPlayer _timerPlayer = AudioPlayer();

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