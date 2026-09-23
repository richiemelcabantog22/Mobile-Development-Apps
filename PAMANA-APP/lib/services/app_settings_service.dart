import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart'; // REQUIRED FOR ValueListenable

class AppSettingsService {
  AppSettingsService._();
  static final AppSettingsService instance = AppSettingsService._();

  static const String _boxName = 'settings_box';
  static const String _themeKey = 'theme_mode';
  static const String _dailyLoreKey = 'daily_lore_enabled';
  static const String _bgmKey = 'bgm_enabled';

  late Box _box;

  /// Global initialization called exactly once inside main.dart
  static Future<void> initialize() async {
    instance._box = await Hive.openBox(_boxName);
  }

  /// Exposes the underlying box listener directly to the ValueListenableBuilder in main.dart
  ValueListenable<Box> listenable() {
    return _box.listenable();
  }

  /// Resolves stored string back into standard Flutter ThemeMode tokens
  ThemeMode get themeMode {
    final modeString = _box.get(_themeKey, defaultValue: 'system');
    switch (modeString) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  /// Dynamically reads the updated value directly from the notified box instance stream event
  ThemeMode themeModeFromBox(Box box) {
    final modeString = box.get(_themeKey, defaultValue: 'system');
    switch (modeString) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  /// Persists selected theme mode string token safely to disk
  Future<void> setThemeMode(ThemeMode mode) async {
    String modeString;
    switch (mode) {
      case ThemeMode.light:
        modeString = 'light';
        break;
      case ThemeMode.dark:
        modeString = 'dark';
        break;
      default:
        modeString = 'system';
    }
    await _box.put(_themeKey, modeString);
  }

  /// Check whether the Daily Lore popup dialog configuration is active
  bool get dailyLoreEnabled => _box.get(_dailyLoreKey, defaultValue: true);

  /// Update disk storage for daily popups
  Future<void> setDailyLoreEnabled(bool value) async {
    await _box.put(_dailyLoreKey, value);
  }

  /// Check whether the global eerie environment soundtrack is enabled
  bool get bgmEnabled => _box.get(_bgmKey, defaultValue: true);

  /// Persist the user's background ambient track preference
  Future<void> setBgmEnabled(bool value) async {
    await _box.put(_bgmKey, value);
  }
}