import 'package:flutter/material.dart';
import '../../../../services/user_progress_service.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key, required this.onFinish});
  final VoidCallback onFinish;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _controller = PageController();
  int _page = 0;

  final _pages = const [
    _OnboardSlide(
      icon: Icons.map_rounded,
      title: 'Explore Regions',
      message:
          'Discover folklore by island group and province. Use the Regions tab and filter Luzon, Visayas, Mindanao.',
    ),
    _OnboardSlide(
      icon: Icons.favorite_rounded,
      title: 'Grimoire & Notes',
      message:
          'Tap the heart to add creatures to your Grimoire and write your own study notes for quick review.',
    ),
    _OnboardSlide(
      icon: Icons.view_in_ar_rounded,
      title: '3D, AR, Quiz & Flashcards',
      message:
          'Open 3D/AR viewers to inspect models, then test yourself via Quizzes and the Flashcards study mode.',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await UserProgressService.instance.setOnboardingSeen();
    widget.onFinish();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            children: [
              // Header/logo
              const SizedBox(height: 12),
              CircleAvatar(
                radius: 36,
                backgroundColor: cs.primary.withOpacity(0.12),
                child: Icon(Icons.auto_awesome, size: 36, color: cs.primary),
              ),
              const SizedBox(height: 8),
              Text('PAMANA',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),

              // Pager
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemCount: _pages.length,
                  itemBuilder: (_, i) => _pages[i],
                ),
              ),

              // Dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 8,
                    width: _page == i ? 22 : 8,
                    decoration: BoxDecoration(
                      color: _page == i ? cs.primary : cs.outlineVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Buttons
              Row(
                children: [
                  TextButton(
                    onPressed: _finish,
                    child: const Text('Skip'),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: () async {
                      if (_page < _pages.length - 1) {
                        _controller.nextPage(
                            duration: const Duration(milliseconds: 240),
                            curve: Curves.easeOut);
                      } else {
                        await _finish();
                      }
                    },
                    child: Text(_page < _pages.length - 1 ? 'Next' : 'Get Started'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardSlide extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  const _OnboardSlide(
      {required this.icon, required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 72, color: cs.primary),
        const SizedBox(height: 16),
        Text(title,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ],
    );
  }
}