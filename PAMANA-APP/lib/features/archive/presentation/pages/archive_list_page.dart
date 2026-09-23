import 'package:flutter/material.dart';
import '../../../../models/folklore_creature.dart';
import '../../domain/folklore_repository.dart';
import '../viewmodels/archive_list_viewmodel.dart';
import 'archive_detail_page.dart';

class ArchiveListPage extends StatefulWidget {
  const ArchiveListPage({super.key});

  @override
  State<ArchiveListPage> createState() => _ArchiveListPageState();
}

class _ArchiveListPageState extends State<ArchiveListPage> {
  late final ArchiveListViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = ArchiveListViewModel(repo: FolkloreRepository());
    _vm.start();
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PAMANA Archive'),
      ),
      body: RefreshIndicator(
        onRefresh: _vm.refresh,
        child: AnimatedBuilder(
          animation: Listenable.merge([_vm.loading, _vm.creatures]),
          builder: (context, _) {
            if (_vm.loading.value) {
              return const Center(child: CircularProgressIndicator());
            }
            final items = _vm.creatures.value;
            if (items.isEmpty) {
              return const Center(child: Text('No folklore creatures yet.'));
            }
            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final FolkloreCreature c = items[index];
                return ListTile(
                  leading: CircleAvatar(
                    child: Text(c.name.isNotEmpty ? c.name[0] : '?'),
                  ),
                  title: Text(c.name),
                  subtitle: Text(
                    c.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ArchiveDetailPage(creatureId: c.id),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}