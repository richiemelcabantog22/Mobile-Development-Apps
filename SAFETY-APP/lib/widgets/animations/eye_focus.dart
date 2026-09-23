import 'dart:math' as math;
import 'package:flutter/material.dart';

class EyeFocusAnimation extends StatefulWidget {
  final double width;
  final double height;
  const EyeFocusAnimation({super.key, this.width = 240, this.height = 140});

  @override
  State<EyeFocusAnimation> createState() => _EyeFocusAnimationState();
}

class _EyeFocusAnimationState extends State<EyeFocusAnimation> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // 1.2s back and forth to simulate focus shift
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Offset _pupilOffset(double t, Size size) {
    // t: 0..1, use smooth curve for ease-in-out
    final s = 0.5 - 0.5 * math.cos(t * math.pi); // 0..1
    final x = lerpDouble(0.25 * size.width, 0.75 * size.width, s)!;
    final y = size.height * 0.5;
    return Offset(x, y);
  }

  double? lerpDouble(double a, double b, double t) => a + (b - a) * t;

  @override
  Widget build(BuildContext context) {
    final size = Size(widget.width, widget.height);

    return SizedBox(
      width: size.width,
      height: size.height,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          final pupil = _pupilOffset(t, size);
          final isNear = _controller.status == AnimationStatus.forward; // toggle label

          return CustomPaint(
            painter: _EyePainter(
              pupil: pupil,
              nearActive: isNear,
            ),
          );
        },
      ),
    );
  }
}

class _EyePainter extends CustomPainter {
  final Offset pupil;
  final bool nearActive;

  _EyePainter({required this.pupil, required this.nearActive});

  @override
  void paint(Canvas canvas, Size size) {
    final eyeRect = Rect.fromCenter(center: Offset(size.width / 2, size.height / 2), width: size.width * 0.8, height: size.height * 0.5);
    final eyePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = Colors.white70;

    // Eye outline (ellipse)
    canvas.drawOval(eyeRect, eyePaint);

    // Pupil
    final pupilPaint = Paint()..color = Colors.deepPurpleAccent;
    canvas.drawCircle(pupil, size.shortestSide * 0.06, pupilPaint);

    // Near/Far markers
    final nearPos = Offset(eyeRect.left - 16, eyeRect.center.dy);
    final farPos = Offset(eyeRect.right + 16, eyeRect.center.dy);

    final nearColor = nearActive ? Colors.cyanAccent : Colors.white24;
    final farColor = nearActive ? Colors.white24 : Colors.cyanAccent;

    canvas.drawCircle(nearPos, 8, Paint()..color = nearColor);
    canvas.drawCircle(farPos, 8, Paint()..color = farColor);

    // Labels
    final textPainterNear = _tp('Near', nearActive ? Colors.cyanAccent : Colors.white54);
    textPainterNear.layout();
    textPainterNear.paint(canvas, Offset(nearPos.dx - textPainterNear.width - 6, nearPos.dy - textPainterNear.height / 2));

    final textPainterFar = _tp('Far', !nearActive ? Colors.cyanAccent : Colors.white54);
    textPainterFar.layout();
    textPainterFar.paint(canvas, Offset(farPos.dx + 6, farPos.dy - textPainterFar.height / 2));
  }

  TextPainter _tp(String s, Color c) => TextPainter(
        text: TextSpan(text: s, style: TextStyle(color: c, fontSize: 12)),
        textDirection: TextDirection.ltr,
      );

  @override
  bool shouldRepaint(covariant _EyePainter oldDelegate) {
    return oldDelegate.pupil != pupil || oldDelegate.nearActive != nearActive;
  }
}
