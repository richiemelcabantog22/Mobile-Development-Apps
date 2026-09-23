import 'dart:async';
import 'dart:typed_data';
import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart'; // narrator
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';

import '../services/alert_service.dart';
import '../services/settings_service.dart';
import '../services/attention_service.dart';
import '../services/session_service.dart';
import '../services/dizziness_service.dart';
import '../services/face_detector_service.dart';
import '../services/drowsiness_service.dart';
import '../widgets/face_painter.dart';
import '../core/constants.dart';
import '../database/hive_database.dart';
import '../models/drowsiness_record.dart';
import '../widgets/animations/progress_ring.dart'; // ADD: for ProgressRing widget
import '../widgets/attention_meter.dart'; // ADD: attention meter UI
import '../services/attention_service.dart'; // ADD: attention logic
import '../widgets/neon_panel.dart'; // ADD: futuristic panels
import '../widgets/sparkline.dart'; // for session summary
import '../services/session_service.dart'; // Start/Stop session and summary
import 'package:hive_flutter/hive_flutter.dart'; // ensure listenable available app-wide if you use it here later

class MonitoringScreen extends StatefulWidget {
  const MonitoringScreen({super.key});
  @override
  State<MonitoringScreen> createState() => _MonitoringScreenState();
}

class _MonitoringScreenState extends State<MonitoringScreen> with WidgetsBindingObserver {
  CameraController? _cameraController;
  final FaceDetectorService _detector = FaceDetectorService();
  final DrowsinessService _drowsiness = DrowsinessService();
  final AlertService _alert = AlertService();
  final DizzinessService _dizzy = DizzinessService();
  final FlutterTts _narrator = FlutterTts();
  final AttentionService _attention = AttentionService();
  final SessionService _session = SessionService.instance;

  bool _isBusy = false;
  String _status = "Monitoring...";
  List<Face> _faces = [];

  Size? _inputImageSize;
  double? _lastHeadAngleDeg;
  int? _lastBpm;
  bool _shadeOn = false;
  final DateTime _warmupStart = DateTime.now();
  bool _announceWarmupStart = true;
  bool _announceWarmupEnd = false;
  DateTime? _lastDizzyAlertAt;
  bool _snoozedNotified = false;

  DateTime _lastFrameAt = DateTime.now();
  DateTime _lastProcessedAt = DateTime.fromMillisecondsSinceEpoch(0);
  static const Duration _minProcessInterval = Duration(milliseconds: 120);

  Timer? _watchdogTimer;
  Timer? _warmupTimer;
  bool _restarting = false;
  bool _shuttingDown = false;

  StreamSubscription<GyroscopeEvent>? _gyroSub;

  double? _ambientYAvg;
  int _lowLightCounter = 0;
  bool get _lowLight => (_ambientYAvg ?? 255) < 40 && _lowLightCounter >= 6; // ~0.5s if 120ms processing
  bool _sessionActive() => _session.active.value;

  // Yawn detection state
  DateTime? _yawnStartAt;
  DateTime? _lastYawnAt;
  static const int _yawnHoldSeconds = 2;      // mouth open >= 2s
  static const int _yawnCooldownSeconds = 10; // avoid duplicate records
  static const double _yawnOpenThreshold = 0.06;  // gap/faceHeight to start
  static const double _yawnCloseThreshold = 0.045; // hysteresis to reset

  // Drowsy bout aggregation to avoid spammy history
  bool _drowsyOngoing = false;
  DateTime? _drowsyStartAt;
  bool _drowsyAlertedThisBout = false;
  int _drowsyBouts = 0;
  static const int _repeatDrowsyEscalate = 5; // escalate after 5 bouts per session

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    WakelockPlus.enable();
    _ensureInit();

    // narrator settings
    _narrator.setSpeechRate(Platform.isIOS ? 0.45 : 0.5);
    _narrator.setPitch(1.0);
    _narrator.setVolume(0.85);
    _narrator.awaitSpeakCompletion(true);

    _gyroSub = gyroscopeEvents.listen((e) {
      final angle = _lastHeadAngleDeg ?? 0.0;
      _dizzy.push(headRollDeg: angle, gyro: e);
    });

    _watchdogTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (DateTime.now().difference(_lastFrameAt).inSeconds >= 3 && !_restarting) {
        _restarting = true;
        if (mounted) setState(() => _status = "Restarting camera…");
        await _restartCamera();
        _restarting = false;
      }
    });

    _warmupTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final left = 10 - DateTime.now().difference(_warmupStart).inSeconds;
      if (left >= 0) setState(() {});
      else _warmupTimer?.cancel();
    });
  }

  Future<void> _ensureInit() async {
    if (!SettingsService.isInitialized) {
      await SettingsService.init();
    }
    await _startCamera();
  }

  @override
  void dispose() {
    _shuttingDown = true;
    try { _cameraController?.stopImageStream(); } catch (_) {}
    WidgetsBinding.instance.removeObserver(this);
    WakelockPlus.disable();
    _applySystemUi(shaded: false);
    _alert.stop();
    _cameraController?.dispose();
    _detector.dispose();
    _gyroSub?.cancel();
    _watchdogTimer?.cancel();
    _warmupTimer?.cancel();
    _narrator.stop();
    super.dispose();
  }

  void _applySystemUi({required bool shaded}) {
    if (shaded) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  void _toggleShade() {
    HapticFeedback.selectionClick();
    setState(() {
      _shadeOn = !_shadeOn;
      _applySystemUi(shaded: _shadeOn);
    });
  }

  Future<void> _startCamera() async {
    final cameras = await availableCameras();
    final frontCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _cameraController = CameraController(
      frontCamera,
      ResolutionPreset.low, // faster FPS with ML Kit
      enableAudio: false,
      // Force formats ML Kit expects to avoid "ImageFormat is not supported"
      imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888,
    );

    await _cameraController!.initialize();
    if (!mounted) return;

    _cameraController!.startImageStream((CameraImage image) {
      _lastFrameAt = DateTime.now();
      final now = DateTime.now();
      if (_isBusy) return;
      if (now.difference(_lastProcessedAt) < _minProcessInterval) return;
      _isBusy = true;
      _lastProcessedAt = now;
      _processCameraImage(image);
    });

    setState(() {});
  }

  Future<void> _restartCamera() async {
    try { await _cameraController?.stopImageStream(); } catch (_) {}
    await _cameraController?.dispose();
    _cameraController = null;
    await _startCamera();
  }

  int _deviceOrientationToDegrees(DeviceOrientation o) {
    switch (o) {
      case DeviceOrientation.portraitUp: return 0;
      case DeviceOrientation.landscapeLeft: return 90;
      case DeviceOrientation.portraitDown: return 180;
      case DeviceOrientation.landscapeRight: return 270;
    }
  }

  InputImageRotation _computeInputImageRotation() {
    final sensor = _cameraController!.description.sensorOrientation;
    final device = _cameraController!.value.deviceOrientation;
    final devDeg = _deviceOrientationToDegrees(device);
    int rotDeg;
    if (_cameraController!.description.lensDirection == CameraLensDirection.front) {
      rotDeg = (sensor + devDeg) % 360;
    } else {
      rotDeg = (sensor - devDeg + 360) % 360;
    }
    return InputImageRotationValue.fromRawValue(rotDeg) ?? InputImageRotation.rotation0deg;
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_shuttingDown) return;
    try {
      final sec = DateTime.now().difference(_warmupStart).inSeconds;
      final warmup = sec < 10;
      // Narration for calibration start/end (once)
      if (warmup && _announceWarmupStart) {
        _announceWarmupStart = false;
        unawaited(_narrator.speak("Hold still. Calibrating for ten seconds."));
      } else if (!warmup && !_announceWarmupEnd) {
        _announceWarmupEnd = true;
        unawaited(_narrator.speak("Calibration complete. Monitoring started."));
      }

      final rotation = _computeInputImageRotation();

      // IMPORTANT: Map to formats ML Kit supports explicitly (avoid yuv420 which may not be accepted)
      final inputFormat = Platform.isAndroid ? InputImageFormat.nv21 : InputImageFormat.bgra8888;

      // Auto-brightness guidance: estimate luminance from Y plane (Android NV21) or BGRA
      try {
        double avgY;
        if (Platform.isAndroid && image.format.group == ImageFormatGroup.nv21) {
          final yPlane = image.planes[0].bytes;
          int sum = 0;
          const step = 200; // subsample for speed
          for (int i = 0; i < yPlane.length; i += step) {
            sum += yPlane[i];
          }
          avgY = sum / (yPlane.length / step);
        } else if (Platform.isIOS && image.format.group == ImageFormatGroup.bgra8888) {
          final bgra = image.planes[0].bytes; // BGRA
          int sum = 0;
          int count = 0;
          const step = 4 * 120; // skip pixels
          for (int i = 0; i < bgra.length; i += step) {
            final b = bgra[i];
            final g = bgra[i + 1];
            final r = bgra[i + 2];
            final y = (0.299 * r + 0.587 * g + 0.114 * b).toInt();
            sum += y;
            count++;
          }
          avgY = count == 0 ? 255 : sum / count;
        } else {
          avgY = 255;
        }
        // Smooth
        _ambientYAvg = _ambientYAvg == null ? avgY : (0.7 * _ambientYAvg! + 0.3 * avgY);
        if ((_ambientYAvg ?? 255) < 40) {
          _lowLightCounter++;
        } else {
          _lowLightCounter = 0;
        }
      } catch (_) {}

      // Concatenate planes for ML Kit
      final bytes = WriteBuffer();
      for (final plane in image.planes) {
        bytes.putUint8List(plane.bytes);
      }
      final allBytes = bytes.done().buffer.asUint8List();

      // Build InputImage with the older 'metadata' signature (your package version)
      final inputImage = InputImage.fromBytes(
        bytes: allBytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: inputFormat,
          bytesPerRow: image.planes.first.bytesPerRow,
        ),
      );

      _inputImageSize = Size(image.width.toDouble(), image.height.toDouble());

      final faces = await _detector.process(inputImage);

      if (faces.isEmpty) {
        _drowsiness.reset();
        _dizzy.reset();
        // End any ongoing drowsy bout on face lost
        if (_drowsyOngoing) {
          _endDrowsyBout(endTime: DateTime.now(), stateMsg: 'Face lost');
        }
        if (_sessionActive()) {
          _session.pushAttention(_attention.score);
        }
        if (mounted) {
          setState(() {
            _status = warmup ? "Calibrating..." : "No face detected";
            _faces = const [];
            _lastHeadAngleDeg = null;
            _lastBpm = null;
          });
        }
        return;
      }

      final face = faces.first;
      final state = _drowsiness.update(face);

      _lastHeadAngleDeg = state.headAngleDeg ?? 0.0;
      _dizzy.push(headRollDeg: _lastHeadAngleDeg!, gyro: null);
      final dizzyScore = _dizzy.score();
      final now = DateTime.now();
      final onCooldown = _lastDizzyAlertAt != null && now.difference(_lastDizzyAlertAt!).inSeconds < 15;
      final dizzyAlert = !warmup && !onCooldown && dizzyScore >= AppConstants.dizzinessAlertScore;

      // ------- Drowsy bout handling (one record per bout, one alert per bout) -------
      if (!warmup && state.type == AlertType.drowsy && state.alert) {
        if (!_drowsyOngoing) {
          _drowsyOngoing = true;
          _drowsyStartAt = now;
          _drowsyAlertedThisBout = false;
        }
        // Play drowsy alert only once per bout
        if (!_drowsyAlertedThisBout) {
          _alert.play(AlertType.drowsy);
          _drowsyAlertedThisBout = true;
          if (_sessionActive()) {
            _session.onAlert(isDrowsy: true);
          }
        }
      } else if (_drowsyOngoing && state.type != AlertType.drowsy) {
        // Eyes reopened — end the drowsy bout and record a single event with duration
        _endDrowsyBout(endTime: now, stateMsg: state.message);
      }
      // ------- End drowsy bout handling -------

      // Play and record non-drowsy alerts as usual (head tilt / dizziness)
      if (!warmup && (dizzyAlert || (state.alert && state.type == AlertType.headTilt))) {
        final isTilt = state.type == AlertType.headTilt && !dizzyAlert;
        final type = dizzyAlert ? AlertType.headTilt : AlertType.headTilt;
        _alert.play(type);
        if (_sessionActive()) {
          _session.onAlert(isDrowsy: false);
        }
        HiveDatabase.addRecord(DrowsinessRecord(
          timestamp: now,
          type: dizzyAlert ? 'Dizziness' : 'HeadTilt',
          message: dizzyAlert ? '⚠️ Possible dizziness detected' : state.message,
          headAngle: state.headAngleDeg,
          blinkCount: state.blinksPerMinute,
        ));
        if (dizzyAlert) {
          _lastDizzyAlertAt = now;
        }
      } else if (!(_drowsyOngoing && _drowsyAlertedThisBout)) {
        // If not in drowsy bout or drowsy alert already played, ensure alert is stopped
        _alert.stop();
      }

      // -------- Yawn detection (record only; no alarms) --------
      if (!warmup) {
        final ratio = _estimateMouthOpenRatio(face);
        if (ratio != null) {
          if (ratio >= _yawnOpenThreshold) {
            _yawnStartAt ??= now;
            final held = now.difference(_yawnStartAt!).inSeconds;
            final cooldownOk = _lastYawnAt == null || now.difference(_lastYawnAt!).inSeconds >= _yawnCooldownSeconds;
            if (held >= _yawnHoldSeconds && cooldownOk) {
              await HiveDatabase.addRecord(DrowsinessRecord(
                timestamp: now,
                type: 'Yawn',
                message: 'Yawn detected',
                headAngle: state.headAngleDeg,
                blinkCount: state.blinksPerMinute,
              ));
              _lastYawnAt = now;
              // keep _yawnStartAt while mouth remains open; reset when below hysteresis threshold
            }
          } else if (ratio <= _yawnCloseThreshold) {
            _yawnStartAt = null;
          }
        }
      }
      // -------- End Yawn detection --------

      // Update attention and session stats
      final attState = dizzyAlert
          ? const DrowsinessState(type: AlertType.dizziness, message: "", alert: true)
          : state;
      _attention.update(attState);
      if (_sessionActive()) {
        _session.pushAttention(_attention.score);
      }

      if (mounted) {
        setState(() {
          _faces = faces;
          _status = warmup
              ? "Calibrating..."
              : (dizzyAlert ? "⚠️ Possible dizziness" : state.message);
        });
      }
    } catch (e) {
      debugPrint('Error processing camera image: $e');
    } finally {
      _isBusy = false;
    }
  }

  void _toggleSession() {
    HapticFeedback.selectionClick();
    if (_session.active.value) {
      _session.stop();
      _showSessionSummary();
    } else {
      _session.start();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session started')),
      );
    }
    setState(() {});
  }

  void _showSessionSummary() {
    final s = _session.current.value;
    if (s == null) return;
    final duration = (s.end ?? DateTime.now()).difference(s.start);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Session Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Duration: ${duration.inMinutes}m ${duration.inSeconds % 60}s'),
              Text('Alerts: ${s.alerts}  (Drowsy: ${s.drowsy}, Head Tilt: ${s.headTilt})'),
              const SizedBox(height: 12),
              const Text('Attention Trend'),
              const SizedBox(height: 6),
              SizedBox(
                height: 80,
                width: double.infinity,
                child: Sparkline(data: List<double>.from(s.attentionHistory)),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_shuttingDown) return;
    if (state == AppLifecycleState.paused) {
      _cameraController?.stopImageStream();
    } else if (state == AppLifecycleState.resumed) {
      _cameraController?.startImageStream((image) {
        _lastFrameAt = DateTime.now();
        final now = DateTime.now();
        if (_isBusy) return;
        if (now.difference(_lastProcessedAt) < _minProcessInterval) return;
        _isBusy = true;
        _lastProcessedAt = now;
        _processCameraImage(image);
      });
    }
  }

  Future<void> _onSnooze() async {
    HapticFeedback.lightImpact();
    await _alert.snooze(seconds: 120);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Alerts snoozed for 2 minutes')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.deepPurpleAccent)),
      );
    }

    final previewSize = _cameraController!.value.previewSize!;
    final isFront = _cameraController!.description.lensDirection == CameraLensDirection.front;
    // IMPORTANT: use the controller's preview dimensions (rotated) for consistent overlay mapping
    final overlayImageSize = Size(previewSize.height, previewSize.width);
    final warmupLeft = (10 - DateTime.now().difference(_warmupStart).inSeconds).clamp(0, 10);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("AI Driver Monitoring"),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: _shadeOn ? 'Wake screen' : 'Screen shade',
            icon: Icon(_shadeOn ? Icons.visibility : Icons.visibility_off),
            onPressed: _toggleShade,
          ),
          IconButton(
            tooltip: 'Snooze alerts (2 min)',
            icon: const Icon(Icons.notifications_off_rounded),
            onPressed: _onSnooze,
          ),
          IconButton(
            tooltip: 'Start session',
            icon: Icon(_session.active.value ? Icons.stop_circle_rounded : Icons.play_circle_rounded),
            onPressed: _toggleSession,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Attention meter
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: AttentionMeter(score: _attention.score),
          ),
          Center(
            child: AspectRatio(
              aspectRatio: previewSize.height / previewSize.width,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CameraPreview(_cameraController!),
                  if (_faces.isNotEmpty)
                    CustomPaint(
                      painter: FacePainter(_faces, overlayImageSize, isFrontCamera: isFront),
                    ),
                ],
              ),
            ),
          ),
          // Low light guidance banner
          if (_lowLight && warmupLeft == 0 && !_shadeOn)
            Positioned(
              top: 48,
              left: 20,
              right: 20,
              child: NeonPanel(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.light_mode, color: Colors.amberAccent),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Low light detected. Consider turning on cabin lights.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          // Calibrating overlay
          if (warmupLeft > 0)
             Positioned.fill(
               child: Container(
                 color: Colors.black.withOpacity(0.5),
                 child: Center(
                  child: NeonPanel(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ProgressRing(totalSeconds: 10, remainingSeconds: warmupLeft, size: 140),
                          const SizedBox(height: 16),
                          const Text(
                            "Calibrating… Hold still",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                 ),
               ),
             ),
          // Screen shade overlay
          if (_shadeOn)
            Positioned.fill(
              child: GestureDetector(
                onTap: _toggleShade,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  color: Colors.black,
                  alignment: Alignment.center,
                  child: const Text(
                    'Screen shaded\nTap to wake',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54, fontSize: 16),
                  ),
                ),
              ),
            ),
          Positioned(
             bottom: 40,
             left: 20,
             right: 20,
             child: Center(
              child: NeonPanel(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  child: Text(
                    _status,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
             ),
           ),
        ],
      ),
    );
  }

  // Estimate mouth opening ratio using lip contours; return null if contours unavailable.
  // Returns vertical mouth gap divided by face height (0..~0.2).
  double? _estimateMouthOpenRatio(Face face) {
    try {
      // Use lip contours for reliable mouth opening measurement
      final upperLipTop = face.contours[FaceContourType.upperLipTop];
      final lowerLipBottom = face.contours[FaceContourType.lowerLipBottom];
      if (upperLipTop == null ||
          lowerLipBottom == null ||
          upperLipTop.points.isEmpty ||
          lowerLipBottom.points.isEmpty) {
        // Contours not available in this frame or detector config
        return null;
      }
      // Sample roughly the center points of each contour
      final i = upperLipTop.points.length ~/ 2;
      final j = lowerLipBottom.points.length ~/ 2;
      final up = upperLipTop.points[i];
      final low = lowerLipBottom.points[j];
      final gap = (low.y - up.y).abs();
      final faceH = face.boundingBox.height.toDouble().clamp(1.0, double.infinity);
      return gap / faceH;
    } catch (_) {
      return null;
    }
  }

  void _endDrowsyBout({required DateTime endTime, required String stateMsg}) {
    if (!_drowsyOngoing || _drowsyStartAt == null) return;
    final dur = endTime.difference(_drowsyStartAt!).inSeconds;
    _drowsyOngoing = false;
    _drowsyStartAt = null;
    _drowsyAlertedThisBout = false;
    _drowsyBouts += 1;
    final reopened = TimeOfDay.fromDateTime(endTime).format(context);
    HiveDatabase.addRecord(DrowsinessRecord(
      timestamp: endTime,
      type: 'Drowsy',
      message: 'Drowsy for ${dur}s • eyes reopened at $reopened',
      headAngle: _lastHeadAngleDeg,
      blinkCount: null,
    ));
    // Escalate if repeated drowsiness
    if (_drowsyBouts >= _repeatDrowsyEscalate) {
      _escalateRepeatedDrowsy();
    }
  }

  void _escalateRepeatedDrowsy() {
    // Narrator prompt and louder feedback
    unawaited(_narrator.speak("Repeated drowsiness detected. Please pull over to the side for safety."));
    // Optional: flash an in-app warning
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Safety Warning'),
        content: const Text('Repeated drowsiness detected. Please pull over safely and rest.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }
}