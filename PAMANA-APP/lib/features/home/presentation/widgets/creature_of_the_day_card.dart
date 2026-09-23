import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../../../../models/folklore_creature.dart';
import '../../../ar_viewer/presentation/pages/ar_viewer_page.dart';
import '../../../ar_viewer/presentation/pages/model_viewer_page.dart';

class CreatureOfTheDayCard extends StatefulWidget {
  final FolkloreCreature creature;
  const CreatureOfTheDayCard({super.key, required this.creature});

  @override
  State<CreatureOfTheDayCard> createState() => _CreatureOfTheDayCardState();
}

class _CreatureOfTheDayCardState extends State<CreatureOfTheDayCard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowDailyLore());
  }

  Future<void> _maybeShowDailyLore() async {
    const boxName = 'user_progress_box';
    // Ensure box is available (UserProgressService.initialize() opens this in main.dart)
    final box = Hive.isBoxOpen(boxName)
        ? Hive.box<dynamic>(boxName)
        : await Hive.openBox<dynamic>(boxName);

    final String today =
        DateTime.now().toIso8601String().substring(0, 10); // YYYY-MM-DD
    final String lastShown = (box.get('daily:last_shown') as String?) ?? '';
    if (lastShown == today) return; // Already shown today

    if (!mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        final cs = Theme.of(context).colorScheme;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          contentPadding: EdgeInsets.zero,
          content: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [cs.primaryContainer, cs.primary.withOpacity(0.85)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        'Daily Lore',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.creature.name,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    // Micro-learning: quick trivia derived from description (you can replace with curated facts)
                    widget.creature.description.length > 160
                        ? '${widget.creature.description.substring(0, 160)}…'
                        : widget.creature.description,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.tonal(
                          onPressed: () {
                            Navigator.of(context).pop();
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ModelViewerPage(creature: widget.creature),
                              ),
                            );
                          },
                          child: const Text('View 3D'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ARViewerPage(creature: widget.creature),
                            ),
                          );
                        },
                        tooltip: 'Try AR',
                        icon: const Icon(Icons.view_in_ar),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    // Mark shown for today
    await box.put('daily:last_shown', today);
  }

  void _openImagePreview() {
    final path = widget.creature.imageUrl;
    if (path.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No image available for this creature')),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          contentPadding: const EdgeInsets.all(8),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 3.0,
                child: Image.asset(
                  path,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, err, stack) {
                    return Container(
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(16),
                      child: const Text('Image not found in assets'),
                    );
                  },
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            FilledButton.tonal(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => ModelViewerPage(creature: widget.creature)),
                );
              },
              child: const Text('View 3D'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => ARViewerPage(creature: widget.creature)),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [cs.primaryContainer, cs.primary.withOpacity(0.85)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              // Image avatar with clickable preview
              InkWell(
                onTap: _openImagePreview,
                borderRadius: BorderRadius.circular(48),
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: cs.primary.withOpacity(0.2),
                      child: ClipOval(
                        child: widget.creature.imageUrl.isNotEmpty
                            ? Image.asset(
                                widget.creature.imageUrl,
                                width: 96,
                                height: 96,
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, err, stack) {
                                  return Center(
                                    child: Text(
                                      widget.creature.name.isNotEmpty ? widget.creature.name[0] : '?',
                                      style: Theme.of(context)
                                          .textTheme
                                          .displayMedium
                                          ?.copyWith(color: cs.primary),
                                    ),
                                  );
                                },
                              )
                            : Center(
                                child: Text(
                                  widget.creature.name.isNotEmpty ? widget.creature.name[0] : '?',
                                  style: Theme.of(context)
                                      .textTheme
                                      .displayMedium
                                      ?.copyWith(color: cs.primary),
                                ),
                              ),
                      ),
                    ),
                    // Small picture icon hint
                    Container(
                      margin: const EdgeInsets.only(bottom: 4, right: 4),
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.photo, size: 16, color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Creature of the Day',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: cs.onPrimaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.creature.name,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: cs.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.creature.description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: cs.onPrimaryContainer.withOpacity(0.9),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
