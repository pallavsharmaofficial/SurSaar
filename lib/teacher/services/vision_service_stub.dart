import 'dart:async';

import 'package:flutter/widgets.dart';

import '../models/hand_frame.dart';
import 'vision_service.dart';

VisionService createPlatformVisionService() => UnsupportedVisionService();

class UnsupportedVisionService implements VisionService {
  final StreamController<HandFrame> _controller =
      StreamController<HandFrame>.broadcast();

  @override
  bool get supportsPreview => false;

  @override
  bool get supportsHandTracking => false;

  @override
  bool get isRunning => false;

  @override
  String? get lastError => 'Camera is not available on this platform.';

  @override
  Stream<HandFrame> get frames => _controller.stream;

  @override
  Future<void> start({bool frontCamera = true, bool mirror = true}) async {}

  @override
  Future<void> stop() async {}

  @override
  Widget buildPreview(BuildContext context) => const SizedBox.expand();

  @override
  Future<void> dispose() => _controller.close();
}
