import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../core/constants.dart';
import '../services/settings_service.dart';
import 'perclos_service.dart';

enum AlertType { none, drowsy, headTilt, fatigue, yawn, dizziness }

class DrowsinessState {
  final AlertType type;
  final String message;
  final bool alert;
  final double? headAngleDeg;
  final int? blinksPerMinute;
  final double? perclos;
  final double? ear;
  final double? mar;
  final double? dizziness;

  const DrowsinessState({
    required this.type,
    required this.message,
    required this.alert,
    this.headAngleDeg,
    this.blinksPerMinute,
    this.perclos,
    this.ear,
    this.mar,
    this.dizziness,
  });

  static const monitoring = DrowsinessState(type: AlertType.none, message: "Monitoring...", alert: false);
}

class DrowsinessService {
  final PerclosService _perclos = PerclosService();
  DateTime? _eyesClosedSince;

  // Simple MAR (mouth open) from contours if available
  double? _mar(Face face) {
    final upper = face.contours[FaceContourType.upperLipBottom]?.points;
    final lower = face.contours[FaceContourType.lowerLipTop]?.points;
    final leftCorner = face.landmarks[FaceLandmarkType.leftMouth]?.position;
    final rightCorner = face.landmarks[FaceLandmarkType.rightMouth]?.position;
    if (upper == null || lower == null || leftCorner == null || rightCorner == null) return null;
    // vertical gap (average center)
    final midY1 = upper.fold<double>(0.0, (a, p) => a + p.y) / upper.length;
    final midY2 = lower.fold<double>(0.0, (a, p) => a + p.y) / lower.length;
    final vert = (midY2 - midY1).abs();
    final horiz = (rightCorner.x - leftCorner.x).abs();
    if (horiz == 0) return null;
    return vert / horiz;
  }

  DrowsinessState update(Face face) {
    final cfg = SettingsService.isInitialized ? SettingsService.instance.current : SettingsService.instance.current;

    // Eye open probability (0..1)
    final l = face.leftEyeOpenProbability;
    final r = face.rightEyeOpenProbability;
    double? avgProb = (l != null && r != null) ? (l + r) / 2.0 : (l ?? r);

    // Head roll (Z) in degrees (right tilt positive)
    final headRoll = face.headEulerAngleZ ?? 0.0;

    final mar = _mar(face);

    final eyesClosed = (avgProb != null) ? (avgProb < cfg.eyeClosedThreshold) : false;
    _perclos.push(eyesClosed: eyesClosed);
    final perclosVal = _perclos.perclos(null);

    // Head tilt alert
    if (headRoll.abs() > cfg.headTiltThresholdDeg) {
      return DrowsinessState(
        type: AlertType.headTilt,
        message: "⚠️ Head Tilt Detected",
        alert: true,
        headAngleDeg: headRoll,
        perclos: perclosVal,
        ear: null,
        mar: mar,
      );
    }

    // Yawn hint (MAR heuristic)
    if (mar != null && mar > 0.5) {
      return DrowsinessState(
        type: AlertType.yawn,
        message: "Possible yawn detected",
        alert: false,
        headAngleDeg: headRoll,
        perclos: perclosVal,
        ear: null,
        mar: mar,
      );
    }

    // Continuous closure
    final now = DateTime.now();
    if (eyesClosed) {
      _eyesClosedSince ??= now;
      final closedMs = now.difference(_eyesClosedSince!).inMilliseconds;
      if (closedMs >= cfg.eyeClosedDurationMs) {
        return DrowsinessState(
          type: AlertType.drowsy,
          message: "⚠️ Drowsy Driver Detected",
          alert: true,
          headAngleDeg: headRoll,
          perclos: perclosVal,
          ear: null,
          mar: mar,
        );
      }
      return DrowsinessState(
        type: AlertType.none,
        message: "Eyes closed (${closedMs}ms)...",
        alert: false,
        headAngleDeg: headRoll,
        perclos: perclosVal,
        ear: null,
        mar: mar,
      );
    } else {
      _eyesClosedSince = null;
    }

    // PERCLOS warning
    if (perclosVal >= AppConstants.perclosAlertThreshold) {
      return DrowsinessState(
        type: AlertType.fatigue,
        message: "⚠️ High PERCLOS (${(perclosVal * 100).toStringAsFixed(0)}%)",
        alert: false,
        headAngleDeg: headRoll,
        perclos: perclosVal,
        ear: null,
        mar: mar,
      );
    }

    return const DrowsinessState(
      type: AlertType.none,
      message: "Driver is Alert",
      alert: false,
    );
  }

  void reset() {
    _perclos.reset();
    _eyesClosedSince = null;
  }
}