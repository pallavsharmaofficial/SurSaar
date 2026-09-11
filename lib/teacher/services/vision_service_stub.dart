import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../models/hand_frame.dart';
import 'vision_service.dart';

VisionService createPlatformVisionService() => UnsupportedVisionService();

class UnsupportedVisionService implements VisionService {
  final StreamController<HandFrame> _controller =
      StreamController<HandFrame>.broadcast();
  final ValueNotifier<TrackingStatus> _status = ValueNotifier<TrackingStatus>(
    TrackingStatus.unavailable,
  );

  @override
  bool get supportsPreview => false;

  @override
  bool get supportsHandTracking => false;

  @override
  bool get isRunning => false;

  @override
  String? get lastError => 'The camera is not available on this device.';

  @override
  ValueListenable<TrackingStatus> get trackingStatus => _status;

  @override
  Stream<HandFrame> get frames => _controller.stream;

  @override
  Future<void> warmUp() async {}

  @override
  Future<void> start({bool frontCamera = true, bool mirror = true}) async {}

  @override
  Future<void> stop() async {}

  @override
  Widget buildPreview(BuildContext context) => const SizedBox.expand();

  @override
  Future<void> dispose() async {
    _status.dispose();
    await _controller.close();
  }
}
