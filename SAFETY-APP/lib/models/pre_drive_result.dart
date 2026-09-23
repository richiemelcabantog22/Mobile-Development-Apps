import 'package:hive/hive.dart';

@HiveType(typeId: 4)
class PreDriveResult extends HiveObject {
  @HiveField(0)
  DateTime timestamp;

  @HiveField(1)
  int rounds; // reaction test rounds

  @HiveField(2)
  int avgReactionMs;

  @HiveField(3)
  bool checklistMountOk;

  @HiveField(4)
  bool checklistSeatOk;

  @HiveField(5)
  bool checklistMirrorsOk;

  @HiveField(6)
  bool checklistCabinOk;

  @HiveField(7)
  int skippedSteps;

  @HiveField(8)
  int? ambientLevelY; // 0-255 average Y (brightness)

  @HiveField(9)
  int batteryLevel; // 0-100

  PreDriveResult({
    required this.timestamp,
    required this.rounds,
    required this.avgReactionMs,
    required this.checklistMountOk,
    required this.checklistSeatOk,
    required this.checklistMirrorsOk,
    required this.checklistCabinOk,
    required this.skippedSteps,
    required this.batteryLevel,
    this.ambientLevelY,
  });
}

class PreDriveResultAdapter extends TypeAdapter<PreDriveResult> {
  @override
  final int typeId = 4;

  @override
  PreDriveResult read(BinaryReader reader) {
    return PreDriveResult(
      timestamp: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      rounds: reader.readInt(),
      avgReactionMs: reader.readInt(),
      checklistMountOk: reader.readBool(),
      checklistSeatOk: reader.readBool(),
      checklistMirrorsOk: reader.readBool(),
      checklistCabinOk: reader.readBool(),
      skippedSteps: reader.readInt(),
      batteryLevel: reader.readInt(),
      ambientLevelY: reader.readBool() ? reader.readInt() : null,
    );
  }

  @override
  void write(BinaryWriter writer, PreDriveResult obj) {
    writer.writeInt(obj.timestamp.millisecondsSinceEpoch);
    writer.writeInt(obj.rounds);
    writer.writeInt(obj.avgReactionMs);
    writer.writeBool(obj.checklistMountOk);
    writer.writeBool(obj.checklistSeatOk);
    writer.writeBool(obj.checklistMirrorsOk);
    writer.writeBool(obj.checklistCabinOk);
    writer.writeInt(obj.skippedSteps);
    writer.writeInt(obj.batteryLevel);
    if (obj.ambientLevelY != null) {
      writer.writeBool(true);
      writer.writeInt(obj.ambientLevelY!);
    } else {
      writer.writeBool(false);
    }
  }
}
