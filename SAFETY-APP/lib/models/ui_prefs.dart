import 'package:hive/hive.dart';

@HiveType(typeId: 5)
class UiPrefs extends HiveObject {
  // 0: system, 1: light, 2: dark
  @HiveField(0)
  int themeModeIndex;

  // 'purple' | 'cyan' | 'amber'
  @HiveField(1)
  String accentName;

  // 0.9 .. 1.3 typical
  @HiveField(2)
  double textScale;

  UiPrefs({
    required this.themeModeIndex,
    required this.accentName,
    required this.textScale,
  });

  factory UiPrefs.defaults() => UiPrefs(
        themeModeIndex: 2, // default dark
        accentName: 'purple',
        textScale: 1.0,
      );
}

class UiPrefsAdapter extends TypeAdapter<UiPrefs> {
  @override
  final int typeId = 5;

  @override
  UiPrefs read(BinaryReader reader) {
    return UiPrefs(
      themeModeIndex: reader.readInt(),
      accentName: reader.readString(),
      textScale: reader.readDouble(),
    );
  }

  @override
  void write(BinaryWriter writer, UiPrefs obj) {
    writer.writeInt(obj.themeModeIndex);
    writer.writeString(obj.accentName);
    writer.writeDouble(obj.textScale);
  }
}
