import 'dart:math';
import 'package:flutter/material.dart';

class ProgressRing extends StatelessWidget {
  final int totalSeconds;
  final int remainingSeconds;
  final double size;
  const ProgressRing({super.key, required this.totalSeconds, required this.remainingSeconds, this.size = 120});

  @override
  Widget build(BuildContext context) {
    final pct = totalSeconds == 0 ? 0.0 : (remainingSeconds / totalSeconds).clamp(0.0, 1.0);
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(progress: pct),
        child: Center(
          child: Text(
            '${remainingSeconds}s',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress; // 0..1
  _RingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = 8.0;
    final rect = Offset.zero & size;

    final bg = Paint()
      ..color = Colors.white10
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;

    final fg = Paint()
      ..shader = SweepGradient(
        colors: const [Colors.deepPurpleAccent, Colors.cyanAccent, Colors.deepPurpleAccent],
        startAngle: -pi / 2,
        endAngle: -pi / 2 + 2 * pi * progress,
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = stroke;

    // Background circle
    canvas.drawArc(Rect.fromLTWH(stroke / 2, stroke / 2, size.width - stroke, size.height - stroke), 0, 2 * pi, false, bg);
    // Progress arc
    canvas.drawArc(Rect.fromLTWH(stroke / 2, stroke / 2, size.width - stroke, size.height - stroke), -pi / 2, 2 * pi * progress, false, fg);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) => oldDelegate.progress != progress;
}
