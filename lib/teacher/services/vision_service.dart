import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../models/hand_frame.dart';
import 'vision_service_stub.dart'
    if (dart.library.io) 'vision_service_mobile.dart'
    if (dart.library.js_interop) 'vision_service_web.dart';

/// State of the hand-tracking model.
enum TrackingStatus { unavailable, idle, loading, ready, error }

/// Camera preview + hand landmark stream.
///
/// * Web: MediaPipe Hand Landmarker in a Web Worker (full AR guidance).
/// * Android / iOS: camera preview via the `camera` plugin; hand tracking
///   is not wired yet, so the teacher coaches by ear and shows diagrams.
abstract class VisionService {
  bool get supportsPreview;
  bool get supportsHandTracking;
  bool get isRunning;
  String? get lastError;

  ValueListenable<TrackingStatus> get trackingStatus;

  Stream<HandFrame> get frames;

  /// Downloads and prepares hand tracking without touching the camera.
  Future<void> warmUp();

  Future<void> start({bool frontCamera = true, bool mirror = true});

  Future<void> stop();

  /// The preview. On the web it can stay mounted for the whole screen.
  Widget buildPreview(BuildContext context);

  Future<void> dispose();
}

VisionService createVisionService() => createPlatformVisionService();
