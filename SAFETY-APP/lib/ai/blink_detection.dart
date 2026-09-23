class BlinkDetector {
  final double closedThreshold;
  final int minClosedMs;
  final int maxClosedMs;

  bool _wasClosed = false;
  DateTime? _closedAt;
  final List<DateTime> _blinks = [];

  BlinkDetector({
    required this.closedThreshold,
    required this.minClosedMs,
    required this.maxClosedMs,
  });

  bool update(double avgEyeOpenProb) {
    final now = DateTime.now();

    if (avgEyeOpenProb < closedThreshold) {
      if (!_wasClosed) {
        _closedAt = now;
        _wasClosed = true;
      }
    } else {
      if (_wasClosed && _closedAt != null) {
        final closedDuration = now.difference(_closedAt!).inMilliseconds;
        if (closedDuration >= minClosedMs && closedDuration <= maxClosedMs) {
          _blinks.add(now);
          _blinks.removeWhere((t) => now.difference(t).inSeconds > 60);
          _wasClosed = false;
          _closedAt = null;
          return true;
        }
      }
      _wasClosed = false;
      _closedAt = null;
    }
    return false;
  }

  int blinksPerMinute() {
    final now = DateTime.now();
    _blinks.removeWhere((t) => now.difference(t).inSeconds > 60);
    return _blinks.length;
  }
}
