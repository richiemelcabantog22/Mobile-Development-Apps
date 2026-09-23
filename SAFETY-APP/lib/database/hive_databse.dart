import 'package:hive/hive.dart';
import '../core/constants.dart';
import '../models/drowsiness_record.dart';
import '../models/driver_model.dart';

class HiveDatabase {
  static Future<void> registerAdaptersAndOpen() async {
    if (!Hive.isAdapterRegistered(DrowsinessRecordAdapter().typeId)) {
      Hive.registerAdapter(DrowsinessRecordAdapter());
    }
    if (!Hive.isAdapterRegistered(DriverModelAdapter().typeId)) {
      Hive.registerAdapter(DriverModelAdapter());
    }
    await Hive.openBox<DrowsinessRecord>(AppConstants.historyBox);
  }

  static Box<DrowsinessRecord> get recordsBox =>
      Hive.box<DrowsinessRecord>(AppConstants.historyBox);

  static Future<void> addRecord(DrowsinessRecord record) async {
    await recordsBox.add(record);
  }
}