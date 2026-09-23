import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../services/session_service.dart';
import '../services/alert_service.dart';
import '../services/settings_service.dart';
import '../widgets/sparkline.dart';
import '../widgets/neon_panel.dart';
import '../widgets/radial_gauge.dart'; // keep gauge
import '../models/drowsiness_record.dart';
import '../database/hive_database.dart';
import '../widgets/expandable_fab.dart'; // speed-dial FAB
import 'session_summary_screen.dart'; // NEW: summary screen

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final SessionService _session = SessionService.instance;

  Future<void> _toggleSession() async {
    HapticFeedback.selectionClick();
    if (_session.active.value) {
      // Capture snapshot before stopping for summary use
      final snap = _session.current.value;
      _session.stop();
      if (!mounted) return;
      // Decide whether to show summary: if there were alerts or the session lasted long enough
      if (snap != null) {
        final end = snap.end ?? DateTime.now();
        final duration = end.difference(snap.start);
        const int minSummarySeconds = 60; // show summary if session >= 60s
        final shouldShow = snap.alerts > 0 || duration.inSeconds >= minSummarySeconds;
        if (shouldShow) {
          // Navigate to summary screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SessionSummaryScreen(start: snap.start, end: end, stats: snap),
            ),
          );
          return;
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Session stopped')));
    } else {
      _session.start();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session started')),
      );
    }
    setState(() {});
  }

  Future<void> _snooze2min() async {
    HapticFeedback.lightImpact();
    await AlertService().snooze(seconds: 120);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Alerts snoozed for 2 minutes')),
    );
  }

  Future<void> _applyPreset(String preset) async {
    HapticFeedback.selectionClick();
    switch (preset) {
      case 'Relaxed':
        await SettingsService.instance.save(
          eyeClosedThreshold: 0.25,
          eyeClosedDurationMs: 1800,
          headTiltThresholdDeg: 55,
        );
        break;
      case 'Balanced':
        await SettingsService.instance.save(
          eyeClosedThreshold: 0.35,
          eyeClosedDurationMs: 1500,
          headTiltThresholdDeg: 45,
        );
        break;
      case 'Strict':
        await SettingsService.instance.save(
          eyeClosedThreshold: 0.45,
          eyeClosedDurationMs: 1200,
          headTiltThresholdDeg: 35,
        );
        break;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Sensitivity set to $preset')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Box<DrowsinessRecord> eventsBox = HiveDatabase.drowsinessBox;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          ValueListenableBuilder<bool>(
            valueListenable: AlertService.hapticsOnly,
            builder: (_, value, __) {
              return IconButton(
                tooltip: value ? 'Haptics only: ON' : 'Haptics only: OFF',
                icon: Icon(value ? Icons.vibration : Icons.volume_up_rounded),
                onPressed: () => AlertService.hapticsOnly.value = !value,
              );
            },
          ),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      // RESTORE: Expandable speed-dial FAB (avoid duplicate Monitor button)
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: ExpandableFab(
        heroTag: 'dash_fab',
        children: [
          FabAction(
            icon: Icons.self_improvement,
            label: 'Wake-up',
            onTap: () => Navigator.pushNamed(context, '/wakeup'),
          ),
          FabAction(
            icon: Icons.history,
            label: 'History',
            onTap: () => Navigator.pushNamed(context, '/history'),
          ),
          FabAction(
            icon: Icons.notifications_off,
            label: 'Snooze 2m',
            onTap: _snooze2min,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Futuristic status header with radial attention gauge and ONE clear CTA
          ValueListenableBuilder<bool>(
            valueListenable: _session.active,
            builder: (_, active, __) {
              final s = _session.current.value;
              final att = (s == null || s.attentionHistory.isEmpty)
                  ? 100.0
                  : s.attentionHistory.last;
              return NeonPanel(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      RadialGauge(
                        value: att,
                        size: 88,
                        label: '${att.toStringAsFixed(0)}',
                        gradientColors: const [Colors.cyanAccent, Colors.deepPurpleAccent],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              active ? 'Monitoring Active' : 'Ready to Monitor',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 0.6),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              active
                                  ? 'Real-time drowsiness detection is running.'
                                  : 'Tap below to open the Monitor.',
                              style: const TextStyle(color: Colors.white70),
                            ),
                            const SizedBox(height: 12),
                            // Single prominent CTA: Open Monitor
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => Navigator.pushNamed(context, '/monitor'),
                                icon: const Icon(Icons.visibility_rounded),
                                label: const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 6),
                                  child: Text('Open Monitor', style: TextStyle(fontWeight: FontWeight.w700)),
                                ),
                                style: ElevatedButton.styleFrom(shape: const StadiumBorder()),
                              ),
                            ),
                            const SizedBox(height: 6),
                            // Secondary link (text) to Wake-up routine to avoid button clutter
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                onPressed: () => Navigator.pushNamed(context, '/wakeup'),
                                icon: const Icon(Icons.self_improvement, size: 18),
                                label: const Text('Wake-up routine'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 12),
          // Session panel (futuristic)
          ValueListenableBuilder<bool>(
             valueListenable: _session.active,
             builder: (_, active, __) {
               final stats = _session.current.value;
               final attention = stats?.attentionHistory ?? const <double>[];
              return NeonPanel(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Row(
                         children: [
                           Icon(active ? Icons.circle : Icons.circle_outlined,
                               color: active ? Colors.greenAccent : Colors.white54),
                           const SizedBox(width: 8),
                           Text(
                             active ? 'Session Active' : 'No Active Session',
                             style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.6),
                           ),
                           const Spacer(),
                           // ADD: Start/Stop session button in the session panel
                           
                         ],
                       ),
                       const SizedBox(height: 12),
                       ElevatedButton.icon(
                             onPressed: _toggleSession,
                             icon: Icon(active ? Icons.stop : Icons.play_arrow),
                             label: Text(active ? 'Stop Session' : 'Start Session'),
                           ),
                           const SizedBox(height: 12),
                       if (attention.isNotEmpty) ...[
                         const Text('Attention trend (recent)', style: TextStyle(letterSpacing: 0.4)),
                         const SizedBox(height: 8),
                         SizedBox(height: 60, child: Sparkline(data: List<double>.from(attention))),
                       ] else
                         const Text(
                           'Attention trend will appear here once monitoring starts',
                           style: TextStyle(color: Colors.white54, letterSpacing: 0.3),
                         ),
                     ],
                   ),
                 ),
               );
             },
           ),

           const SizedBox(height: 12),
          // Sensitivity presets quick chips in neon panel
          NeonPanel(
            child: Padding(
               padding: const EdgeInsets.all(12),
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   const Text('Sensitivity Presets', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.6)),
                   const SizedBox(height: 8),
                   Wrap(
                     spacing: 8,
                     children: [
                       ChoiceChip(label: const Text('Relaxed'), selected: false, onSelected: (_) => _applyPreset('Relaxed')),
                       ChoiceChip(label: const Text('Balanced'), selected: false, onSelected: (_) => _applyPreset('Balanced')),
                       ChoiceChip(label: const Text('Strict'), selected: false, onSelected: (_) => _applyPreset('Strict')),
                     ],
                   ),
                 ],
               ),
             ),
           ),

           const SizedBox(height: 12),
          // Recent events in neon panel
          NeonPanel(
            child: Padding(
               padding: const EdgeInsets.all(12),
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Row(
                     children: [
                       const Text('Recent Events', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.6)),
                       const Spacer(),
                       TextButton(
                         onPressed: () => Navigator.pushNamed(context, '/history'),
                         child: const Text('View All'),
                       ),
                     ],
                   ),
                   const Divider(height: 12),
                   ValueListenableBuilder<Box<DrowsinessRecord>>(
                     valueListenable: eventsBox.listenable(),
                     builder: (_, box, __) {
                       final items = box.values.toList()
                         ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
                       final recent = items.take(5).toList();
                       if (recent.isEmpty) {
                         return const Text('No events yet', style: TextStyle(color: Colors.white54, letterSpacing: 0.3));
                       }
                       return Column(
                         children: recent.map((r) {
                           final t = TimeOfDay.fromDateTime(r.timestamp).format(context);
                           return ListTile(
                             dense: true,
                             leading: Icon(
                               r.type == 'Drowsy'
                                   ? Icons.bedtime
                                   : (r.type == 'HeadTilt' ? Icons.screen_rotation : Icons.monitor_heart),
                               color: r.type == 'Drowsy' ? Colors.orangeAccent : Colors.cyanAccent,
                             ),
                             title: Text('${r.type}  •  $t'),
                             subtitle: Text(r.message, maxLines: 1, overflow: TextOverflow.ellipsis),
                           );
                         }).toList(),
                       );
                     },
                   ),
                 ],
               ),
             ),
           ),

           const SizedBox(height: 12),
          // More links in neon panel
          NeonPanel(
            child: Padding(
               padding: const EdgeInsets.all(12),
               child: Column(
                 children: [
                   Row(
                     children: [
                       const Text('More', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.6)),
                     ],
                   ),
                   const SizedBox(height: 8),
                   Wrap(
                     spacing: 8,
                     runSpacing: 8,
                     children: [
                       OutlinedButton.icon(
                         onPressed: () => Navigator.pushNamed(context, '/tips'),
                         icon: const Icon(Icons.help_outline),
                         label: const Text('Tips & Help'),
                       ),
                       OutlinedButton.icon(
                         onPressed: () => Navigator.pushNamed(context, '/diagnostics'),
                         icon: const Icon(Icons.health_and_safety_outlined),
                         label: const Text('Diagnostics'),
                       ),
                       OutlinedButton.icon(
                         onPressed: () => Navigator.pushNamed(context, '/about'),
                         icon: const Icon(Icons.privacy_tip_outlined),
                         label: const Text('About & Privacy'),
                       ),
                     ],
                   ),
                 ],
               ),
             ),
           ),
         ],
       ),
    );
  }
}