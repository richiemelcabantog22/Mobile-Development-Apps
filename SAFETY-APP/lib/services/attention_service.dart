import '../services/drowsiness_service.dart';

class AttentionService {
  double _score = 100.0;
  DateTime? _lastUpdate;

  double get score => _score.clamp(0.0, 100.0);

  void update(DrowsinessState state) {
    final now = DateTime.now();
    final dt = _lastUpdate == null ? 0.2 : (now.difference(_lastUpdate!).inMilliseconds / 1000.0);
    _lastUpdate = now;

    // Recovery rate per second
    const recoveryPerSec = 8.0;
    _score = (_score + recoveryPerSec * dt).clamp(0.0, 100.0);

    switch (state.type) {
      case AlertType.drowsy:
        _score -= 30;
        break;
      case AlertType.headTilt:
        _score -= 20;
        break;
      case AlertType.fatigue:
        _score -= 15;
        break;
      case AlertType.yawn:
        _score -= 10;
        break;
      case AlertType.dizziness: // ADD: handle new enum value
        _score -= 25;
        break;
      case AlertType.none:
        // no penalty, only recovery
        break;
      // Optional safeguard for future enum additions:
      // default:
      //   break;
    }

    if (state.alert) {
      // extra penalty if audible alert active
      _score -= 10;
    }

    // Re-clamp after penalties
    _score = _score.clamp(0.0, 100.0);
  }
}