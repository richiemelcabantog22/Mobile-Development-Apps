import 'package:flutter/material.dart';
import '../widgets/neon_panel.dart';
import '../database/hive_database.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pager = PageController();
  int _index = 0;

  final _pages = const [
    _OnboardPage(
      icon: Icons.phone_android,
      title: 'Mount at Eye Level',
      body: 'Place your device at eye level, 50–70 cm away. Keep the mount stable and centered.',
    ),
    _OnboardPage(
      icon: Icons.light_mode,
      title: 'Good Lighting',
      body: 'Avoid harsh backlight. Use soft cabin lighting at night for reliable face detection.',
    ),
    _OnboardPage(
      icon: Icons.privacy_tip_outlined,
      title: 'On‑Device & Private',
      body: 'All processing happens on your device. Only event summaries are stored locally.',
    ),
  ];

  void _next() {
    if (_index < _pages.length - 1) {
      _pager.nextPage(duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    } else {
      // Mark as completed and go to dashboard
      HiveDatabase.kvBox.put('onboarded', true);
      Navigator.pushReplacementNamed(context, '/dashboard');
    }
  }

  void _skip() {
    HiveDatabase.kvBox.put('onboarded', true);
    Navigator.pushReplacementNamed(context, '/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    final dots = List.generate(_pages.length, (i) {
      final active = i == _index;
      return AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: active ? 18 : 8,
        height: 8,
        margin: const EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(
          color: active ? Colors.cyanAccent : Colors.white24,
          borderRadius: BorderRadius.circular(12),
        ),
      );
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome'),
        actions: [
          TextButton(onPressed: _skip, child: const Text('Skip')),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pager,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (_, i) => NeonPanel(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: _pages[i],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: dots,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _next,
                icon: Icon(_index < _pages.length - 1 ? Icons.arrow_forward : Icons.check),
                label: Text(_index < _pages.length - 1 ? 'Next' : 'Get Started'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardPage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  const _OnboardPage({required this.icon, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 8),
        Icon(icon, size: 64, color: Colors.cyanAccent),
        const SizedBox(height: 12),
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 0.6)),
        const SizedBox(height: 8),
        Text(body, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
      ],
    );
  }
}
