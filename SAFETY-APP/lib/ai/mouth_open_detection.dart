import 'dart:math';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

double _medianY(List<Point<int>> pts) {
  if (pts.isEmpty) return 0.0;
  final ys = pts.map((p) => p.y).toList()..sort();
  final mid = ys.length ~/ 2;
  if (ys.length.isOdd) {
    return ys[mid].toDouble();
  } else {
    return ((ys[mid - 1] + ys[mid]) / 2).toDouble();
  }
}

double? _medianYFromContour(Face face, FaceContourType type) {
  final pts = face.contours[type]?.points;
  if (pts == null || pts.isEmpty) return null;
  return _medianY(pts);
}

double? mouthOpeningRatio(Face face) {
  // Prefer upperLipBottom vs lowerLipTop; fall back if missing
  final upperY =
      _medianYFromContour(face, FaceContourType.upperLipBottom) ??
      _medianYFromContour(face, FaceContourType.upperLipTop);

  final lowerY =
      _medianYFromContour(face, FaceContourType.lowerLipTop) ??
      _medianYFromContour(face, FaceContourType.lowerLipBottom);

  if (upperY == null || lowerY == null) return null;

  final gap = (lowerY - upperY).abs();

  // Normalize by face height to be scale-invariant
  final faceHeight = face.boundingBox.height <= 0 ? 1.0 : face.boundingBox.height;
  return gap / faceHeight;
}

bool isYawn(Face face, {double threshold = 0.10}) {
  final ratio = mouthOpeningRatio(face);
  if (ratio == null) return false;
  return ratio >= threshold;
}