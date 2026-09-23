import 'package:flutter/material.dart';

class NeonPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  const NeonPanel({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.secondary;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        // Futuristic translucent surface with subtle gradient and border glow
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.06),
            Colors.white.withOpacity(0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: accent.withOpacity(0.35), width: 1),
        boxShadow: [
          BoxShadow(color: accent.withOpacity(0.12), blurRadius: 18, offset: const Offset(0, 8)),
        ],
      ),
      child: child,
    );
  }
}
