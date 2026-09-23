import 'dart:math';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

double _distance(Point<int> a, Point<int> b) {
  final dx = (a.x - b.x).toDouble();
  final dy = (a.y - b.y).toDouble();
  return sqrt(dx * dx + dy * dy);
}

// Compute simplified EAR from eye contour points (uses vertical span / horizontal span)
double? eyeAspectRatio(Face face, {required bool left}) {
  final type = left ? FaceContourType.leftEye : FaceContourType.rightEye;
  final pts = face.contours[type]?.points;
  if (pts == null || pts.length < 6) return null;

  // Approximate: vertical = distance between top-most and bottom-most points
  final top = pts.reduce((a, b) => a.y < b.y ? a : b);
  final bottom = pts.reduce((a, b) => a.y > b.y ? a : b);
  // Horizontal = distance between left-most and right-most
  final leftPt = pts.reduce((a, b) => a.x < b.x ? a : b);
  final rightPt = pts.reduce((a, b) => a.x > b.x ? a : b);

  final vert = _distance(top, bottom);
  final horiz = _distance(leftPt, rightPt);
  if (horiz == 0) return null;
  return (vert / horiz).clamp(0.0, 1.0);
}

// Compute MAR (mouth aspect ratio) using lip contours
double? mouthAspectRatio(Face face) {
  final upper = face.contours[FaceContourType.upperLipBottom]?.points ??
      face.contours[FaceContourType.upperLipTop]?.points;
  final lower = face.contours[FaceContourType.lowerLipTop]?.points ??
      face.contours[FaceContourType.lowerLipBottom]?.points;

  if (upper == null || lower == null || upper.isEmpty || lower.isEmpty) return null;

  // Vertical: median Y gap
  final upY = (upper.map((p) => p.y).reduce((a, b) => a + b) / upper.length);
  final loY = (lower.map((p) => p.y).reduce((a, b) => a + b) / lower.length);
  final vert = (loY - upY).abs().toDouble();

  // Horizontal: width between mouth corners if available (fallback to overall bounding)
  final all = [...upper, ...lower];
  final leftPt = all.reduce((a, b) => a.x < b.x ? a : b);
  final rightPt = all.reduce((a, b) => a.x > b.x ? a : b);
  final horiz = (rightPt.x - leftPt.x).abs().toDouble();
  if (horiz == 0) return null;
  return (vert / horiz).clamp(0.0, 1.0);
}
