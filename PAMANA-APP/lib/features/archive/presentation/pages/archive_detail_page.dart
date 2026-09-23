import 'package:flutter/material.dart';
import '../../../../models/folklore_creature.dart';
import '../../domain/folklore_repository.dart';
import '../../../ar_viewer/presentation/pages/ar_viewer_page.dart';

class ArchiveDetailPage extends StatelessWidget {
  final String creatureId;
  const ArchiveDetailPage({super.key, required this.creatureId});

  @override
  Widget build(BuildContext context) {
    final repo = FolkloreRepository();
    final FolkloreCreature? creature = repo.getById(creatureId);

    if (creature == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Creature not found')),
        body: const Center(child: Text('The requested creature does not exist.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(creature.name)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  creature.name[0],
                  style: Theme.of(context).textTheme.displayLarge,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                creature.name,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                creature.description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ARViewerPage(creature: creature),
                      ),
                    );
                  },
                  child: const Text('View in AR'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}