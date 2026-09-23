import 'package:camera/camera.dart';

class CameraService {
  CameraController? controller;

  Future<void> init() async {
    final cameras = await availableCameras();
    final front = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    controller = CameraController(
      front,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );
    await controller!.initialize();
  }

  void startStream(void Function(CameraImage) onImage) {
    controller?.startImageStream(onImage);
  }

  void dispose() {
    controller?.dispose();
  }
}