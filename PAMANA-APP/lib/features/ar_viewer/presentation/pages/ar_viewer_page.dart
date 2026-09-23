import 'package:flutter/material.dart';
import 'package:ar_flutter_plugin_plus/widgets/ar_view.dart';
import 'package:ar_flutter_plugin_plus/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin_plus/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin_plus/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin_plus/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin_plus/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin_plus/models/ar_node.dart';
import 'package:ar_flutter_plugin_plus/models/ar_anchor.dart';
import 'package:ar_flutter_plugin_plus/models/ar_hittest_result.dart';
import 'package:ar_flutter_plugin_plus/datatypes/node_types.dart';
import 'package:vector_math/vector_math_64.dart' as vector;
import '../../../../models/folklore_creature.dart';
import 'dart:io' show Platform;
import 'model_viewer_page.dart';
import '../../../../services/user_progress_service.dart';

class ARViewerPage extends StatefulWidget {
  final FolkloreCreature creature;
  const ARViewerPage({super.key, required this.creature});

  @override
  State<ARViewerPage> createState() => _ARViewerPageState();
}

class _ARViewerPageState extends State<ARViewerPage> {
  late ARSessionManager _arSessionManager;
  late ARObjectManager _arObjectManager;
  late ARAnchorManager _arAnchorManager;
  ARNode? _modelNode;
  ARPlaneAnchor? _planeAnchor;
  final Stopwatch _arSw = Stopwatch();

  bool _placed = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('AR: ${widget.creature.name}')),
      body: Stack(
        children: [
          ARView(
            planeDetectionConfig: PlaneDetectionConfig.horizontalAndVertical,
            onARViewCreated: _onARViewCreated,
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: _InstructionBanner(placed: _placed),
          ),
        ],
      ),
      floatingActionButton: _placed
          ? FloatingActionButton.extended(
              onPressed: () async {
                await _removeModelAndAnchor();
                setState(() => _placed = false);
              },
              label: const Text('Reset'),
              icon: const Icon(Icons.refresh),
            )
          : null,
    );
  }

  Future<void> _onARViewCreated(
    ARSessionManager arSessionManager,
    ARObjectManager arObjectManager,
    ARAnchorManager arAnchorManager,
    ARLocationManager arLocationManager,
  ) async {
    _arSessionManager = arSessionManager;
    _arObjectManager = arObjectManager;
    _arAnchorManager = arAnchorManager;

    // If device is not Android/iOS, or AR init fails, fallback to 3D viewer.
    if (!(Platform.isAndroid || Platform.isIOS)) {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => ModelViewerPage(creature: widget.creature)),
        );
      }
      return;
    }

    try {
      await _arSessionManager.onInitialize(
        showFeaturePoints: false,
        showPlanes: true,
        showWorldOrigin: false,
        handleTaps: true,
      );
      await _arObjectManager.onInitialize();

      _arSessionManager.onPlaneOrPointTap = _onPlaneTap;

      // Start AR learning timer once AR session initialized
      _arSw.start();
    } catch (e) {
      // AR not available (MissingPluginException / ARCore not installed / unsupported device)
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => ModelViewerPage(creature: widget.creature)),
        );
      }
    }
  }

  Future<void> _onPlaneTap(List<ARHitTestResult> hits) async {
    if (_placed || hits.isEmpty) return;

    final hit = hits.first;
    final anchor = ARPlaneAnchor(transformation: hit.worldTransform);
    final didAddAnchor = await _arAnchorManager.addAnchor(anchor);
    if (didAddAnchor != true) return;

    _planeAnchor = anchor;

    final node = ARNode(
      type: NodeType.localGLTF2,
      uri: widget.creature.modelPath, // e.g., assets/models/tikbalang.glb
      // If your model has a custom scale property, replace 0.2 with it.
      scale: vector.Vector3.all(0.2),
      position: vector.Vector3.zero(),
      rotation: vector.Vector4(0, 0, 0, 1),
    );

    final didAddNode = await _arObjectManager.addNode(node, planeAnchor: anchor);
    if (didAddNode == true) {
      setState(() {
        _modelNode = node;
        _placed = true;
      });
    }
  }

  @override
  void dispose() {
    _removeModelAndAnchor();
    // Some versions only expose dispose on session manager; ignore if already torn down.
    try {
      _arSessionManager.dispose();
    } catch (_) {}
    // Track AR learning time if session started
    if (_arSw.isRunning || _arSw.elapsedMilliseconds > 0) {
      _arSw.stop();
      UserProgressService.instance.addLearningTime(_arSw.elapsed, source: 'ar_viewer');
      UserProgressService.instance.markDiscovered(widget.creature.id);
    }
    super.dispose();
  }

  Future<void> _removeModelAndAnchor() async {
    if (_modelNode != null) {
      await _arObjectManager.removeNode(_modelNode!);
      _modelNode = null;
    }
    if (_planeAnchor != null) {
      await _arAnchorManager.removeAnchor(_planeAnchor!);
      _planeAnchor = null;
    }
  }
}

class _InstructionBanner extends StatelessWidget {
  final bool placed;
  const _InstructionBanner({required this.placed});

  @override
  Widget build(BuildContext context) {
    final text = placed
        ? 'Model placed. Pinch to zoom, drag to move, rotate with two fingers.'
        : 'Move your device to detect a surface, then tap to place the model.';
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          text,
          style: const TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}