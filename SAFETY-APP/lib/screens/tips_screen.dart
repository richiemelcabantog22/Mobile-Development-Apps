import 'package:flutter/material.dart';
import '../widgets/neon_panel.dart';

class TipsScreen extends StatelessWidget {
  const TipsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tips = const [
      {
        'title': 'Mounting',
        'body': 'Mount the phone at eye level, centered, about 50–70 cm from your face. Ensure the mount is stable.'
      },
      {
        'title': 'Lighting',
        'body': 'Avoid strong backlight. Use soft cabin lighting at night for better face detection.'
      },
      {
        'title': 'Position',
        'body': 'Sit upright with a clear view of the camera. Avoid covering your face with hands or accessories.'
      },
      {
        'title': 'Privacy',
        'body': 'All processing happens on-device. No video frames are uploaded.'
      },
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Tips & Help')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: tips.length,
        itemBuilder: (_, i) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: NeonPanel(
            child: ListTile(
              leading: const Icon(Icons.info_outline, color: Colors.cyanAccent),
              title: Text(tips[i]['title']!, style: const TextStyle(letterSpacing: 0.4)),
              subtitle: Text(tips[i]['body']!),
            ),
          ),
        ),
      ),
    );
  }
}