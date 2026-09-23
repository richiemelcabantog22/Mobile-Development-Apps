import 'package:hive/hive.dart';

@HiveType(typeId: 3)
class SettingsModel extends HiveObject {
  @HiveField(0)
  double eyeClosedThreshold;

  @HiveField(1)
  int eyeClosedDurationMs;

  @HiveField(2)
  double headTiltThresholdDeg;

  @HiveField(3)
  double yawnThreshold;

  SettingsModel({
    required this.eyeClosedThreshold,
    required this.eyeClosedDurationMs,
    required this.headTiltThresholdDeg,
    required this.yawnThreshold,
  });

  factory SettingsModel.defaults() => SettingsModel(
        eyeClosedThreshold: 0.35,
        eyeClosedDurationMs: 1500,
        headTiltThresholdDeg: 45,
        yawnThreshold: 0.10,
      );
}

class SettingsModelAdapter extends TypeAdapter<SettingsModel> {
  @override
  final int typeId = 3;

  @override
  SettingsModel read(BinaryReader reader) {
    return SettingsModel(
      eyeClosedThreshold: reader.readDouble(),
      eyeClosedDurationMs: reader.readInt(),
      headTiltThresholdDeg: reader.readDouble(),
      yawnThreshold: reader.readDouble(),
    );
  }

  @override
  void write(BinaryWriter writer, SettingsModel obj) {
    writer.writeDouble(obj.eyeClosedThreshold);
    writer.writeInt(obj.eyeClosedDurationMs);
    writer.writeDouble(obj.headTiltThresholdDeg);
    writer.writeDouble(obj.yawnThreshold);
  }
}