import 'package:hive/hive.dart';

@HiveType(typeId: 2)
class DriverModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  DriverModel({
    required this.id,
    required this.name,
  });
}

class DriverModelAdapter extends TypeAdapter<DriverModel> {
  @override
  final int typeId = 2;

  @override
  DriverModel read(BinaryReader reader) {
    return DriverModel(
      id: reader.readString(),
      name: reader.readString(),
    );
  }

  @override
  void write(BinaryWriter writer, DriverModel obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.name);
  }
}