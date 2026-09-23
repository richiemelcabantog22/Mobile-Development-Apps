import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // ADD haptics
import '../core/constants.dart';
import '../services/settings_service.dart';
import '../services/theme_service.dart';
import '../services/alert_service.dart'; // ADD: to toggle haptics-only
import '../services/drowsiness_service.dart'; // for AlertType
import '../widgets/neon_panel.dart'; // ADD: futuristic panel

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  double eyeClosedThreshold = 0.35;
  double headTiltThreshold = 45;
  int eyeClosedDuration = 1500;
  bool _loading = true;

  ThemeMode _mode = ThemeService.instance.mode.value;
  String _accent = ThemeService.instance.accent.value;      // ADD
  double _textScale = ThemeService.instance.textScale.value; // ADD

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    if (!SettingsService.isInitialized) {
      await SettingsService.init();
    }
    final cfg = SettingsService.instance.current;
    setState(() {
      eyeClosedThreshold = cfg.eyeClosedThreshold;
      headTiltThreshold = cfg.headTiltThresholdDeg;
      eyeClosedDuration = cfg.eyeClosedDurationMs;
      _loading = false;
    });
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
    );
  }

  Widget _accentOption(String name, Color color) {
    final selected = _accent == name;
    return ChoiceChip(
      label: Text(name[0].toUpperCase() + name.substring(1)),
      selected: selected,
      selectedColor: color.withOpacity(0.25),
      avatar: CircleAvatar(backgroundColor: color, radius: 8),
      onSelected: (_) async {
        HapticFeedback.selectionClick();
        setState(() => _accent = name);
        await ThemeService.instance.setAccent(name);
        // Ensure immediate theme refresh in case MyApp isn't listening yet
        ThemeService.instance.accent.notifyListeners();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle('Alerts'),
          NeonPanel(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
              child: Column(
                children: [
                  ValueListenableBuilder<bool>(
                    valueListenable: AlertService.hapticsOnly,
                    builder: (context, value, _) {
                      return SwitchListTile(
                        title: const Text('Haptic-only alerts'),
                        subtitle: const Text('Suppress audio and use vibration with on-screen banner'),
                        value: value,
                        onChanged: (v) {
                          HapticFeedback.selectionClick();
                          AlertService.hapticsOnly.value = v;
                        },
                      );
                    },
                  ),
                  const Divider(height: 8),
                  Row(
                    children: const [
                      Text('Alert Volume', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  ValueListenableBuilder<double>(
                    valueListenable: AlertService.volume,
                    builder: (context, vol, _) {
                      return Slider(
                        min: 0.0,
                        max: 1.0,
                        divisions: 10,
                        value: vol,
                        label: vol.toStringAsFixed(1),
                        onChanged: (v) {
                          setState(() {}); // update label immediately
                          AlertService.instance.setVolume(v);
                        },
                      );
                    },
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Wrap(
                      spacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => AlertService.instance.test(AlertType.drowsy),
                          icon: const Icon(Icons.bedtime),
                          label: const Text('Test Drowsy'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => AlertService.instance.test(AlertType.headTilt),
                          icon: const Icon(Icons.screen_rotation_alt),
                          label: const Text('Test Head Tilt'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          _sectionTitle('Appearance'),
          NeonPanel(
            child: Column(
              children: [
                RadioListTile<ThemeMode>(
                  title: const Text('System Default'),
                  value: ThemeMode.system,
                  groupValue: _mode,
                  onChanged: (m) async {
                    if (m == null) return;
                    HapticFeedback.selectionClick();
                    setState(() => _mode = m);
                    await ThemeService.instance.setMode(m);
                  },
                ),
                const Divider(height: 1),
                RadioListTile<ThemeMode>(
                  title: const Text('Light Mode'),
                  value: ThemeMode.light,
                  groupValue: _mode,
                  onChanged: (m) async {
                    if (m == null) return;
                    HapticFeedback.selectionClick();
                    setState(() => _mode = m);
                    await ThemeService.instance.setMode(m);
                  },
                ),
                const Divider(height: 1),
                RadioListTile<ThemeMode>(
                  title: const Text('Dark Mode'),
                  value: ThemeMode.dark,
                  groupValue: _mode,
                  onChanged: (m) async {
                    if (m == null) return;
                    HapticFeedback.selectionClick();
                    setState(() => _mode = m);
                    await ThemeService.instance.setMode(m);
                  },
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Accent Color', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          _accentOption('purple', Colors.deepPurpleAccent),
                          _accentOption('cyan', Colors.cyanAccent),
                          _accentOption('amber', Colors.amberAccent),
                          _accentOption('blue', Colors.lightBlueAccent),
                          _accentOption('green', Colors.lightGreenAccent),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Live preview bar to confirm accent applied
                      Row(
                        children: [
                          const Text('Preview', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              height: 10,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                gradient: LinearGradient(
                                  colors: [
                                    Theme.of(context).colorScheme.secondary.withOpacity(0.15),
                                    Theme.of(context).colorScheme.secondary,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text('Text Size', style: TextStyle(fontWeight: FontWeight.bold)),
                      Slider(
                        min: 0.9,
                        max: 1.3,
                        divisions: 8,
                        value: _textScale,
                        label: _textScale.toStringAsFixed(2),
                        onChanged: (v) => setState(() => _textScale = v),
                        onChangeEnd: (v) async {
                          HapticFeedback.selectionClick();
                          await ThemeService.instance.setTextScale(v);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          _sectionTitle('Sensitivity Presets'),
          NeonPanel(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Relaxed'),
                    selected: false,
                    onSelected: (_) async {
                      HapticFeedback.selectionClick();
                      await SettingsService.instance.save(
                        eyeClosedThreshold: 0.25,
                        eyeClosedDurationMs: 1800,
                        headTiltThresholdDeg: 55,
                      );
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Sensitivity set to Relaxed')),
                      );
                    },
                  ),
                  ChoiceChip(
                    label: const Text('Balanced'),
                    selected: false,
                    onSelected: (_) async {
                      HapticFeedback.selectionClick();
                      await SettingsService.instance.save(
                        eyeClosedThreshold: 0.35,
                        eyeClosedDurationMs: 1500,
                        headTiltThresholdDeg: 45,
                      );
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Sensitivity set to Balanced')),
                      );
                    },
                  ),
                  ChoiceChip(
                    label: const Text('Strict'),
                    selected: false,
                    onSelected: (_) async {
                      HapticFeedback.selectionClick();
                      await SettingsService.instance.save(
                        eyeClosedThreshold: 0.45,
                        eyeClosedDurationMs: 1200,
                        headTiltThresholdDeg: 35,
                      );
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Sensitivity set to Strict')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          
          _sectionTitle('Detection Thresholds'),
          const Text('Eye Closure Threshold (probability)', style: TextStyle(fontWeight: FontWeight.bold)),
          Slider(
            min: 0.1,
            max: 0.9,
            value: eyeClosedThreshold,
            onChanged: (v) => setState(() => eyeClosedThreshold = v),
            label: eyeClosedThreshold.toStringAsFixed(2),
          ),
          const SizedBox(height: 8),
          const Text('Head Tilt Threshold (degrees)', style: TextStyle(fontWeight: FontWeight.bold)),
          Slider(
            min: 10,
            max: 60,
            value: headTiltThreshold,
            onChanged: (v) => setState(() => headTiltThreshold = v),
            label: headTiltThreshold.toStringAsFixed(0),
          ),
          const SizedBox(height: 8),
          const Text('Eye Closed Duration (ms)', style: TextStyle(fontWeight: FontWeight.bold)),
          Slider(
            min: 500,
            max: 3000,
            value: eyeClosedDuration.toDouble(),
            divisions: 10,
            onChanged: (v) => setState(() => eyeClosedDuration = v.toInt()),
            label: eyeClosedDuration.toString(),
          ),
          
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () async {
              HapticFeedback.lightImpact();
              await SettingsService.instance.save(
                eyeClosedThreshold: eyeClosedThreshold,
                eyeClosedDurationMs: eyeClosedDuration,
                headTiltThresholdDeg: headTiltThreshold,
              );
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings saved')),
              );
            },
            child: const Text('Save Thresholds'),
          ),
          
          _sectionTitle('About'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('AI-Powered Driver Safety System'),
              subtitle: const Text('Detects drowsiness and head tilt in real-time to keep you safe on the road.'),
              trailing: const Text('v0.1.0'),
              onTap: () {},
            ),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy'),
            subtitle: const Text('All processing happens on-device. No video is uploaded.'),
          ),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Help & Tips'),
            subtitle: const Text('Mount the phone at eye level and ensure good lighting.'),
          ),
        ],
      ),
    );
  }
}