import 'package:flutter/material.dart';

class BreathingCircle extends StatefulWidget {
  final double size;
  const BreathingCircle({super.key, this.size = 160});

  @override
  State<BreathingCircle> createState() => _BreathingCircleState();
}

class _BreathingCircleState extends State<BreathingCircle> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // 6s cycle ~ 3s inhale, 3s exhale
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _phase(double t) {
    // 0..1 forward = inhale, backward = exhale (using status is easier)
    return _controller.status == AnimationStatus.forward ? 'Inhale' : 'Exhale';
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value; // 0..1
          final scale = 0.85 + (t * 0.30); // 0.85..1.15
          final color = Color.lerp(Colors.deepPurpleAccent, Colors.cyanAccent, t)!;

          return Stack(
            alignment: Alignment.center,
            children: [
              Transform.scale(
                scale: scale,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [color.withOpacity(0.25), color.withOpacity(0.8)],
                    ),
                    boxShadow: [
                      BoxShadow(color: color.withOpacity(0.4), blurRadius: 24, spreadRadius: 2),
                    ],
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _phase(t),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Breathe ${_controller.status == AnimationStatus.forward ? 'in' : 'out'}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
