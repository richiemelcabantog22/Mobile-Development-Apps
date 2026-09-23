import 'package:hive/hive.dart';
import '../database/hive_database.dart';
import '../models/settings_model.dart';

class SettingsService {
  static late SettingsService instance;
  static bool _initialized = false;
  static bool get isInitialized => _initialized;

  late Box<SettingsModel> _box;

  SettingsModel _current = SettingsModel.defaults();
  SettingsModel get current => _current;

  static Future<void> init() async {
    instance = SettingsService();
    instance._box = HiveDatabase.settingsBox;
    if (instance._box.isEmpty) {
      await instance._box.add(SettingsModel.defaults());
    }
    instance._current = instance._box.getAt(0) ?? SettingsModel.defaults();
    _initialized = true;
  }

  Future<void> save({
    required double eyeClosedThreshold,
    required int eyeClosedDurationMs,
    required double headTiltThresholdDeg,
    double? yawnThreshold,
  }) async {
    _current
      ..eyeClosedThreshold = eyeClosedThreshold
      ..eyeClosedDurationMs = eyeClosedDurationMs
      ..headTiltThresholdDeg = headTiltThresholdDeg
      ..yawnThreshold = yawnThreshold ?? _current.yawnThreshold;
    await _current.save();
  }
}