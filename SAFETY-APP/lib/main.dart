import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'database/hive_database.dart';
import 'services/theme_service.dart';

import 'screens/splash_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/monitoring_screen.dart';
import 'screens/history_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/wakeup_routine_screen.dart';
import 'screens/tips_screen.dart';
import 'screens/diagnostics_screen.dart';
import 'screens/about_privacy_screen.dart';
import 'screens/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveDatabase.registerAdaptersAndOpen();
  await ThemeService.instance.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  ThemeData _buildTheme(Brightness brightness) {
    final seed = ThemeService.instance.seedColor();
    final scheme = ColorScheme.fromSeed(seedColor: seed, brightness: brightness);
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      scaffoldBackgroundColor: brightness == Brightness.dark ? const Color(0xFF0B0B10) : null,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface.withOpacity(0.6),
        foregroundColor: scheme.onSurface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: scheme.primary,
        contentTextStyle: TextStyle(color: scheme.onPrimary),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: ThemeService.instance.accent,  
      builder: (_, __accent, __) {
        return ValueListenableBuilder<ThemeMode>(
          valueListenable: ThemeService.instance.mode,
          builder: (_, mode, __) {
            return ValueListenableBuilder<double>(
              valueListenable: ThemeService.instance.textScale,
              builder: (_, scale, __) {
                return MaterialApp(
                  debugShowCheckedModeBanner: false,
                  title: 'DriveGuard',
                  themeMode: mode,
                  theme: _buildTheme(Brightness.light),
                  darkTheme: _buildTheme(Brightness.dark),
                  builder: (context, child) {
                    final media = MediaQuery.of(context);
                    try {
                      return MediaQuery(
                        data: media.copyWith(textScaler: TextScaler.linear(scale)),
                        child: child ?? const SizedBox.shrink(),
                      );
                    } catch (_) {
                      return MediaQuery(
                        data: media.copyWith(textScaleFactor: scale),
                        child: child ?? const SizedBox.shrink(),
                      );
                    }
                  },
                  initialRoute: '/',
                  routes: {
                    '/': (_) => const SplashScreen(),
                    '/onboarding': (_) => const OnboardingScreen(),
                    '/dashboard': (_) => const DashboardScreen(),
                    '/monitor': (_) => const MonitoringScreen(),
                    '/history': (_) => const HistoryScreen(),
                    '/settings': (_) => const SettingsScreen(),
                    '/wakeup': (_) => const WakeUpRoutineScreen(),
                    '/tips': (_) => const TipsScreen(),
                    '/diagnostics': (_) => const DiagnosticsScreen(),
                    '/about': (_) => const AboutPrivacyScreen(),
                    '/session_summary': (_) {
                      // This route is not used directly; we push SessionSummaryScreen with parameters.
                      return const Scaffold(body: SizedBox.shrink());
                    },
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}