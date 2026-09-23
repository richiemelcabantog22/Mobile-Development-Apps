String formatDurationMs(int ms) {
  final s = (ms / 1000).toStringAsFixed(2);
  return '${s}s';
}