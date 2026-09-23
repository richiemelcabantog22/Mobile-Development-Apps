import 'package:hive/hive.dart';

@HiveType(typeId: 1)
class DrowsinessRecord extends HiveObject {
  @HiveField(0)
  DateTime timestamp;

  @HiveField(1)
  String type; // 'Drowsy' | 'HeadTilt' | 'Fatigue'

  @HiveField(2)
  String message;

  @HiveField(3)
  double? headAngle;

  @HiveField(4)
  int? blinkCount;

  DrowsinessRecord({
    required this.timestamp,
    required this.type,
    required this.message,
    this.headAngle,
    this.blinkCount,
  });
}

// Manual adapter (no build_runner needed)
class DrowsinessRecordAdapter extends TypeAdapter<DrowsinessRecord> {
  @override
  final int typeId = 1;

  @override
  DrowsinessRecord read(BinaryReader reader) {
    return DrowsinessRecord(
      timestamp: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      type: reader.readString(),
      message: reader.readString(),
      headAngle: reader.readBool() ? reader.readDouble() : null,
      blinkCount: reader.readBool() ? reader.readInt() : null,
    );
  }

  @override
  void write(BinaryWriter writer, DrowsinessRecord obj) {
    writer.writeInt(obj.timestamp.millisecondsSinceEpoch);
    writer.writeString(obj.type);
    writer.writeString(obj.message);
    if (obj.headAngle != null) {
      writer.writeBool(true);
      writer.writeDouble(obj.headAngle!);
    } else {
      writer.writeBool(false);
    }
    if (obj.blinkCount != null) {
      writer.writeBool(true);
      writer.writeInt(obj.blinkCount!);
    } else {
      writer.writeBool(false);
    }
  }
}