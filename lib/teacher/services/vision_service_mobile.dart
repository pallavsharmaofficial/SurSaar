import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/widgets.dart';

import '../models/hand_frame.dart';
import 'vision_service.dart';

VisionService createPlatformVisionService() => MobileVisionService();

/// Camera preview through the `camera` plugin. Hand landmarks are not
/// produced on mobile yet; the engine degrades gracefully (audio-only
/// coaching plus the chord diagram).
class MobileVisionService implements VisionService {
  final StreamController<HandFrame> _controller =
      StreamController<HandFrame>.broadcast();
  CameraController? _camera;
  bool _running = false;
  String? _lastError;

  @override
  bool get supportsPreview => true;

  @override
  bool get supportsHandTracking => false;

  @override
  bool get isRunning => _running;

  @override
  String? get lastError => _lastError;

  @override
  Stream<HandFrame> get frames => _controller.stream;

  @override
  Future<void> start({bool frontCamera = true, bool mirror = true}) async {
    if (_running) return;
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _lastError = 'No camera found on this device.';
        return;
      }
      final wanted = frontCamera
          ? CameraLensDirection.front
          : CameraLensDirection.back;
      final camera = cameras.firstWhere(
        (c) => c.lensDirection == wanted,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await controller.initialize();
      _camera = controller;
      _running = true;
      _lastError = null;
    } catch (error) {
      _lastError = 'Camera unavailable: $error';
      _running = false;
    }
  }

  @override
  Future<void> stop() async {
    _running = false;
    final camera = _camera;
    _camera = null;
    await camera?.dispose();
  }

  @override
  Widget buildPreview(BuildContext context) {
    final camera = _camera;
    if (camera == null || !camera.value.isInitialized) {
      return const SizedBox.expand();
    }
    return FittedBox(
      fit: BoxFit.cover,
      clipBehavior: Clip.hardEdge,
      child: SizedBox(
        width: camera.value.previewSize?.height ?? 480,
        height: camera.value.previewSize?.width ?? 640,
        child: CameraPreview(camera),
      ),
    );
  }

  @override
  Future<void> dispose() async {
    await stop();
    await _controller.close();
  }
}
