import 'package:just_audio/just_audio.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart';
import 'app_settings_service.dart';

class AudioGovernorService {
  AudioGovernorService._();
  static final AudioGovernorService instance = AudioGovernorService._();

  final AudioPlayer _bgmPlayer = AudioPlayer();
  final FlutterTts _ttsEngine = FlutterTts();
  
  bool _isNarrationPlaying = false;
  bool get isNarrationPlaying => _isNarrationPlaying;

  /// Setup global audio player structures and defaults
  Future<void> initialize() async {
    // 1. Setup Background Ambience asset configurations
    try {
      debugPrint('🎵 AudioGovernor: Initializing background music asset pipeline...');
      
      // CRITICAL FIX: Explicitly direct the player engine to load and cache the target file asset
      await _bgmPlayer.setAsset('assets/audio/ambience_eerie.mp3');
      await _bgmPlayer.load(); // Forces the native player thread to buffer the audio data completely
      
      await _bgmPlayer.setLoopMode(LoopMode.all); // Loop background track infinitely
      await _bgmPlayer.setVolume(0.15);           // Keep background track low and subtle
      
      debugPrint('✅ AudioGovernor: Ambient audio engine configured and preloaded successfully.');
    } catch (e, stackTrace) {
      debugPrint('❌ AUDIO CORE FAILURE: Could not locate, load, or stream asset file!');
      debugPrint('Error details: $e');
      debugPrint('Stack trace:\n$stackTrace');
    }

    // 2. Setup Text-To-Speech audio output profiles
    try {
      await _ttsEngine.setLanguage('en-US'); // Audiobook narrative dialect anchor
      await _ttsEngine.setSpeechRate(0.45);  // Slow, distinct speed for clear research reading
      await _ttsEngine.setVolume(1.0);       // Clear dialogue level focus

      _ttsEngine.setStartHandler(() {
        _isNarrationPlaying = true;
      });

      _ttsEngine.setCompletionHandler(() {
        _isNarrationPlaying = false;
        _resumeBgmGradually(); // Return background music to standard volume levels cleanly
      });

      _ttsEngine.setErrorHandler((msg) {
        debugPrint('⚠️ Narration Engine encountered a stream boundary error: $msg');
        _isNarrationPlaying = false;
        _resumeBgmGradually();
      });
    } catch (ttsError) {
      debugPrint('❌ TTS Initialization skipped or unmapped on host device: $ttsError');
    }
  }

  /// Start playing eerie background music loops across the app shell if enabled by configurations
  void startGlobalAmbience() {
    final isEnabled = AppSettingsService.instance.bgmEnabled;
    debugPrint('🎵 AudioGovernor: startGlobalAmbience checked. BGM Enabled: $isEnabled, Already Playing: ${_bgmPlayer.playing}');
    
    if (isEnabled && !_bgmPlayer.playing) {
      _bgmPlayer.play().catchError((error) {
        debugPrint('❌ AudioGovernor playback runtime error: $error');
      });
    }
  }

  /// Stop or pause global background environment audio tracks
  void pauseGlobalAmbience() {
    if (_bgmPlayer.playing) {
      _bgmPlayer.pause();
    }
  }

  /// A reactive control switch to handle configuration changes mid-session from Settings Page
  void toggleBgmState(bool enabled) {
    if (enabled) {
      startGlobalAmbience();
    } else {
      pauseGlobalAmbience();
    }
  }

  /// Narrate a creature's story text out loud like an audiobook with audio ducking
  Future<void> speakNarration(String text) async {
    if (text.isEmpty) return;
    
    // AUDIO DUCKING: Drop background tracks down so narration remains fully audible
    if (_bgmPlayer.playing) {
      await _bgmPlayer.setVolume(0.04);
    }
    await _ttsEngine.speak(text);
  }

  /// Halt current narrative speech instantly and reset track levels
  Future<void> stopNarration() async {
    await _ttsEngine.stop();
    _isNarrationPlaying = false;
    _resumeBgmGradually();
  }

  /// Scales global ambiance level safely back to baseline
  void _resumeBgmGradually() {
    final isEnabled = AppSettingsService.instance.bgmEnabled;
    if (isEnabled) {
      _bgmPlayer.setVolume(0.30);
    }
  }
  
  /// Handle total resource cleanup when app undergoes complete termination lifecycle
  void dispose() {
    _bgmPlayer.dispose();
    _ttsEngine.stop();
  }
}