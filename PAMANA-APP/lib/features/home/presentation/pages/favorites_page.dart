import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../models/folklore_creature.dart';
import '../../../../services/folklore_creature_service.dart';
import '../../../ar_viewer/presentation/pages/model_viewer_page.dart';
import '../../../ar_viewer/presentation/pages/ar_viewer_page.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final _service = FolkloreCreatureService.instance;

  // Keep text controllers per creature ID and debounce timers to reduce writes.
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, Timer> _debouncers = {};

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    for (final d in _debouncers.values) {
      d.cancel();
    }
    super.dispose();
  }

  void _ensureController(String id, String initial) {
    if (_controllers.containsKey(id)) return;
    final controller = TextEditingController(text: initial);
    controller.addListener(() {
      // Debounce writes to Hive (300ms)
      _debouncers[id]?.cancel();
      _debouncers[id] = Timer(const Duration(milliseconds: 300), () {
        _service.setNote(id, controller.text);
      });
    });
    _controllers[id] = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Grimoire')),
      body: StreamBuilder<List<FolkloreCreature>>(
        stream: _service.watchFavoriteCreatures(),
        initialData: _service.getFavorites(),
        builder: (context, snap) {
          final items = snap.data ?? const <FolkloreCreature>[];
          if (items.isEmpty) {
            return const Center(
              child: Text(
                'Your Grimoire is empty.\nTap the heart on a creature to add it,\nthen write your notes here.',
                textAlign: TextAlign.center,
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final c = items[index];
              final note = _service.getNote(c.id);
              _ensureController(c.id, note);

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(child: Text(c.name.isNotEmpty ? c.name[0] : '?')),
                          title: Text(c.name),
                          subtitle: Text(
                            c.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            tooltip: 'Remove from Grimoire',
                            onPressed: () => _service.toggleFavorite(c.id),
                          ),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => ModelViewerPage(creature: c)),
                            );
                          },
                          onLongPress: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => ARViewerPage(creature: c)),
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _controllers[c.id],
                          minLines: 2,
                          maxLines: 6,
                          decoration: InputDecoration(
                            labelText: 'Your notes',
                            hintText: 'Add study or research notes about ${c.name}...',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.save_alt_outlined),
                              tooltip: 'Save now',
                              onPressed: () => _service.setNote(c.id, _controllers[c.id]!.text),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}