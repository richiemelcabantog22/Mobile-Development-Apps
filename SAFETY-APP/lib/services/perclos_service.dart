import 'dart:collection';
import '../core/constants.dart';

class PerclosService {
  final Queue<DateTime> _closedEvents = Queue<DateTime>();
  final Queue<DateTime> _allFrames = Queue<DateTime>();

  void push({required bool eyesClosed, DateTime? now}) {
    final t = now ?? DateTime.now();
    _allFrames.addLast(t);
    if (eyesClosed) {
      _closedEvents.addLast(t);
    }
    _trimOld(t);
  }

  double perclos(DateTime? now) {
    final t = now ?? DateTime.now();
    _trimOld(t);
    final total = _allFrames.length;
    if (total == 0) return 0.0;
    return _closedEvents.length / total;
  }

  void reset() {
    _closedEvents.clear();
    _allFrames.clear();
  }

  void _trimOld(DateTime now) {
    final cutoff = now.subtract(Duration(seconds: AppConstants.perclosWindowSeconds));
    while (_allFrames.isNotEmpty && _allFrames.first.isBefore(cutoff)) {
      _allFrames.removeFirst();
    }
    while (_closedEvents.isNotEmpty && _closedEvents.first.isBefore(cutoff)) {
      _closedEvents.removeFirst();
    }
  }
}
