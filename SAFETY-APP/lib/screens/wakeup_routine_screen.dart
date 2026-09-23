import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:io' show Platform;
import 'package:battery_plus/battery_plus.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:hive/hive.dart';
import '../database/hive_database.dart';
import '../models/pre_drive_result.dart';
import '../widgets/animations/breathing_circle.dart';
import '../widgets/animations/eye_focus.dart';
import '../widgets/animations/progress_ring.dart';
import '../widgets/neon_panel.dart'; // unify futuristic look

enum RoutineStep { checklist, breathing, eyeFocus, reactionTest, summary }

class WakeUpRoutineScreen extends StatefulWidget {
  const WakeUpRoutineScreen({super.key});

  @override
  State<WakeUpRoutineScreen> createState() => _WakeUpRoutineScreenState();
}

class _WakeUpRoutineScreenState extends State<WakeUpRoutineScreen> {
  final FlutterTts _tts = FlutterTts();
  final Battery _battery = Battery();
  RoutineStep _step = RoutineStep.checklist;
  int _skipped = 0;

  // Checklist
  bool mountOk = false, seatOk = false, mirrorsOk = false, cabinOk = false;

  // Breathing/Eye focus timers
  int _breathSeconds = 30;
  int _eyeFocusSeconds = 30;
  Timer? _timer;

  // Reaction test
  static const int _rounds = 3;
  int _currentRound = 0;
  bool _waitingSignal = false;
  bool _tapNow = false;
  DateTime? _signalAt;
  final List<int> _reactions = [];

  // Ambient/Battery
  int? _ambientY; // 0..255
  int _batteryLevel = 100;

  @override
  void initState() {
    super.initState();
    // ADJUST: Slower, platform-tuned speech rate and await completion
    if (Platform.isAndroid) {
      _tts.setSpeechRate(0.5);
    } else if (Platform.isIOS) {
      _tts.setSpeechRate(0.45);
    } else {
      _tts.setSpeechRate(0.5);
    }
    _tts.setPitch(1.0);
    _tts.setVolume(0.9);
    _tts.awaitSpeakCompletion(true);

    _readBattery();
    _speak("Welcome. Let's prepare before driving. Start with the checklist.");
  }

  Future<void> _readBattery() async {
    try {
      final level = await _battery.batteryLevel;
      setState(() => _batteryLevel = level);
    } catch (_) {}
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tts.stop();
    super.dispose();
  }

  void _nextStep() {
    setState(() {
      if (_step == RoutineStep.checklist) {
        _step = RoutineStep.breathing;
        _startBreathing();
      } else if (_step == RoutineStep.breathing) {
        _step = RoutineStep.eyeFocus;
        _startEyeFocus();
      } else if (_step == RoutineStep.eyeFocus) {
        _step = RoutineStep.reactionTest;
        _startReactionRound();
      } else if (_step == RoutineStep.reactionTest) {
        _step = RoutineStep.summary;
        _speak("Great job. Here is your summary.");
      }
    });
  }

  Future<void> _speak(String text) async {
    try {
      await _tts.stop();
      await _tts.speak(text);
    } catch (_) {}
  }

  void _skipStep() {
    setState(() {
      _skipped += 1;
    });
    _nextStep();
  }

  // Breathing step: simple countdown with guidance
  void _startBreathing() {
    _speak("Deep breathing. Inhale through the nose, and exhale slowly. We will do this for 30 seconds.");
    _timer?.cancel();
    _breathSeconds = 30;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_breathSeconds <= 0) {
        t.cancel();
        _speak("Breathing complete.");
        _nextStep();
      } else {
        setState(() => _breathSeconds--);
      }
    });
  }

  // Eye focus step: near/far focus shifts
  void _startEyeFocus() {
    _speak("Eye focus exercise. Alternate focus between something near and something far. 30 seconds.");
    _timer?.cancel();
    _eyeFocusSeconds = 30;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_eyeFocusSeconds <= 0) {
        t.cancel();
        _speak("Eye focus complete.");
        _nextStep();
      } else {
        setState(() => _eyeFocusSeconds--);
      }
    });
  }

  // Reaction test
  void _startReactionRound() async {
    if (_currentRound >= _rounds) {
      setState(() => _step = RoutineStep.summary);
      _speak("Reaction test complete.");
      return;
    }
    setState(() {
      _waitingSignal = true;
      _tapNow = false;
    });
    final delayMs = Random().nextInt(2000) + 1000; // 1-3s
    await Future.delayed(Duration(milliseconds: delayMs));
    if (!mounted || _step != RoutineStep.reactionTest) return;
    setState(() {
      _waitingSignal = false;
      _tapNow = true;
      _signalAt = DateTime.now();
    });
  }

  void _onTapReaction() {
    if (!_tapNow || _signalAt == null) {
      // Tapped too early
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Too early! Wait for "Tap now!"')));
      return;
    }
    final ms = DateTime.now().difference(_signalAt!).inMilliseconds;
    _reactions.add(ms);
    _currentRound += 1;
    setState(() {
      _tapNow = false;
    });
    if (_currentRound < _rounds) {
      _startReactionRound();
    } else {
      _speak("Good work. Your average reaction time is ${_avgReactionMs()} milliseconds.");
      setState(() => _step = RoutineStep.summary);
    }
  }

  int _avgReactionMs() {
    if (_reactions.isEmpty) return 0;
    return _reactions.reduce((a, b) => a + b) ~/ _reactions.length;
  }

  // Ambient brightness from single camera frame (average Y)
  Future<void> _checkAmbient() async {
    try {
      final cams = await availableCameras();
      final front = cams.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cams.first,
      );
      final controller = CameraController(
        front,
        ResolutionPreset.low,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      await controller.initialize();

      // FIX: startImageStream returns Future<void>, not a StreamSubscription.
      // Use a Completer and stop the stream after first frame.
      final completer = Completer<void>();
      bool captured = false;

      await controller.startImageStream((image) async {
        if (captured) return;
        captured = true;

        // Compute average Y from plane 0 (sampled)
        final yPlane = image.planes[0];
        final data = yPlane.bytes;
        int sum = 0;
        const step = 50;
        for (int i = 0; i < data.length; i += step) {
          sum += data[i];
        }
        final avg = (sum / (data.length / step)).round().clamp(0, 255);

        if (mounted) {
          setState(() {
            _ambientY = avg;
          });
        }

        await controller.stopImageStream();
        await controller.dispose();
        if (!completer.isCompleted) completer.complete();
      });

      // Wait for the first frame (with timeout)
      await completer.future.timeout(const Duration(seconds: 3));
      _speak("Ambient check complete.");
    } catch (e) {
      debugPrint('Ambient check failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ambient check failed')));
    }
  }

  Future<void> _saveResult() async {
    final box = HiveDatabase.preDriveBox;
    final result = PreDriveResult(
      timestamp: DateTime.now(),
      rounds: _rounds,
      avgReactionMs: _avgReactionMs(),
      checklistMountOk: mountOk,
      checklistSeatOk: seatOk,
      checklistMirrorsOk: mirrorsOk,
      checklistCabinOk: cabinOk,
      skippedSteps: _skipped,
      batteryLevel: _batteryLevel,
      ambientLevelY: _ambientY,
    );
    await box.add(result);
  }

  Widget _buildChecklist() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Pre-drive Checklist', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        CheckboxListTile(
          value: mountOk,
          onChanged: (v) => setState(() => mountOk = v ?? false),
          title: const Text('Phone mounted at eye level and stable'),
        ),
        CheckboxListTile(
          value: seatOk,
          onChanged: (v) => setState(() => seatOk = v ?? false),
          title: const Text('Seat adjusted comfortably'),
        ),
        CheckboxListTile(
          value: mirrorsOk,
          onChanged: (v) => setState(() => mirrorsOk = v ?? false),
          title: const Text('Mirrors aligned properly'),
        ),
        CheckboxListTile(
          value: cabinOk,
          onChanged: (v) => setState(() => cabinOk = v ?? false),
          title: const Text('Cabin temperature comfortable'),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: _nextStep,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Continue'),
            ),
            const SizedBox(width: 12),
            TextButton(
              onPressed: _skipStep,
              child: const Text('Skip'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBreathing() {
    const total = 30;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Deep Breathing', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        const Text('Inhale through your nose, exhale slowly. Follow the pulsing guide.'),
        const SizedBox(height: 16),
        Center(
          child: Column(
            children: [
              const BreathingCircle(size: 180),
              const SizedBox(height: 16),
              ProgressRing(totalSeconds: total, remainingSeconds: _breathSeconds, size: 120),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(onPressed: _skipStep, child: const Text('Skip')),
        ),
      ],
    );
  }

  Widget _buildEyeFocus() {
    const total = 30;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Eye Focus Shifts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        const Text('Alternate focus between a near and a far point. Follow the eye marker.'),
        const SizedBox(height: 16),
        Center(
          child: Column(
            children: [
              const EyeFocusAnimation(width: 260, height: 150),
              const SizedBox(height: 16),
              ProgressRing(totalSeconds: total, remainingSeconds: _eyeFocusSeconds, size: 120),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(onPressed: _skipStep, child: const Text('Skip')),
        ),
      ],
    );
  }

  Widget _buildReactionTest() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Reaction Time Test', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text('Round ${_currentRound + 1} / $_rounds'),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            children: [
              Text(
                _tapNow ? 'TAP NOW!' : (_waitingSignal ? 'Wait for it...' : 'Get Ready'),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _tapNow ? Colors.greenAccent : Colors.amberAccent,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _onTapReaction,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text('Tap', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
              if (_reactions.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Last: ${_reactions.last} ms   Avg: ${_avgReactionMs()} ms'),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () {
            _skipped += 1;
            _step = RoutineStep.summary;
            setState(() {});
          },
          child: const Text('Skip test'),
        ),
      ],
    );
  }

  String _ambientSuggestion() {
    if (_ambientY == null) return 'Not checked';
    if (_ambientY! < 60) return 'Too dim – consider more lighting.';
    if (_ambientY! < 140) return 'OK lighting.';
    return 'Very bright – avoid glare if possible.';
    }

  Widget _buildSummary() {
    final avg = _avgReactionMs();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: Text('Average reaction: ${avg > 0 ? '$avg ms' : 'N/A'}')),
            ElevatedButton.icon(
              onPressed: _checkAmbient,
              icon: const Icon(Icons.light_mode),
              label: const Text('Check Ambient'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text('Ambient: ${_ambientY?.toString() ?? 'N/A'} (${_ambientSuggestion()})'),
        Text('Battery: $_batteryLevel%'),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () async {
                  await _saveResult();
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pre-drive routine saved')));
                },
                icon: const Icon(Icons.save),
                label: const Text('Save'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pushReplacementNamed(context, '/monitor'),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Start Monitoring'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final steps = ['Checklist', 'Breathing', 'Eye Focus', 'Reaction', 'Summary'];
    final currentIndex = RoutineStep.values.indexOf(_step);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pre-Drive Wake Up'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F0C29), Color(0xFF302B63), Color(0xFF24243E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            children: [
              // Progress stepper
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(steps.length, (i) {
                  final active = i <= currentIndex;
                  return Expanded(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: active ? Colors.deepPurpleAccent : Colors.white24,
                          child: Text('${i + 1}', style: const TextStyle(fontSize: 12, color: Colors.white)),
                        ),
                        const SizedBox(height: 4),
                        Text(steps[i], style: const TextStyle(fontSize: 10, color: Colors.white70), overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              // Step content
              if (_step == RoutineStep.checklist) _glassCard(child: _buildChecklist()),
              if (_step == RoutineStep.breathing) _glassCard(child: _buildBreathing()),
              if (_step == RoutineStep.eyeFocus) _glassCard(child: _buildEyeFocus()),
              if (_step == RoutineStep.reactionTest) _glassCard(child: _buildReactionTest()),
              if (_step == RoutineStep.summary) _glassCard(child: _buildSummary()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _glassCard({required Widget child}) {
    return NeonPanel(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}
