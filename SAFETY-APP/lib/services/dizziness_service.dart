import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';
import '../core/constants.dart';

class DizzinessService {
  // Rolling buffers (last ~5s)
  final List<DateTime> _times = [];
  final List<double> _rollDeg = []; // head roll angle Z
  final List<double> _gyroMag = []; // |gyro| in rad/s

  // EMA smoothing for score
  double? _emaScore;
  static const double _emaAlpha = 0.3;

  // Config
  final Duration window = const Duration(seconds: 5);

  void push({required double headRollDeg, GyroscopeEvent? gyro}) {
    final now = DateTime.now();
    _times.add(now);
    _rollDeg.add(headRollDeg);
    if (gyro != null) {
      final mag = sqrt(gyro.x * gyro.x + gyro.y * gyro.y + gyro.z * gyro.z);
      _gyroMag.add(mag);
    } else {
      _gyroMag.add(0.0);
    }
    _trim(now);
  }

  // Simple sway amplitude & rhythmicity estimation + gaze instability proxy via gyro magnitude
  double score() {
    // Require enough samples and window duration to stabilize estimates
    if (_rollDeg.length < 15 || _elapsedSeconds() < 2.5) return _smooth(0.0);

    final mean = _rollDeg.reduce((a, b) => a + b) / _rollDeg.length;
    final centered = _rollDeg.map((v) => v - mean).toList();

    // Amplitude (peak-to-peak over window)
    final amp = (centered.reduce(max).abs() + centered.reduce(min).abs());

    // Rhythmicity proxy: zero-crossings per second (approx frequency)
    int zeroCross = 0;
    for (int i = 1; i < centered.length; i++) {
      if (centered[i - 1] == 0) continue;
      if ((centered[i - 1] > 0) != (centered[i] > 0)) zeroCross++;
    }
    final seconds = max(1e-3, _elapsedSeconds());
    final freq = (zeroCross / 2) / seconds; // cycles/sec

    // Gyro instability (mean magnitude)
    final gyroMean = _gyroMag.reduce((a, b) => a + b) / _gyroMag.length;

    // Conservative gating to reduce false positives when still
    // If essentially still: low gyro and low head roll amplitude → return 0
    if (gyroMean < 0.08 && amp < 6.0) {
      return _smooth(0.0);
    }

    // Penalize non-dizzy frequencies (<0.15 Hz slow drift, >0.8 Hz too fast/jitter)
    final inBand = (freq >= 0.15 && freq <= 0.8) ? 1.0 : 0.3;

    // Normalize components conservatively
    final ampScore = (amp / 20.0).clamp(0.0, 1.0);       // 0..~20 deg peak-to-peak
    final freqScore = ((freq / 0.5).clamp(0.0, 1.0)) * inBand; // 0..0.5 Hz ideal
    final gyroScore = (gyroMean / 1.2).clamp(0.0, 1.0);  // typical handheld jitter < 1.2

    // Weighted combination with stronger emphasis on amplitude; smooth via EMA
    final raw = (0.6 * ampScore + 0.2 * freqScore + 0.2 * gyroScore).clamp(0.0, 1.0);
    return _smooth(raw);
  }

  void reset() {
    _times.clear();
    _rollDeg.clear();
    _gyroMag.clear();
    _emaScore = null;
  }

  void _trim(DateTime now) {
    while (_times.isNotEmpty && now.difference(_times.first) > window) {
      _times.removeAt(0);
      _rollDeg.removeAt(0);
      _gyroMag.removeAt(0);
    }
  }

  double _elapsedSeconds() {
    if (_times.length < 2) return 0.0;
    return _times.last.difference(_times.first).inMilliseconds / 1000.0;
  }

  double _smooth(double val) {
    if (_emaScore == null) {
      _emaScore = val;
    } else {
      _emaScore = _emaAlpha * val + (1 - _emaAlpha) * _emaScore!;
    }
    return _emaScore!;
  }
}
