import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'dart:ui' as ui;

class FacePainter extends CustomPainter {
  final List<Face> faces;
  final Size imageSize;
  final bool isFrontCamera;
  FacePainter(this.faces, this.imageSize, {this.isFrontCamera = true});

  @override
  void paint(Canvas canvas, Size size) {
    // Scale factors from input image to canvas
    final sx = size.width / imageSize.width;
    final sy = size.height / imageSize.height;

    // Base paints
    final boxPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const ui.Color(0xFF00FFFF).withOpacity(0.85);
    final eyePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const ui.Color(0xFF7C4DFF).withOpacity(0.95);

    // Map a point-like object (with x, y) to an Offset on the canvas
    Offset _toOffset(dynamic p) {
      final double x = (p.x as num).toDouble();
      final double y = (p.y as num).toDouble();
      final double xMirrored = isFrontCamera ? (imageSize.width - x) : x;
      return Offset(xMirrored * sx, y * sy);
    }

    for (final f in faces) {
      // Draw face bounding box
      final rect = f.boundingBox;
      final left = isFrontCamera ? (imageSize.width - rect.right) * sx : rect.left * sx;
      final top = rect.top * sy;
      final right = isFrontCamera ? (imageSize.width - rect.left) * sx : rect.right * sx;
      final bottom = rect.bottom * sy;
      final r = RRect.fromRectAndRadius(Rect.fromLTRB(left, top, right, bottom), const Radius.circular(10));
      canvas.drawRRect(r, boxPaint);

      // Draw eye contours if available; fallback to small circles at eye landmarks
      final leftEye = f.contours[FaceContourType.leftEye];
      final rightEye = f.contours[FaceContourType.rightEye];

      if (leftEye != null && leftEye.points.isNotEmpty) {
        final pts = leftEye.points.map<Offset>((pt) => _toOffset(pt)).toList(growable: false);
        final path = Path()..addPolygon(pts, true);
        canvas.drawPath(path, eyePaint);
      } else {
        final lm = f.landmarks[FaceLandmarkType.leftEye]?.position;
        if (lm != null) canvas.drawCircle(_toOffset(lm), 6, eyePaint);
      }

      if (rightEye != null && rightEye.points.isNotEmpty) {
        final pts = rightEye.points.map<Offset>((pt) => _toOffset(pt)).toList(growable: false);
        final path = Path()..addPolygon(pts, true);
        canvas.drawPath(path, eyePaint);
      } else {
        final lm = f.landmarks[FaceLandmarkType.rightEye]?.position;
        if (lm != null) canvas.drawCircle(_toOffset(lm), 6, eyePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant FacePainter oldDelegate) =>
      oldDelegate.faces != faces || oldDelegate.imageSize != imageSize || oldDelegate.isFrontCamera != isFrontCamera;
}