import 'package:flutter/widgets.dart';

import '../models/hand_frame.dart';
import 'vision_service_stub.dart'
    if (dart.library.io) 'vision_service_mobile.dart'
    if (dart.library.js_interop) 'vision_service_web.dart';

/// Camera preview + hand landmark stream.
///
/// * Web: MediaPipe Hand Landmarker via JS interop (full AR guidance).
/// * Android / iOS: camera preview via the `camera` plugin; hand tracking
///   is not wired yet (see docs/TEACHER_ENGINE.md), so overlays fall back
///   to the chord diagram.
/// * Everything else: no camera.
abstract class VisionService {
  bool get supportsPreview;
  bool get supportsHandTracking;
  bool get isRunning;
  String? get lastError;

  Stream<HandFrame> get frames;

  Future<void> start({bool frontCamera = true, bool mirror = true});

  Future<void> stop();

  Widget buildPreview(BuildContext context);

  Future<void> dispose();
}

VisionService createVisionService() => createPlatformVisionService();
