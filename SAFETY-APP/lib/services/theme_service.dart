import 'package:flutter/material.dart';
import '../database/hive_database.dart';
import '../models/ui_prefs.dart';

class ThemeService {
  ThemeService._();
  static final ThemeService instance = ThemeService._();

  final ValueNotifier<ThemeMode> mode = ValueNotifier<ThemeMode>(ThemeMode.dark);
  final ValueNotifier<String> accent = ValueNotifier<String>('purple'); // 'purple'|'cyan'|'amber'
  final ValueNotifier<double> textScale = ValueNotifier<double>(1.0);

  Future<void> init() async {
    final box = HiveDatabase.prefsBox;
    if (box.isEmpty) {
      await box.add(UiPrefs.defaults());
    }
    final prefs = box.getAt(0) ?? UiPrefs.defaults();
    mode.value = _modeFromIndex(prefs.themeModeIndex);
    accent.value = prefs.accentName;
    textScale.value = prefs.textScale;
  }

  Future<void> setMode(ThemeMode newMode) async {
    mode.value = newMode;
    final box = HiveDatabase.prefsBox;
    final prefs = box.getAt(0) ?? UiPrefs.defaults();
    prefs.themeModeIndex = _indexFromMode(newMode);
    await prefs.save();
  }

  Future<void> setAccent(String name) async {
    accent.value = name;
    final box = HiveDatabase.prefsBox;
    final prefs = box.getAt(0) ?? UiPrefs.defaults();
    prefs.accentName = name;
    await prefs.save();
  }

  Future<void> setTextScale(double scale) async {
    textScale.value = scale;
    final box = HiveDatabase.prefsBox;
    final prefs = box.getAt(0) ?? UiPrefs.defaults();
    prefs.textScale = scale;
    await prefs.save();
  }

  int _indexFromMode(ThemeMode m) {
    switch (m) {
      case ThemeMode.light:
        return 1;
      case ThemeMode.dark:
        return 2;
      case ThemeMode.system:
      default:
        return 0;
    }
  }

  ThemeMode _modeFromIndex(int i) {
    switch (i) {
      case 1:
        return ThemeMode.light;
      case 2:
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  // Helper: provide seed color from accent
  Color seedColor() {
    switch (accent.value) {
      case 'cyan':
        return Colors.cyanAccent;
      case 'amber':
        return Colors.amberAccent;
      case 'purple':
      default:
        return Colors.deepPurpleAccent;
    }
  }
}
