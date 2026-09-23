import 'package:flutter/material.dart';

class IconCapsule extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;
  final bool expand;

  const IconCapsule({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = Colors.cyanAccent,
    this.expand = false,
  });

  @override
  Widget build(BuildContext context) {
    final child = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.22), Colors.white.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: color.withOpacity(0.45)),
          boxShadow: [BoxShadow(color: color.withOpacity(0.18), blurRadius: 16, offset: const Offset(0, 8))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(letterSpacing: 0.4)),
          ],
        ),
      ),
    );

    return expand
        ? SizedBox(width: (MediaQuery.of(context).size.width - 16 * 2 - 12) / 2, child: Center(child: child))
        : child;
  }
}
