import '../../../models/folklore_creature.dart';
import '../../../services/folklore_creature_service.dart';

class FolkloreRepository {
  final FolkloreCreatureService _service;

  FolkloreRepository({FolkloreCreatureService? service})
      : _service = service ?? FolkloreCreatureService.instance;

  Stream<List<FolkloreCreature>> watchAll() => _service.watchAll();

  List<FolkloreCreature> getAll() => _service.getAll();

  FolkloreCreature? getById(String id) => _service.getById(id);

  Future<void> upsert(FolkloreCreature creature) => _service.upsertCreature(creature);

  Future<void> delete(String id) => _service.deleteCreature(id);

  Future<void> clear() => _service.clear();
}