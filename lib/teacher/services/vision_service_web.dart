import 'dart:async';
import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../models/hand_frame.dart';
import 'teacher_js.dart';
import 'vision_service.dart';

VisionService createPlatformVisionService() => WebVisionService();

/// Web implementation backed by `web/teacher/sursaar_teacher.js`.
class WebVisionService implements VisionService {
  WebVisionService()
    : _status = ValueNotifier<TrackingStatus>(
        teacherJsAvailable ? TrackingStatus.idle : TrackingStatus.unavailable,
      );

  static const String viewType = 'sursaar-vision-view';
  static bool _factoryRegistered = false;

  final StreamController<HandFrame> _controller =
      StreamController<HandFrame>.broadcast();
  final ValueNotifier<TrackingStatus> _status;
  bool _running = false;
  bool _mirror = true;
  bool _disposed = false;
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
  ValueListenable<TrackingStatus> get trackingStatus => _status;

  @override
  Stream<HandFrame> get frames => _controller.stream;

  void _setStatus(TrackingStatus status) {
    if (!_disposed) _status.value = status;
  }

  void _onStatus(JSString status) {
    switch (status.toDart) {
      case 'loading':
        _setStatus(TrackingStatus.loading);
      case 'ready':
        _setStatus(TrackingStatus.ready);
      case 'error':
        _setStatus(TrackingStatus.error);
    }
  }

  @override
  Future<void> warmUp() async {
    if (!teacherJsAvailable || _status.value == TrackingStatus.ready) return;
    try {
      final ok = await teacherJs.preloadVision(_onStatus.toJS).toDart;
      _setStatus(ok.toDart ? TrackingStatus.ready : TrackingStatus.error);
    } catch (_) {
      _setStatus(TrackingStatus.error);
    }
  }

  static void _registerFactory() {
    if (_factoryRegistered || !teacherJsAvailable) return;
    _factoryRegistered = true;
    ui_web.platformViewRegistry.registerViewFactory(
      viewType,
      (int viewId) => teacherJs.createVisionView(viewId.toJS),
    );
  }

  @override
  Future<void> start({bool frontCamera = true, bool mirror = true}) async {
    if (!teacherJsAvailable) {
      _lastError = 'The camera helper did not load. Reload the page.';
      return;
    }
    _mirror = mirror && frontCamera;
    _registerFactory();
    teacherJs.setMirror(_mirror.toJS);
    _lastError = null;
    try {
      await teacherJs
          .startVision(frontCamera.toJS, _onFrame.toJS, _onError.toJS)
          .toDart;
      _running = true;
      if (_status.value == TrackingStatus.idle) {
        _setStatus(TrackingStatus.loading);
      }
      unawaited(warmUp());
    } catch (error) {
      _lastError ??= _describe(error);
      _running = false;
    }
  }

  static String _describe(Object error) {
    final text = error.toString();
    return text.startsWith('Error: ') ? text.substring(7) : text;
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
    if (_controller.isClosed) return;
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
      // MediaPipe labels assume a mirrored selfie image. The worker receives
      // the raw camera frame, so its "Left" is the learner's right hand.
      final label = labels[i].toDart;
      hands.add(
        Hand(
          handedness: label == 'Left'
              ? Handedness.right
              : label == 'Right'
              ? Handedness.left
              : Handedness.unknown,
          score: i < scoreList.length ? scoreList[i] : 0,
          landmarks: points,
        ),
      );
    }
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
    _disposed = true;
    _status.dispose();
    await _controller.close();
  }
}
