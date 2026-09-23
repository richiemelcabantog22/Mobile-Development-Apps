import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart'; // for Box.listenable()
import 'package:flutter/services.dart';
import '../database/hive_database.dart';
import '../models/drowsiness_record.dart';
import '../models/pre_drive_result.dart';
import '../widgets/neon_panel.dart'; // ADD

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with SingleTickerProviderStateMixin {
  late final TabController _tab;
  String _eventFilter = 'All'; // All, Drowsy, HeadTilt, Dizziness, Fatigue, Yawn
  DateTimeRange? _range;
  String _quickRange = 'All'; // All, Today, 7d, 30d

  Future<void> _onSnooze() async {
    // No-op here; method exists only to avoid unresolved references if you added a snooze action accidentally.
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Snooze not available on History screen')),
    );
  }

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  bool _inRange(DateTime t) {
    if (_range == null) return true;
    return (t.isAfter(_range!.start) || t.isAtSameMomentAs(_range!.start)) &&
        (t.isBefore(_range!.end) || t.isAtSameMomentAs(_range!.end));
  }

  DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

  void _applyQuickRange(String label) {
    setState(() {
      _quickRange = label;
      final now = DateTime.now();
      if (label == 'All') {
        _range = null;
      } else if (label == 'Today') {
        final start = _startOfDay(now);
        _range = DateTimeRange(start: start, end: now);
      } else if (label == '7d') {
        final start = _startOfDay(now.subtract(const Duration(days: 7)));
        _range = DateTimeRange(start: start, end: now);
      } else if (label == '30d') {
        final start = _startOfDay(now.subtract(const Duration(days: 30)));
        _range = DateTimeRange(start: start, end: now);
      }
    });
  }

  Future<void> _confirmClearEvents(Box<DrowsinessRecord> box) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear all events?'),
        content: const Text('This will permanently delete all drowsiness/tilt events.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Clear')),
        ],
      ),
    );
    if (ok == true) {
      await box.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Events cleared')));
    }
  }

  Future<void> _confirmClearPreDrive(Box<PreDriveResult> box) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear all pre-drive records?'),
        content: const Text('This will permanently delete all wake-up routine summaries.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Clear')),
        ],
      ),
    );
    if (ok == true) {
      await box.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pre-drive records cleared')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final Box<DrowsinessRecord> eventsBox = HiveDatabase.drowsinessBox;
    final Box<PreDriveResult> preDriveBox = HiveDatabase.preDriveBox;

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: 'Events'),
            Tab(text: 'Pre-drive'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Filter dates',
            icon: const Icon(Icons.filter_alt_outlined),
            onPressed: () async {
              final now = DateTime.now();
              final selected = await showDateRangePicker(
                context: context,
                firstDate: now.subtract(const Duration(days: 365)),
                lastDate: now,
                initialDateRange: _range,
              );
              if (selected != null) setState(() {
                _quickRange = 'Custom';
                _range = selected;
              });
            },
          ),
          if (_range != null)
            IconButton(
              tooltip: 'Clear date filter',
              icon: const Icon(Icons.clear),
              onPressed: () => setState(() {
                _quickRange = 'All';
                _range = null;
              }),
            ),
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'clear_events') {
                await _confirmClearEvents(eventsBox);
              } else if (v == 'clear_pre') {
                await _confirmClearPreDrive(preDriveBox);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'clear_events', child: Text('Clear all Events')),
              PopupMenuItem(value: 'clear_pre', child: Text('Clear all Pre-drive')),
            ],
          ),
        ],
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          // Events
          ValueListenableBuilder<Box<DrowsinessRecord>>(
            valueListenable: eventsBox.listenable(),
            builder: (context, box, _) {
              final all = box.values
                  .where((r) => _inRange(r.timestamp))
                  .where((r) => _eventFilter == 'All' ? true : r.type == _eventFilter)
                  .toList()
                ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

              // Aggregates: counts per type, busiest hour
              final Map<String, int> typeCounts = {
                'Drowsy': 0, 'HeadTilt': 0, 'Dizziness': 0, 'Fatigue': 0, 'Yawn': 0,
              };
              final Map<int, int> perHour = {};
              for (final r in all) {
                if (typeCounts.containsKey(r.type)) {
                  typeCounts[r.type] = (typeCounts[r.type] ?? 0) + 1;
                }
                perHour[r.timestamp.hour] = (perHour[r.timestamp.hour] ?? 0) + 1;
              }
              int busiestHour = -1, bestCount = 0;
              perHour.forEach((h, c) {
                if (c > bestCount) { bestCount = c; busiestHour = h; }
              });

              // Quick range chips and type filter
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Wrap(
                      spacing: 8,
                      children: [
                        _chip('All'),
                        _chip('Drowsy'),
                        _chip('HeadTilt'),
                        _chip('Dizziness'),
                        _chip('Fatigue'),
                        _chip('Yawn'),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('All'),
                          selected: _quickRange == 'All',
                          onSelected: (_) => _applyQuickRange('All'),
                        ),
                        ChoiceChip(
                          label: const Text('Today'),
                          selected: _quickRange == 'Today',
                          onSelected: (_) => _applyQuickRange('Today'),
                        ),
                        ChoiceChip(
                          label: const Text('7d'),
                          selected: _quickRange == '7d',
                          onSelected: (_) => _applyQuickRange('7d'),
                        ),
                        ChoiceChip(
                          label: const Text('30d'),
                          selected: _quickRange == '30d',
                          onSelected: (_) => _applyQuickRange('30d'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Aggregates card
                  NeonPanel(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Summary', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.6)),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 12,
                            runSpacing: 6,
                            children: [
                              Text('Total: ${all.length}'),
                              Text('Drowsy: ${typeCounts['Drowsy']}'),
                              Text('HeadTilt: ${typeCounts['HeadTilt']}'),
                              Text('Dizziness: ${typeCounts['Dizziness']}'),
                              Text('Fatigue: ${typeCounts['Fatigue']}'),
                              Text('Yawn: ${typeCounts['Yawn']}'),
                              if (busiestHour >= 0) Text('Busiest hour: ${busiestHour.toString().padLeft(2, '0')}:00'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: _GroupedEventList(records: all),
                  ),
                ],
              );
            },
          ),
          // Pre-drive
          ValueListenableBuilder<Box<PreDriveResult>>(
            valueListenable: preDriveBox.listenable(),
            builder: (context, box, _) {
              final items = box.values
                  .where((r) => _inRange(r.timestamp))
                  .toList()
                ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
              final avgMs = items.isEmpty
                  ? 0
                  : items.map((e) => e.avgReactionMs).reduce((a, b) => a + b) ~/ items.length;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('All'),
                          selected: _quickRange == 'All',
                          onSelected: (_) => _applyQuickRange('All'),
                        ),
                        ChoiceChip(
                          label: const Text('Today'),
                          selected: _quickRange == 'Today',
                          onSelected: (_) => _applyQuickRange('Today'),
                        ),
                        ChoiceChip(
                          label: const Text('7d'),
                          selected: _quickRange == '7d',
                          onSelected: (_) => _applyQuickRange('7d'),
                        ),
                        ChoiceChip(
                          label: const Text('30d'),
                          selected: _quickRange == '30d',
                          onSelected: (_) => _applyQuickRange('30d'),
                        ),
                      ],
                    ),
                  ),
                  Card(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 6,
                        children: [
                          Text('Records: ${items.length}'),
                          Text('Avg reaction: ${avgMs} ms'),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final r = items[i];
                        final date = '${r.timestamp.year}-${r.timestamp.month.toString().padLeft(2, '0')}-${r.timestamp.day.toString().padLeft(2, '0')}';
                        return Dismissible(
                          key: ValueKey('pre_${r.key}_${r.timestamp.millisecondsSinceEpoch}'),
                          background: Container(color: Colors.redAccent.withOpacity(0.8)),
                          onDismissed: (_) async {
                            await r.delete();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pre-drive record deleted')));
                            }
                          },
                          child: ListTile(
                            leading: const Icon(Icons.directions_car, color: Colors.limeAccent),
                            title: Text('Pre-drive on $date'),
                            subtitle: Text('Avg reaction: ${r.avgReactionMs} ms • Battery: ${r.batteryLevel}% • AmbientY: ${r.ambientLevelY ?? '-'}'),
                            trailing: Icon(Icons.checklist, color: (r.checklistMountOk && r.checklistSeatOk && r.checklistMirrorsOk && r.checklistCabinOk) ? Colors.greenAccent : Colors.orangeAccent),
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text('Checklist'),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Phone mounted: ${r.checklistMountOk ? 'Yes' : 'No'}'),
                                      Text('Seat adjusted: ${r.checklistSeatOk ? 'Yes' : 'No'}'),
                                      Text('Mirrors aligned: ${r.checklistMirrorsOk ? 'Yes' : 'No'}'),
                                      Text('Cabin comfortable: ${r.checklistCabinOk ? 'Yes' : 'No'}'),
                                      const SizedBox(height: 8),
                                      Text('Rounds: ${r.rounds}'),
                                      Text('Avg reaction: ${r.avgReactionMs} ms'),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _chip(String label) {
    final sel = _eventFilter == label;
    return ChoiceChip(
      label: Text(label),
      selected: sel,
      onSelected: (_) => setState(() => _eventFilter = label),
    );
  }
}

// Grouped-by-day event list with swipe-to-delete
class _GroupedEventList extends StatelessWidget {
  final List<DrowsinessRecord> records;
  const _GroupedEventList({required this.records});

  String _dayKey(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    // Group by day
    final Map<String, List<DrowsinessRecord>> groups = {};
    for (final r in records) {
      final k = _dayKey(r.timestamp);
      (groups[k] ??= []).add(r);
    }
    final dayKeys = groups.keys.toList()
      ..sort((a, b) => b.compareTo(a)); // newest day first

    final List<Widget> children = [];
    for (final day in dayKeys) {
      final parts = day.split('-');
      final label = '${parts[0]}-${parts[1]}-${parts[2]}';
      children.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: NeonPanel(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
            ),
          ),
        ),
      );
      final list = groups[day]!;
      for (final r in list) {
        final ts = TimeOfDay.fromDateTime(r.timestamp).format(context);
        children.add(
          Dismissible(
            key: ValueKey('ev_${r.key}_${r.timestamp.millisecondsSinceEpoch}'),
            background: Container(color: Colors.redAccent.withOpacity(0.8)),
            onDismissed: (_) async {
              await r.delete();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Event deleted')));
            },
            child: ListTile(
              leading: Icon(
                r.type == 'Drowsy'
                    ? Icons.bedtime
                    : (r.type == 'HeadTilt' ? Icons.screen_rotation : Icons.monitor_heart),
                color: r.type == 'Drowsy' ? Colors.orangeAccent : Colors.cyanAccent,
              ),
              title: Text(r.type),
              subtitle: Text('${r.message}\n$ts  • angle: ${r.headAngle?.toStringAsFixed(1) ?? '-'}°'),
              isThreeLine: true,
            ),
          ),
        );
        children.add(const Divider(height: 1));
      }
    }
    if (children.isEmpty) {
      return const Center(child: Text('No events for the selected filters', style: TextStyle(color: Colors.white54)));
    }
    return ListView(children: children);
  }
}