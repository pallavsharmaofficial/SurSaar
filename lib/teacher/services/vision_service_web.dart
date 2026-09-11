import 'dart:async';
import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';

import '../models/hand_frame.dart';
import 'teacher_js.dart';
import 'vision_service.dart';

VisionService createPlatformVisionService() => WebVisionService();

/// Web implementation: camera via getUserMedia + MediaPipe Hand Landmarker,
/// both driven from `web/teacher/sursaar_teacher.js`.
class WebVisionService implements VisionService {
  static const String viewType = 'sursaar-vision-view';
  static bool _factoryRegistered = false;

  final StreamController<HandFrame> _controller =
      StreamController<HandFrame>.broadcast();
  bool _running = false;
  bool _mirror = true;
  String? _lastError;

  @override
  bool get supportsPreview => teacherJsAvailable;

  @override
  bool get supportsHandTracking => teacherJsAvailable;

  @override
  bool get isRunning => _running;

  @override
  String? get lastError => _lastError;

  @override
  Stream<HandFrame> get frames => _controller.stream;

  @override
  Future<void> start({bool frontCamera = true, bool mirror = true}) async {
    if (_running) return;
    if (!teacherJsAvailable) {
      _lastError =
          'Teacher script not loaded (web/teacher/sursaar_teacher.js).';
      return;
    }
    _mirror = mirror && frontCamera;
    _registerFactory();
    teacherJs.setMirror(_mirror.toJS);
    try {
      await teacherJs
          .startVision(frontCamera.toJS, _onFrame.toJS, _onError.toJS)
          .toDart;
      _running = true;
      _lastError = null;
    } catch (error) {
      _lastError = 'Camera unavailable: $error';
      _running = false;
    }
  }

  void _registerFactory() {
    if (_factoryRegistered) return;
    _factoryRegistered = true;
    ui_web.platformViewRegistry.registerViewFactory(
      viewType,
      (int viewId) => teacherJs.getVisionContainer(),
    );
  }

  void _onError(JSString message) {
    _lastError = message.toDart;
  }

  void _onFrame(
    JSFloat32Array landmarks,
    JSArray<JSString> handedness,
    JSFloat32Array scores,
    JSNumber timestamp,
    JSNumber width,
    JSNumber height,
  ) {
    final flat = landmarks.toDart;
    final labels = handedness.toDart;
    final scoreList = scores.toDart;
    final hands = <Hand>[];
    for (var i = 0; i < labels.length; i++) {
      final base = i * 63;
      if (base + 63 > flat.length) break;
      final points = List<HandLandmark>.generate(
        21,
        (j) => HandLandmark(
          flat[base + j * 3],
          flat[base + j * 3 + 1],
          flat[base + j * 3 + 2],
        ),
        growable: false,
      );
      // MediaPipe labels assume a mirrored (selfie) input. We hand it the raw
      // camera stream, so its "Left" is the learner's right hand.
      final label = labels[i].toDart;
      final handednessValue = label == 'Left'
          ? Handedness.right
          : label == 'Right'
          ? Handedness.left
          : Handedness.unknown;
      hands.add(
        Hand(
          handedness: handednessValue,
          score: i < scoreList.length ? scoreList[i] : 0,
          landmarks: points,
        ),
      );
    }
    if (_controller.isClosed) return;
    _controller.add(
      HandFrame(
        hands: hands,
        timestampMs: timestamp.toDartInt,
        imageWidth: width.toDartInt,
        imageHeight: height.toDartInt,
        mirrored: _mirror,
      ),
    );
  }

  @override
  Future<void> stop() async {
    if (!_running) return;
    _running = false;
    if (teacherJsAvailable) teacherJs.stopVision();
  }

  @override
  Widget buildPreview(BuildContext context) {
    if (!teacherJsAvailable) return const SizedBox.expand();
    _registerFactory();
    return const HtmlElementView(viewType: viewType);
  }

  @override
  Future<void> dispose() async {
    await stop();
    await _controller.close();
  }
}
