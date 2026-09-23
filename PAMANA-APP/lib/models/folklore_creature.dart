import 'package:hive/hive.dart';

class FolkloreCreature {
  final String id;
  final String name;
  final String description;
  final String imageUrl; // For the encyclopedia list
  final String modelPath; // Path to your .glb file in assets/
  final double modelScale; // uniform scale for AR/3D
  final String category; // e.g., Maligno, Aswang, Deity, Benevolent Spirits
  final String region;   // e.g., Luzon, Visayas, Mindanao
  final List<String> provinces; // e.g., ['Capiz', 'Cebu']

  FolkloreCreature({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.modelPath,
    this.modelScale = 0.2,
    this.category = 'Unknown',
    this.region = 'Unknown',
    this.provinces = const <String>[],
  });
}

// Hive TypeAdapter for FolkloreCreature (manual adapter to avoid codegen)
class FolkloreCreatureAdapter extends TypeAdapter<FolkloreCreature> {
  @override
  final int typeId = 0;

  @override
  FolkloreCreature read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FolkloreCreature(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String,
      imageUrl: fields[3] as String,
      modelPath: fields[4] as String,
      modelScale: (fields[5] as double?) ?? 0.2,
      category: (fields[6] as String?) ?? 'Unknown',
      region: (fields[7] as String?) ?? 'Unknown',
      provinces: (fields[8] as List?)?.cast<String>() ?? const <String>[],
    );
  }

  @override
  void write(BinaryWriter writer, FolkloreCreature obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.imageUrl)
      ..writeByte(4)
      ..write(obj.modelPath)
      ..writeByte(5)
      ..write(obj.modelScale)
      ..writeByte(6)
      ..write(obj.category)
      ..writeByte(7)
      ..write(obj.region)
      ..writeByte(8)
      ..write(obj.provinces);
  }
}