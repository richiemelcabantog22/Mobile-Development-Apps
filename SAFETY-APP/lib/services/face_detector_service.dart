import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceDetectorService {
  // Enable contours to draw eyes and detect mouth opening for yawns
  final FaceDetector _detector = FaceDetector(
    options: FaceDetectorOptions(
      enableTracking: true,
      performanceMode: FaceDetectorMode.accurate,
      enableClassification: true,
      enableLandmarks: true,
      enableContours: true,
    ),
  );

  Future<List<Face>> process(InputImage image) => _detector.processImage(image);

  Future<void> dispose() => _detector.close();
}