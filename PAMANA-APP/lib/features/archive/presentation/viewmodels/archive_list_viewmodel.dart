import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../../models/folklore_creature.dart';
import '../../domain/folklore_repository.dart';

class ArchiveListViewModel {
  final FolkloreRepository _repo;

  final ValueNotifier<bool> loading = ValueNotifier<bool>(true);
  final ValueNotifier<List<FolkloreCreature>> creatures =
      ValueNotifier<List<FolkloreCreature>>(<FolkloreCreature>[]);

  StreamSubscription<List<FolkloreCreature>>? _sub;

  ArchiveListViewModel({FolkloreRepository? repo})
      : _repo = repo ?? FolkloreRepository();

  void start() {
    loading.value = true;
    _sub = _repo.watchAll().listen((data) {
      creatures.value = List.unmodifiable(data);
      loading.value = false;
    }, onError: (_) {
      loading.value = false;
    });
  }

  Future<void> refresh() async {
    // Since data is local, simulate a refresh by re-pulling current list
    final data = _repo.getAll();
    creatures.value = List.unmodifiable(data);
  }

  void dispose() {
    _sub?.cancel();
    loading.dispose();
    creatures.dispose();
  }
}