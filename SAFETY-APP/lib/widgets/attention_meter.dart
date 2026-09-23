import 'package:flutter/material.dart';

class AttentionMeter extends StatelessWidget {
  final double score; // 0..100
  const AttentionMeter({super.key, required this.score});

  Color _colorFor(double s) {
    if (s >= 80) return Colors.greenAccent;
    if (s >= 60) return Colors.limeAccent;
    if (s >= 40) return Colors.orangeAccent;
    if (s >= 20) return Colors.deepOrangeAccent;
    return Colors.redAccent;
    }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 18,
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(10),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          FractionallySizedBox(
            widthFactor: (score / 100.0).clamp(0.0, 1.0),
            child: Container(color: _colorFor(score)),
          ),
          Center(
            child: Text(
              'Attention ${score.toStringAsFixed(0)}%',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}