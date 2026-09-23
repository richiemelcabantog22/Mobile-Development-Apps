import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../models/folklore_creature.dart';
import '../../../../services/folklore_creature_service.dart';
import '../../../../services/user_progress_service.dart';
import '../../../../services/audio_governor_service.dart'; 
import '../../../ar_viewer/presentation/pages/model_viewer_page.dart';
import '../../../ar_viewer/presentation/pages/ar_viewer_page.dart';

class CreatureDetailPage extends StatefulWidget {
  final FolkloreCreature creature;
  const CreatureDetailPage({super.key, required this.creature});

  @override
  State<CreatureDetailPage> createState() => _CreatureDetailPageState(); // FIXED: Changed type argument here
}

class _CreatureDetailPageState extends State<CreatureDetailPage> {
  final _service = FolkloreCreatureService.instance;
  final _progress = UserProgressService.instance;

  final Stopwatch _readTimer = Stopwatch();
  late bool _isFavorite;
  late int _views;
  TextEditingController? _notesCtrl;
  Timer? _debounce;
  bool _isSpeaking = false; 

  @override
  void initState() {
    super.initState();
    _progress.markDiscovered(widget.creature.id);
    _readTimer.start();

    _progress.incrementCounter('views:${widget.creature.id}').then((v) {
      if (mounted) setState(() => _views = v);
    });
    _views = _progress.getCounter('views:${widget.creature.id}');

    _isFavorite = _service.isFavorite(widget.creature.id);
    final note = _service.getNote(widget.creature.id);
    _notesCtrl = TextEditingController(text: note)
      ..addListener(() {
        _debounce?.cancel();
        _debounce = Timer(const Duration(milliseconds: 300), () {
          _service.setNote(widget.creature.id, _notesCtrl!.text);
          if (!_isFavorite) {
            _service.toggleFavorite(widget.creature.id);
            setState(() => _isFavorite = true);
          }
        });
      });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _notesCtrl?.dispose();
    _readTimer.stop();
    _progress.addLearningTime(_readTimer.elapsed, source: 'detail_page');
    AudioGovernorService.instance.stopNarration();
    super.dispose();
  }

  void _toggleFavorite() async {
    await _service.toggleFavorite(widget.creature.id);
    setState(() => _isFavorite = !_isFavorite);
  }

  void _toggleNarration() async {
    if (_isSpeaking) {
      await AudioGovernorService.instance.stopNarration();
      if (mounted) setState(() => _isSpeaking = false);
    } else {
      if (mounted) setState(() => _isSpeaking = true);
      await AudioGovernorService.instance.speakNarration(widget.creature.description);
      
      Timer.periodic(const Duration(milliseconds: 500), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        if (!AudioGovernorService.instance.isNarrationPlaying) {
          setState(() => _isSpeaking = false);
          timer.cancel();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.creature;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(c.name),
        actions: [
          IconButton(
            tooltip: _isFavorite ? 'Remove from Grimoire' : 'Add to Grimoire',
            onPressed: _toggleFavorite,
            icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: c.imageUrl.isNotEmpty
                    ? Image.asset(
                        c.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _ImageFallback(initial: c.name.isNotEmpty ? c.name[0] : '?'),
                      )
                    : _ImageFallback(initial: c.name.isNotEmpty ? c.name[0] : '?'),
              ),
            ),
            const SizedBox(height: 12),

            Text(
              c.name,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MetaChip(icon: Icons.category_outlined, label: c.category),
                _MetaChip(icon: Icons.public, label: c.region),
                if (c.provinces.isNotEmpty)
                  _MetaChip(icon: Icons.location_on_outlined, label: c.provinces.join(', ')),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => ModelViewerPage(creature: c)));
                    },
                    icon: const Icon(Icons.threed_rotation),
                    label: const Text('View 3D'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => ARViewerPage(creature: c)));
                    },
                    icon: const Icon(Icons.view_in_ar),
                    label: const Text('Try AR'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _SectionTitle(title: 'Lore'),
                IconButton.filledTonal(
                  icon: Icon(_isSpeaking ? Icons.volume_up : Icons.volume_mute_outlined),
                  tooltip: _isSpeaking ? 'Stop Narration' : 'Listen to Legend',
                  onPressed: _toggleNarration,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              c.description,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.4),
            ),
            const SizedBox(height: 16),

            _SectionTitle(title: 'Cultural Origins'),
            const SizedBox(height: 4),
            Text(
              '${c.region}${c.provinces.isNotEmpty ? ' • ${c.provinces.join(", ")}' : ''}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 16),

            _SectionTitle(title: 'Your Study Stats'),
            const SizedBox(height: 6),
            Row(
              children: [
                _StatTile(icon: Icons.visibility_outlined, label: 'Inspected', value: '$_views×'),
                const SizedBox(width: 12),
                _StatTile(
                  icon: Icons.task_alt_outlined,
                  label: 'Discovered',
                  value: UserProgressService.instance.isDiscovered(c.id) ? 'Yes' : 'No',
                ),
              ],
            ),
            const SizedBox(height: 16),

            _SectionTitle(title: 'Your Notes'),
            const SizedBox(height: 6),
            TextField(
              controller: _notesCtrl,
              minLines: 3,
              maxLines: 10,
              decoration: InputDecoration(
                hintText: 'Write your study or research notes about ${c.name}…',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                suffixIcon: const Icon(Icons.notes),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label, overflow: TextOverflow.ellipsis),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700));
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _StatTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cs.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: cs.primary),
            const SizedBox(width: 8),
            Expanded(child: Text(label, overflow: TextOverflow.ellipsis)),
            Text(value, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  final String initial;
  const _ImageFallback({required this.initial});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      color: cs.surfaceVariant,
      alignment: Alignment.center,
      child: Text(
        initial,
        style: Theme.of(context).textTheme.displayLarge?.copyWith(color: cs.primary, fontWeight: FontWeight.w800),
      ),
    );
  }
}