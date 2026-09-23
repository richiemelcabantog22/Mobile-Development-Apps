import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../widgets/neon_panel.dart';
import '../widgets/sparkline.dart';
import '../database/hive_database.dart';
import '../models/drowsiness_record.dart';
import '../services/session_service.dart';

class SessionSummaryScreen extends StatelessWidget {
  final DateTime start;
  final DateTime end;
  final SessionStats? stats;
  const SessionSummaryScreen({super.key, required this.start, required this.end, this.stats});

  @override
  Widget build(BuildContext context) {
    final Box<DrowsinessRecord> box = HiveDatabase.drowsinessBox;
    // Filter records within the session window
    final events = box.values.where((r) => !r.timestamp.isBefore(start) && !r.timestamp.isAfter(end)).toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Count per type
    final Map<String, int> typeCounts = {'Drowsy': 0, 'HeadTilt': 0, 'Dizziness': 0, 'Yawn': 0};
    for (final e in events) {
      if (typeCounts.containsKey(e.type)) {
        typeCounts[e.type] = (typeCounts[e.type] ?? 0) + 1;
      }
    }
    final totalAlerts = typeCounts['Drowsy']! + typeCounts['HeadTilt']! + typeCounts['Dizziness']!;

    // Timeline bucket per minute
    final int minutes = end.difference(start).inMinutes.clamp(1, 240);
    final List<int> buckets = List<int>.filled(minutes, 0);
    for (final e in events) {
      final idx = e.timestamp.difference(start).inMinutes;
      if (idx >= 0 && idx < minutes) buckets[idx] += 1;
    }

    final durStr = _formatDuration(end.difference(start));
    final dateStr = '${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Session Summary'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context), // back to Dashboard
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          NeonPanel(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.assessment, color: Colors.cyanAccent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Date: $dateStr', style: const TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text('Duration: $durStr'),
                        Text('Total alerts: $totalAlerts  •  Yawns: ${typeCounts['Yawn']}'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          NeonPanel(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Alerts by type', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      _chip('Drowsy', typeCounts['Drowsy']!, Colors.amberAccent),
                      _chip('HeadTilt', typeCounts['HeadTilt']!, Colors.cyanAccent),
                      _chip('Dizziness', typeCounts['Dizziness']!, Colors.pinkAccent),
                      _chip('Yawn', typeCounts['Yawn']!, Colors.limeAccent),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (events.isNotEmpty)
            NeonPanel(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Alerts timeline', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    SizedBox(height: 120, child: _MiniBarChart(values: buckets)),
                    const SizedBox(height: 4),
                    Text('From ${_fmtTime(start)} to ${_fmtTime(end)}', style: const TextStyle(color: Colors.white54)),
                  ],
                ),
              ),
            ),
          if (stats?.attentionHistory.isNotEmpty == true) ...[
            const SizedBox(height: 12),
            NeonPanel(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Attention trend', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    SizedBox(height: 80, child: Sparkline(data: List<double>.from(stats!.attentionHistory))),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.dashboard_outlined),
              label: const Text('Back to Dashboard'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.45)),
        color: Colors.white.withOpacity(0.06),
        boxShadow: [BoxShadow(color: color.withOpacity(0.12), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Text('$label: $count'),
    );
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) return '${h}h ${m}m ${s}s';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
    }

  String _fmtTime(DateTime t) {
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }
}

class _MiniBarChart extends StatelessWidget {
  final List<int> values;
  const _MiniBarChart({required this.values});

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty || values.every((v) => v == 0)) {
      return const Center(child: Text('No alerts during session', style: TextStyle(color: Colors.white54)));
    }
    return CustomPaint(
      painter: _BarsPainter(values),
      size: Size.infinite,
    );
  }
}

class _BarsPainter extends CustomPainter {
  final List<int> values;
  _BarsPainter(this.values);

  @override
  void paint(Canvas canvas, Size size) {
    final maxVal = values.fold<int>(0, (m, v) => v > m ? v : m);
    final paint = Paint()..color = Colors.cyanAccent.withOpacity(0.9);
    final barW = (size.width / values.length).clamp(1.5, 18.0);
    for (int i = 0; i < values.length; i++) {
      final v = values[i];
      if (v == 0) continue;
      final hRatio = maxVal == 0 ? 0.0 : v / maxVal;
      final barH = hRatio * (size.height - 8);
      final x = i * (size.width / values.length);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x + 1, size.height - barH, barW - 2, barH),
        const Radius.circular(3),
      );
      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BarsPainter oldDelegate) => oldDelegate.values != values;
}
