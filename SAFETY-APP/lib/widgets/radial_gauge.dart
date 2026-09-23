import 'package:flutter/material.dart';

class RadialGauge extends StatelessWidget {
  final double value; // 0..100
  final double size;
  final String? label;
  final List<Color> gradientColors;

  const RadialGauge({
    super.key,
    required this.value,
    this.size = 96,
    this.label,
    this.gradientColors = const [Colors.cyanAccent, Colors.deepPurpleAccent],
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GaugePainter(value / 100.0, gradientColors),
        child: Center(
          child: Text(
            label ?? value.toStringAsFixed(0),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double t; // 0..1
  final List<Color> colors;
  _GaugePainter(this.t, this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.10;
    final rect = Offset.zero & size;
    final start = -3.14 * 3 / 4; // -135°
    final sweep = 3.14 * 1.5;    // 270°

    final bg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = Colors.white.withOpacity(0.08)
      ..strokeCap = StrokeCap.round;

    final fg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..shader = SweepGradient(
        startAngle: start,
        endAngle: start + sweep,
        colors: colors,
      ).createShader(rect)
      ..strokeCap = StrokeCap.round;

    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - stroke) / 2;

    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), start, sweep, false, bg);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), start, sweep * t, false, fg);
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) => oldDelegate.t != t || oldDelegate.colors != colors;
}
