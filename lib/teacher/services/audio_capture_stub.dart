import 'dart:async';

import '../models/audio_frame.dart';
import 'audio_capture_service.dart';

AudioCaptureService createPlatformAudioCaptureService() =>
    UnsupportedAudioCaptureService();

class UnsupportedAudioCaptureService implements AudioCaptureService {
  final StreamController<AudioFrame> _controller =
      StreamController<AudioFrame>.broadcast();

  @override
  bool get isSupported => false;

  @override
  bool get isRunning => false;

  @override
  String? get lastError => 'Microphone is not available on this platform.';

  @override
  Stream<AudioFrame> get frames => _controller.stream;

  @override
  Future<bool> start() async => false;

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() => _controller.close();
}
