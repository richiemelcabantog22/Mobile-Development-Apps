import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

double headRollAngleDeg(Face face) {
  return (face.headEulerAngleZ ?? 0.0).toDouble();
}