import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:vibration/vibration.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import '../services/drowsiness_service.dart'; // AlertType

class AlertService {
  // Singleton pattern to avoid LateInitializationError and multiple players/TTS
  AlertService._();
  static final AlertService instance = AlertService._();
  factory AlertService() => instance;

  final AudioPlayer _player = AudioPlayer();
  final FlutterTts _tts = FlutterTts();
  bool _isPlaying = false;
  DateTime? _snoozeUntil;
  // Global config: allow app-wide haptics-only mode
  static final ValueNotifier<bool> hapticsOnly = ValueNotifier<bool>(false);
  // Global alert volume (0.0 - 1.0)
  static final ValueNotifier<double> volume = ValueNotifier<double>(0.8);

  void _ensureTtsConfigured() {
    if (Platform.isAndroid) {
      _tts.setSpeechRate(0.5); // slower on Android
    } else if (Platform.isIOS) {
      _tts.setSpeechRate(0.45); // iOS tends to be faster at same rate
    } else {
      _tts.setSpeechRate(0.5);
    }
    _tts.setVolume(volume.value);
    _tts.setPitch(1.0);
    _tts.awaitSpeakCompletion(true);
  }

  void setVolume(double v) {
    volume.value = v.clamp(0.0, 1.0);
    // Apply to TTS immediately; audio player volume will be set on next play
    _tts.setVolume(volume.value);
  }

  bool get isSnoozed => _snoozeUntil != null && DateTime.now().isBefore(_snoozeUntil!);

  Future<void> snooze({int seconds = 60}) async {
    _snoozeUntil = DateTime.now().add(Duration(seconds: seconds));
    await stop();
  }

  Future<void> play(AlertType type) async {
    _ensureTtsConfigured();
    if (isSnoozed) return;
    if (_isPlaying) return;
    _isPlaying = true;

    try {
      // Haptic-only mode: skip audio, just vibrate patterns
      if (hapticsOnly.value) {
        await _vibratePattern(type, stage: 1);
        await Future.delayed(const Duration(seconds: 2));
        await _vibratePattern(type, stage: 2);
        return;
      }

      // Stage 1: gentle beep + mild haptics
      await _player.setVolume(0.4 * volume.value);
      await _player.play(AssetSource('sounds/alert.mp3'));
      await _vibratePattern(type, stage: 1);

      // Wait for acknowledgement window (3s)
      await Future.delayed(const Duration(seconds: 3));
      if (isSnoozed) return;

      // Stage 2: louder beep + stronger haptics
      await _player.setVolume(0.8 * volume.value);
      await _player.play(AssetSource('sounds/alert.mp3'));
      await _vibratePattern(type, stage: 2);

      // Wait and escalate to voice prompt if still not acknowledged
      await Future.delayed(const Duration(seconds: 3));
      if (isSnoozed) return;

      // Stage 3: TTS prompt
      final prompt = type == AlertType.drowsy
          ? "Warning. Drowsiness detected. Please stay alert."
          : "Warning. Head tilt detected. Please focus on the road.";
      await _tts.speak(prompt);
    } catch (_) {
      // swallow
    } finally {
      _isPlaying = false;
    }
  }

  // Quick test alert used by Settings screen
  Future<void> test(AlertType type) async {
    _ensureTtsConfigured();
    try {
      if (hapticsOnly.value) {
        await _vibratePattern(type, stage: 1);
        return;
      }
      await _player.setVolume(0.5 * volume.value);
      await _player.play(AssetSource('sounds/alert.mp3'));
      await Future.delayed(const Duration(milliseconds: 500));
      await _tts.speak('Test alert');
    } catch (_) {}
  }

  Future<void> _vibratePattern(AlertType type, {required int stage}) async {
    if (await Vibration.hasVibrator() ?? false) {
      if (type == AlertType.drowsy) {
        // Drowsy: pulse pattern
        final pattern = stage == 1 ? [0, 200, 150, 200] : [0, 300, 150, 300, 150, 300];
        final intensities = stage == 1 ? [100, 200] : [128, 255, 200];
        Vibration.vibrate(pattern: pattern, intensities: intensities);
      } else {
        // Head tilt: longer buzz
        final pattern = stage == 1 ? [0, 300] : [0, 500, 200, 500];
        final intensities = stage == 1 ? [150] : [200, 255];
        Vibration.vibrate(pattern: pattern, intensities: intensities);
      }
    }
  }

  Future<void> stop() async {
    try {
      await _player.stop();
      await _tts.stop();
      Vibration.cancel();
    } finally {
      _isPlaying = false;
    }
  }

  // Singleton—no-op dispose to avoid invalidating shared instance
  void dispose() {}
}