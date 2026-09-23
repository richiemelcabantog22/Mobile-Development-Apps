import 'package:flutter/material.dart';
import '../../../../services/app_settings_service.dart';
import '../../../../services/user_progress_service.dart';
import '../../../../services/folklore_creature_service.dart';
import '../../../../services/audio_governor_service.dart'; 

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _settings = AppSettingsService.instance;

  late ThemeMode _mode;
  late bool _dailyLore;
  late bool _bgmEnabled; 

  @override
  void initState() {
    super.initState();
    _mode = _settings.themeMode;
    _dailyLore = _settings.dailyLoreEnabled;
    _bgmEnabled = _settings.bgmEnabled; 
  }

  // OPTIMIZED: Triggers absolute systemic rebuild notifications down to main.dart
  Future<void> _applyTheme(ThemeMode mode) async {
    await _settings.setThemeMode(mode);
    if (mounted) {
      setState(() => _mode = mode);
    }
  }

  Future<void> _toggleDailyLore(bool value) async {
    await _settings.setDailyLoreEnabled(value);
    if (mounted) {
      setState(() => _dailyLore = value);
    }
  }

  Future<void> _toggleBgm(bool value) async {
    await _settings.setBgmEnabled(value);
    AudioGovernorService.instance.toggleBgmState(value); 
    if (mounted) {
      setState(() => _bgmEnabled = value);
    }
  }

  void _showAbout() {
    showAboutDialog(
      context: context,
      applicationName: 'PAMANA',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.auto_awesome),
      children: const [
        Text(
          'Philippine Mythology AR & 3D learning app.\n'
          'Explore creatures by region, view them in 3D/AR, and track your learning progress with quizzes, flashcards, and badges.',
        ),
      ],
    );
  }

  Future<void> _resetProgress() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reset Progress'),
        content: const Text('This will clear badges, timers, and discovery status. Continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Reset')),
        ],
      ),
    );
    if (confirmed == true) {
      await UserProgressService.instance.reset();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Progress reset')));
      }
    }
  }

  Future<void> _resetGrimoire() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear Grimoire'),
        content: const Text('This will remove all favorites and notes. Continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Clear')),
        ],
      ),
    );
    if (confirmed == true) {
      await FolkloreCreatureService.instance.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Grimoire cleared')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Appearance'),
            subtitle: const Text('Choose theme mode'),
            leading: const Icon(Icons.brightness_6),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(value: ThemeMode.system, label: Text('System'), icon: Icon(Icons.settings_suggest_outlined)),
                ButtonSegment(value: ThemeMode.light, label: Text('Light'), icon: Icon(Icons.light_mode_outlined)),
                ButtonSegment(value: ThemeMode.dark, label: Text('Dark'), icon: Icon(Icons.dark_mode_outlined)),
              ],
              selected: <ThemeMode>{_mode},
              onSelectionChanged: (sel) => _applyTheme(sel.first),
            ),
          ),
          const Divider(),
          
          SwitchListTile(
            title: const Text('Ambient Soundscapes'),
            subtitle: const Text('Enable immersive background music and environmental sounds'),
            value: _bgmEnabled,
            onChanged: _toggleBgm,
            secondary: const Icon(Icons.music_note_outlined),
          ),
          const Divider(),

          SwitchListTile(
            title: const Text('Daily Lore Popup'),
            subtitle: const Text('Show the Daily Lore dialog once per day'),
            value: _dailyLore,
            onChanged: _toggleDailyLore,
            secondary: const Icon(Icons.auto_awesome_outlined),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About PAMANA'),
            subtitle: const Text('Version, credits, and description'),
            onTap: _showAbout,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.refresh),
            title: const Text('Reset Progress'),
            subtitle: const Text('Clear badges, timers, and discovery status'),
            onTap: _resetProgress,
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: const Text('Clear Grimoire'),
            subtitle: const Text('Remove all favorites and notes'),
            onTap: _resetGrimoire,
          ),
        ],
      ),
    );
  }
}