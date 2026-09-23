import 'package:flutter/material.dart';

class Sparkline extends StatelessWidget {
  final List<double> data; // expected 0..100
  const Sparkline({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SparklinePainter(data),
      size: const Size(double.infinity, 60),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> data;
  _SparklinePainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    final paint = Paint()
      ..color = Colors.deepPurpleAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path();
    final n = data.length;
    final dx = size.width / (n - 1).clamp(1, 9999);
    for (int i = 0; i < n; i++) {
      final x = i * dx;
      final v = data[i].clamp(0.0, 100.0);
      final y = size.height - (v / 100.0) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.data != data;
  }
}
