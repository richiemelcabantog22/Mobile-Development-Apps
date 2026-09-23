import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../core/constants.dart';
import '../models/drowsiness_record.dart';
import '../models/driver_model.dart';
import '../models/settings_model.dart';
import '../models/pre_drive_result.dart';
import '../models/ui_prefs.dart';

class HiveDatabase {
  static Future<void> registerAdaptersAndOpen() async {
    await Hive.initFlutter();

    if (!Hive.isAdapterRegistered(DrowsinessRecordAdapter().typeId)) {
      Hive.registerAdapter(DrowsinessRecordAdapter());
    }
    if (!Hive.isAdapterRegistered(DriverModelAdapter().typeId)) {
      Hive.registerAdapter(DriverModelAdapter());
    }
    if (!Hive.isAdapterRegistered(SettingsModelAdapter().typeId)) {
      Hive.registerAdapter(SettingsModelAdapter());
    }
    if (!Hive.isAdapterRegistered(PreDriveResultAdapter().typeId)) {
      Hive.registerAdapter(PreDriveResultAdapter());
    }
    if (!Hive.isAdapterRegistered(UiPrefsAdapter().typeId)) {
      Hive.registerAdapter(UiPrefsAdapter());
    }

    await Hive.openBox<DrowsinessRecord>(AppConstants.historyBox);
    await Hive.openBox<SettingsModel>(AppConstants.settingsBox);
    await Hive.openBox<PreDriveResult>(AppConstants.preDriveBox);
    await Hive.openBox<UiPrefs>(AppConstants.prefsBox);
    await Hive.openBox('app_kv'); // for onboarding flag
  }

  static Box<DrowsinessRecord> get recordsBox =>
      Hive.box<DrowsinessRecord>(AppConstants.historyBox);

  // Alias to match usages expecting 'drowsinessBox'
  static Box<DrowsinessRecord> get drowsinessBox => recordsBox;

  static Box<SettingsModel> get settingsBox =>
      Hive.box<SettingsModel>(AppConstants.settingsBox);

  static Box<PreDriveResult> get preDriveBox =>
      Hive.box<PreDriveResult>(AppConstants.preDriveBox);

  static Box<UiPrefs> get prefsBox =>
      Hive.box<UiPrefs>(AppConstants.prefsBox);

  static Box get kvBox => Hive.box('app_kv');

  static Future<void> addRecord(DrowsinessRecord record) async {
    await recordsBox.add(record);
  }
}