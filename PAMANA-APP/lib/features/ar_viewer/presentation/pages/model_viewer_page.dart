import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import '../../../../models/folklore_creature.dart';
import '../../../../services/user_progress_service.dart';
import '../../../archive/presentation/pages/creature_detail_page.dart';

class ModelViewerPage extends StatefulWidget {
  final FolkloreCreature creature;
  const ModelViewerPage({super.key, required this.creature});

  @override
  State<ModelViewerPage> createState() => _ModelViewerPageState();
}

class _ModelViewerPageState extends State<ModelViewerPage> {
  final Stopwatch _sw = Stopwatch();
  bool _showInfo = true;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    // Mark discovered and start learning timer
    UserProgressService.instance.markDiscovered(widget.creature.id);
    _sw.start();
  }

  @override
  void dispose() {
    _sw.stop();
    UserProgressService.instance
        .addLearningTime(_sw.elapsed, source: 'model_viewer');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final maxPanelHeight = MediaQuery.of(context).size.height * 0.42;
    final collapsedHeight = 88.0; // slightly smaller to avoid edge overflow

    return Scaffold(
      appBar: AppBar(
        title: Text('3D: ${widget.creature.name}'),
        actions: [
          IconButton(
            tooltip: _showInfo ? 'Hide info' : 'Show info',
            icon: Icon(_showInfo ? Icons.info_outline : Icons.info),
            onPressed: () => setState(() => _showInfo = !_showInfo),
          ),
          IconButton(
            tooltip: 'Read More',
            icon: const Icon(Icons.subject),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => CreatureDetailPage(creature: widget.creature)),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // 3D model
          Positioned.fill(
            child: ModelViewer(
              src: widget.creature.modelPath,
              alt: '${widget.creature.name} model',
              ar: false,
              autoRotate: true,
              cameraControls: true,
              iosSrc: widget.creature.modelPath,
              backgroundColor: Colors.white,
            ),
          ),

          // Floating transparent description panel
          if (_showInfo)
            Align(
              alignment: Alignment.bottomCenter,
              child: SafeArea(
                minimum: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                  height: _expanded ? maxPanelHeight : collapsedHeight,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.black.withOpacity(0.28),
                    border: Border.all(color: Colors.white.withOpacity(0.12)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Blur for glass effect
                        BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: const SizedBox.expand(),
                        ),
                        // Content
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Drag handle / header row
                            GestureDetector(
                              onTap: () => setState(() => _expanded = !_expanded),
                              child: Container(
                                padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white.withOpacity(0.10),
                                      Colors.white.withOpacity(0.04),
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    // Drag handle
                                    Container(
                                      width: 36,
                                      height: 5,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.6),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        widget.creature.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ),
                                    IconButton(
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () =>
                                          setState(() => _expanded = !_expanded),
                                      icon: Icon(
                                        _expanded
                                            ? Icons.expand_less // show collapse icon when expanded
                                            : Icons.expand_more,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Description scroll area (only render when expanded to prevent overflow)
                            if (_expanded)
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                                  child: SingleChildScrollView(
                                    child: Text(
                                      widget.creature.description,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: Colors.white.withOpacity(0.95),
                                          ),
                                    ),
                                  ),
                                ),
                              ),
                            // Quick chips row (only when expanded)
                            if (_expanded)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: [
                                    _InfoChip(
                                      icon: Icons.public,
                                      label: widget.creature.region,
                                      cs: cs,
                                    ),
                                    _InfoChip(
                                      icon: Icons.category_outlined,
                                      label: widget.creature.category,
                                      cs: cs,
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final ColorScheme cs;
  const _InfoChip({required this.icon, required this.label, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}