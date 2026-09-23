import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../services/face_detector_service.dart';
import '../widgets/neon_panel.dart';

class DiagnosticsScreen extends StatefulWidget {
  const DiagnosticsScreen({super.key});

  @override
  State<DiagnosticsScreen> createState() => _DiagnosticsScreenState();
}

class _DiagnosticsScreenState extends State<DiagnosticsScreen> {
  String _cameraStatus = 'Checking…';
  String _mlkitStatus = 'Checking…';
  bool? _cameraPassed; // null=unknown, true=ok, false=error
  bool? _mlkitPassed;
  bool _isCameraTesting = false;
  bool _isMlkitChecking = false;

  // Top banner helper to avoid off-screen SnackBar issues
  void _showBanner({
    required String message,
    required Color color,
    required IconData icon,
    int ms = 2000,
  }) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearMaterialBanners();
    messenger.showMaterialBanner(
      MaterialBanner(
        backgroundColor: color.withOpacity(0.9),
        leading: Icon(icon, color: Colors.white),
        content: Text(message, style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => messenger.hideCurrentMaterialBanner(),
            child: const Text('DISMISS', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    Future.delayed(Duration(milliseconds: ms), () {
      if (mounted) messenger.hideCurrentMaterialBanner();
    });
  }

  @override
  void initState() {
    super.initState();
    _checkCamera();
    _checkMLKit();
  }

  Future<void> _checkCamera() async {
    setState(() {
      _isCameraTesting = true;
      _cameraStatus = 'Checking…';
      _cameraPassed = null;
    });
    try {
      final cams = await availableCameras();
      final hasFront = cams.any((c) => c.lensDirection == CameraLensDirection.front);
      setState(() {
        _cameraStatus = hasFront ? 'Front camera available' : 'Front camera not found';
        _cameraPassed = hasFront;
      });
      _showBanner(
        message: hasFront ? 'Front camera detected' : 'Front camera not found',
        color: hasFront ? Colors.green : Colors.red,
        icon: hasFront ? Icons.check_circle_rounded : Icons.error_rounded,
      );
    } catch (e) {
      setState(() {
        _cameraStatus = 'Camera error: $e';
        _cameraPassed = false;
      });
      _showBanner(
        message: 'Camera error: $e',
        color: Colors.red,
        icon: Icons.error_rounded,
        ms: 3000,
      );
    } finally {
      setState(() => _isCameraTesting = false);
    }
  }

  Future<void> _checkMLKit() async {
    setState(() {
      _isMlkitChecking = true;
      _mlkitStatus = 'Checking…';
      _mlkitPassed = null;
    });
    try {
      final detector = FaceDetectorService();
      await detector.dispose();
      setState(() {
        _mlkitStatus = 'ML Kit Face Detector available';
        _mlkitPassed = true;
      });
      _showBanner(
        message: 'ML Kit test successful',
        color: Colors.green,
        icon: Icons.check_circle_rounded,
      );
    } catch (e) {
      setState(() {
        _mlkitStatus = 'ML Kit error: $e';
        _mlkitPassed = false;
      });
      _showBanner(
        message: 'ML Kit test failed',
        color: Colors.red,
        icon: Icons.error_rounded,
        ms: 3000,
      );
    } finally {
      setState(() => _isMlkitChecking = false);
    }
  }

  // Actively open and close the front camera to validate permission and availability with animated feedback.
  Future<void> _runCameraOpenTest() async {
    setState(() {
      _isCameraTesting = true;
      _cameraStatus = 'Opening camera for test…';
      _cameraPassed = null;
    });
    CameraController? controller;
    try {
      final cams = await availableCameras();
      if (cams.isEmpty) {
        setState(() {
          _cameraStatus = 'No cameras detected on device';
          _cameraPassed = false;
        });
        _showBanner(
          message: 'No cameras detected on device',
          color: Colors.red,
          icon: Icons.error_rounded,
          ms: 3000,
        );
        return;
      }
      final cam = cams.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cams.first,
      );
      controller = CameraController(cam, ResolutionPreset.low, enableAudio: false);
      await controller.initialize();
      await controller.dispose();
      setState(() {
        _cameraStatus = 'Camera test passed: opened and closed successfully';
        _cameraPassed = true;
      });
      _showBanner(
        message: 'Camera test successful',
        color: Colors.green,
        icon: Icons.check_circle_rounded,
      );
    } catch (e) {
      try {
        await controller?.dispose();
      } catch (_) {}
      setState(() {
        _cameraStatus = 'Camera test failed: $e';
        _cameraPassed = false;
      });
      _showBanner(
        message: 'Camera test failed',
        color: Colors.red,
        icon: Icons.error_rounded,
        ms: 3000,
      );
    } finally {
      if (mounted) setState(() => _isCameraTesting = false);
    }
  }

  Widget _statusChip({required bool? ok, required String label}) {
    Color bg;
    IconData? icon;
    if (ok == true) {
      bg = Colors.green.withOpacity(0.15);
      icon = Icons.check_circle_rounded;
    } else if (ok == false) {
      bg = Colors.red.withOpacity(0.15);
      icon = Icons.error_rounded;
    } else {
      bg = Colors.amber.withOpacity(0.15);
      icon = Icons.hourglass_top_rounded;
    }
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ok == true
              ? Colors.greenAccent.withOpacity(0.5)
              : ok == false
                  ? Colors.redAccent.withOpacity(0.5)
                  : Colors.amberAccent.withOpacity(0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(icon, key: ValueKey(icon), size: 16, color: Colors.white),
          ),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Diagnostics')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          NeonPanel(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.camera_alt_outlined),
                    title: const Text('Camera'),
                    subtitle: Text(_cameraStatus),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _statusChip(ok: _cameraPassed, label: _cameraPassed == true ? 'Passed' : _cameraPassed == false ? 'Failed' : 'Checking'),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: _isCameraTesting ? null : _runCameraOpenTest,
                        icon: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: _isCameraTesting
                              ? const SizedBox(
                                  key: ValueKey('camload'),
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.play_circle_outline, key: ValueKey('camicon')),
                        ),
                        label: const Text('Run Camera Test'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          NeonPanel(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.memory_outlined),
                    title: const Text('ML Kit'),
                    subtitle: Text(_mlkitStatus),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _statusChip(ok: _mlkitPassed, label: _mlkitPassed == true ? 'Passed' : _mlkitPassed == false ? 'Failed' : 'Checking'),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: _isMlkitChecking ? null : _checkMLKit,
                        icon: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: _isMlkitChecking
                              ? const SizedBox(
                                  key: ValueKey('mlload'),
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.refresh, key: ValueKey('mlicon')),
                        ),
                        label: const Text('Recheck ML Kit'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'If issues persist:\n• Ensure camera permission is granted\n• Restart the app\n• Improve lighting\n• Keep the device steady',
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }
}
