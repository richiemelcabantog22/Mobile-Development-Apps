import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../database/hive_database.dart'; // ADD: to read onboarding flag

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _routeNext(); // CHANGED: decide onboarding vs dashboard
  }

  Future<void> _routeNext() async {
    // small splash delay
    await Future.delayed(const Duration(milliseconds: 1200));
    bool onboarded = false;
    try {
      // requires HiveDatabase.registerAdaptersAndOpen() called in main()
      onboarded = (HiveDatabase.kvBox.get('onboarded') as bool?) ?? false;
    } catch (_) {
      // if kv box isn't ready for any reason, fall back to dashboard
      onboarded = true;
    }
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, onboarded ? '/dashboard' : '/onboarding');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B10),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // App icon/logo
              SizedBox(
                width: 120,
                height: 120,
                child: Image.asset(
                  'assets/branding/logo.png', // replace with your logo asset
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'DriveGuard',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 20),
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Colors.deepPurpleAccent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}