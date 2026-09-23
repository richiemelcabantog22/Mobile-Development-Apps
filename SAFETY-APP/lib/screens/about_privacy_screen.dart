import 'package:flutter/material.dart';

class AboutPrivacyScreen extends StatelessWidget {
  const AboutPrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About & Privacy')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('About'),
            subtitle: Text('AI-Powered Driver Safety detects drowsiness and head tilt in real-time on your device.'),
          ),
          ListTile(
            leading: Icon(Icons.privacy_tip_outlined),
            title: Text('Privacy'),
            subtitle: Text('All processing happens on-device. No video frames are uploaded to servers. Only anonymous event statistics are stored locally.'),
          ),
          ListTile(
            leading: Icon(Icons.gavel_outlined),
            title: Text('Terms'),
            subtitle: Text('Use at your own risk. Always keep your attention on the road.'),
          ),
          ListTile(
            leading: Icon(Icons.numbers_outlined),
            title: Text('Version'),
            subtitle: Text('v0.1.0'),
          ),
        ],
      ),
    );
  }
}
