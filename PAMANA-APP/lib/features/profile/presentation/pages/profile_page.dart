import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../services/user_progress_service.dart';
import '../../../../services/folklore_creature_service.dart';
import '../../../settings/presentation/pages/settings_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  String _fmtDuration(int ms) {
    final d = Duration(milliseconds: ms);
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    if (h > 0) return '${h}h ${m}m';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final progress = UserProgressService.instance;
    final folService = FolkloreCreatureService.instance;

    // Lore completion
    final total = folService.getAll().length;
    final discoveredIds = progress.discoveredIds();
    final discoveredCount = discoveredIds.length;
    final completion = total == 0 ? 0.0 : discoveredCount / total;

    // Region breakdown (using helper on service)
    int luzon = 0, visayas = 0, mindanao = 0, unknown = 0;
    for (final id in discoveredIds) {
      final r = folService.regionForId(id);
      switch (r) {
        case 'Luzon':
          luzon++; break;
        case 'Visayas':
          visayas++; break;
        case 'Mindanao':
          mindanao++; break;
        default:
          unknown++; break;
      }
    }
    final pieSections = <PieChartSectionData>[
      if (luzon > 0)
        PieChartSectionData(value: luzon.toDouble(), color: cs.primary, title: 'Luzon'),
      if (visayas > 0)
        PieChartSectionData(value: visayas.toDouble(), color: cs.tertiary, title: 'Visayas'),
      if (mindanao > 0)
        PieChartSectionData(value: mindanao.toDouble(), color: cs.secondary, title: 'Mindanao'),
      if (luzon + visayas + mindanao == 0)
        PieChartSectionData(value: 1, color: cs.outlineVariant, title: 'None'),
    ];

    // Time spent
    final totalMs = progress.getTimeMs(source: 'total');
    final modelMs = progress.getTimeMs(source: 'model_viewer');
    final arMs = progress.getTimeMs(source: 'ar_viewer');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Explorer Profile'),
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Completion card
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Lore Completion', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(value: completion, minHeight: 12),
                    ),
                    const SizedBox(height: 8),
                    Text('$discoveredCount of $total discovered'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Region breakdown
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Learning by Region', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 220,
                      child: PieChart(
                        PieChartData(
                          sections: pieSections,
                          sectionsSpace: 2,
                          centerSpaceRadius: 32,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        _LegendDot(color: cs.primary, label: 'Luzon ($luzon)'),
                        _LegendDot(color: cs.tertiary, label: 'Visayas ($visayas)'),
                        _LegendDot(color: cs.secondary, label: 'Mindanao ($mindanao)'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Time spent
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Time Spent Learning', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.schedule),
                      title: const Text('Total'),
                      trailing: Text(_fmtDuration(totalMs)),
                    ),
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.threed_rotation),
                      title: const Text('3D Viewer'),
                      trailing: Text(_fmtDuration(modelMs)),
                    ),
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.view_in_ar),
                      title: const Text('AR Viewer'),
                      trailing: Text(_fmtDuration(arMs)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Badges gallery
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Badges', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    StreamBuilder<Set<String>>(
                      stream: UserProgressService.instance.watchBadges(),
                      initialData: UserProgressService.instance.allBadges(),
                      builder: (context, snap) {
                        final unlocked = snap.data ?? const <String>{};
                        return LayoutBuilder(
                          builder: (context, constraints) {
                            final width = constraints.maxWidth;
                            // Use 2 columns on narrow phones to avoid vertical overflow
                            final cols = width < 400 ? 2 : 3;
                            final ratio = width < 400 ? 0.9 : 0.82;
                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: cols,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: ratio,
                              ),
                              itemCount: _badgeCatalog.length,
                              itemBuilder: (context, index) {
                                final meta = _badgeCatalog[index];
                                final isUnlocked = unlocked.contains(meta.id);
                                return _BadgeTile(meta: meta, unlocked: isUnlocked);
                              },
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }
}

// ---------------- Badges Catalog & Tiles ----------------
class _BadgeMeta {
  final String id;
  final String title;
  final String requirement;
  final IconData icon;
  final Color color;
  const _BadgeMeta({
    required this.id,
    required this.title,
    required this.requirement,
    required this.icon,
    required this.color,
  });
}

// Match the IDs used in QuizPage: 'quiz_perfect_${module.toLowerCase()}'
final List<_BadgeMeta> _badgeCatalog = [
  _BadgeMeta(
    id: 'quiz_perfect_luzon',
    title: 'Luzon Laureate',
    requirement: 'Get a perfect score on the Luzon quiz.',
    icon: Icons.landscape_rounded,
    color: const Color(0xFF3F7D20),
  ),
  _BadgeMeta(
    id: 'quiz_perfect_visayas',
    title: 'Visayan Mythologist',
    requirement: 'Get a perfect score on the Visayas quiz.',
    icon: Icons.waves_rounded,
    color: const Color(0xFF0A84FF),
  ),
  _BadgeMeta(
    id: 'quiz_perfect_mindanao',
    title: 'Mindanao Sage',
    requirement: 'Get a perfect score on the Mindanao quiz.',
    icon: Icons.terrain_rounded,
    color: const Color(0xFF8E2DE2),
  ),
  _BadgeMeta(
    id: 'quiz_perfect_aswang',
    title: 'Aswang A+',
    requirement: 'Perfect the Aswang category quiz.',
    icon: Icons.nightlight_round,
    color: const Color(0xFFB00020),
  ),
  _BadgeMeta(
    id: 'quiz_perfect_deity',
    title: 'Divine Scholar',
    requirement: 'Perfect the Deity category quiz.',
    icon: Icons.auto_awesome,
    color: const Color(0xFFFFC107),
  ),
];

class _BadgeTile extends StatelessWidget {
  final _BadgeMeta meta;
  final bool unlocked;
  const _BadgeTile({required this.meta, required this.unlocked});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = unlocked
        ? LinearGradient(colors: [meta.color.withOpacity(0.85), meta.color.withOpacity(0.55)])
        : LinearGradient(colors: [cs.surfaceVariant, cs.surface]);
    final boxShadow = unlocked
        ? [
            BoxShadow(
              color: meta.color.withOpacity(0.35),
              blurRadius: 18,
              spreadRadius: 1,
            ),
          ]
        : [
            BoxShadow(
              color: cs.shadow.withOpacity(0.06),
              blurRadius: 8,
            ),
          ];
    final iconColor = unlocked ? Colors.white : cs.onSurfaceVariant;
    final titleStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
          color: unlocked ? Colors.white : cs.onSurface,
          fontWeight: FontWeight.w700,
        );
    final reqStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: unlocked ? Colors.white70 : cs.onSurfaceVariant,
        );

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: bg,
        boxShadow: boxShadow,
        border: Border.all(
          color: unlocked ? Colors.white.withOpacity(0.2) : cs.outlineVariant,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // prevent forcing extra height
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(meta.icon, color: iconColor, size: 28),
          const SizedBox(height: 6),
          Flexible(
            child: Text(
              meta.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: titleStyle,
            ),
          ),
          const SizedBox(height: 4),
          Flexible(
            child: Text(
              meta.requirement,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: reqStyle,
            ),
          ),
        ],
      ),
    );
  }
}
