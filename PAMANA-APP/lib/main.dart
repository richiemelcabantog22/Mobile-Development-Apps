import 'dart:async';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter/material.dart';
import 'services/folklore_creature_service.dart';
import 'services/user_progress_service.dart';
import 'services/app_settings_service.dart'; 
import 'features/home/presentation/pages/home_page.dart';
import 'features/home/presentation/pages/regional_map_page.dart';
import 'features/quiz/presentation/pages/quiz_page.dart';
import 'features/home/presentation/pages/favorites_page.dart' as grimoire;
import 'features/profile/presentation/pages/profile_page.dart';
import 'features/onboarding/presentation/pages/onboarding_page.dart';
import 'services/audio_governor_service.dart'; 

void main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await FolkloreCreatureService.initialize();
  await FolkloreCreatureService.instance.seedSampleDataIfEmpty();
  await UserProgressService.initialize();
  await AppSettingsService.initialize(); 

  await AudioGovernorService.instance.initialize();
  AudioGovernorService.instance.startGlobalAmbience(); 

  runApp(const PamanaApp());
}

class PamanaApp extends StatelessWidget {
  const PamanaApp({super.key});

  @override
  Widget build(BuildContext context) {
    // FIXED: Invokes the newly exposed service method to track value edits
    return ValueListenableBuilder(
      valueListenable: AppSettingsService.instance.listenable(),
      builder: (context, box, _) {
        // FIXED: Invokes the cleaner internal instance property getter directly
        final currentThemeMode = AppSettingsService.instance.themeMode;

        return MaterialApp(
          title: 'PAMANA',
          debugShowCheckedModeBanner: false,
          themeMode: currentThemeMode,
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF006D5B),
              brightness: Brightness.light,
            ),
            appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF006D5B),
              brightness: Brightness.dark,
            ),
            appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
          ),
          home: const _StartupGate(),
        );
      },
    );
  }
}

class _StartupGate extends StatefulWidget {
  const _StartupGate({super.key});

  @override
  State<_StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<_StartupGate> {
  late Future<bool> _seenFuture;

  @override
  void initState() {
    super.initState();
    _seenFuture = Future<bool>(() => UserProgressService.instance.onboardingSeen);
  }

  void _goToShell() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AppShell()),
    );
    FlutterNativeSplash.remove();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _seenFuture,
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        FlutterNativeSplash.remove();

        final seen = snap.data ?? false;
        if (seen) {
          Future.microtask(_goToShell);
          return const SizedBox.shrink();
        }

        return OnboardingPage(onFinish: _goToShell);
      },
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  void _goToTab(int i) => setState(() => _index = i);

  late final List<Widget> _tabs = <Widget>[
    const HomePage(),
    const RegionalMapPage(),
    QuizPage(onQuizComplete: () => _goToTab(0)),
    const grimoire.FavoritesPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _goToTab,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined), 
            selectedIcon: Icon(Icons.home), 
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined), 
            selectedIcon: Icon(Icons.map), 
            label: 'Regions',
          ),
          NavigationDestination(
            icon: Icon(Icons.quiz_outlined), 
            selectedIcon: Icon(Icons.quiz), 
            label: 'Quiz',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_outline), 
            selectedIcon: Icon(Icons.favorite), 
            label: 'Grimoire',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined), 
            selectedIcon: Icon(Icons.insights), 
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}