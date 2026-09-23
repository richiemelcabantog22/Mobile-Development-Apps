import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

double? averageEyeOpenProbability(Face face) {
  final left = face.leftEyeOpenProbability;
  final right = face.rightEyeOpenProbability;
  if (left == null || right == null) return null;
  return (left + right) / 2.0;
}