import 'package:flutter/foundation.dart';

class SessionStats {
  final DateTime start;
  DateTime? end;
  final List<double> attentionHistory = <double>[];
  int alerts = 0;
  int drowsy = 0;
  int headTilt = 0;

  SessionStats(this.start);
}

class SessionService {
  SessionService._();
  // Eagerly initialized singleton to avoid LateInitializationError
  static final SessionService instance = SessionService._();

  // Reactive session state
  final ValueNotifier<bool> active = ValueNotifier(false);
  final ValueNotifier<SessionStats?> current = ValueNotifier<SessionStats?>(null);

  // Start a new session
  void start() {
    if (active.value) return;
    current.value = SessionStats(DateTime.now());
    active.value = true;
  }

  // Stop current session
  void stop() {
    if (!active.value) return;
    current.value?.end = DateTime.now();
    active.value = false;
  }

  // Push attention score (0..100); keep last ~120 samples (e.g., ~2 minutes if pushed ~1s)
  void pushAttention(double score) {
    final s = current.value;
    if (s == null) return;
    s.attentionHistory.add(score.clamp(0.0, 100.0));
    if (s.attentionHistory.length > 120) {
      s.attentionHistory.removeAt(0);
    }
    // Notify listeners that current content changed
    current.notifyListeners();
  }

  // Register an alert during a session
  void onAlert({required bool isDrowsy}) {
    final s = current.value;
    if (s == null) return;
    s.alerts += 1;
    if (isDrowsy) {
      s.drowsy += 1;
    } else {
      s.headTilt += 1;
    }
    current.notifyListeners();
  }
}
