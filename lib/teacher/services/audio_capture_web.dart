import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import '../models/audio_frame.dart';
import 'audio_capture_service.dart';
import 'teacher_js.dart';

AudioCaptureService createPlatformAudioCaptureService() =>
    WebAudioCaptureService();

/// Web Audio capture via `sursaar_teacher.js`.
class WebAudioCaptureService implements AudioCaptureService {
  final StreamController<AudioFrame> _controller =
      StreamController<AudioFrame>.broadcast();
  bool _running = false;
  String? _lastError;

  @override
  bool get isSupported => teacherJsAvailable;

  @override
  bool get isRunning => _running;

  @override
  String? get lastError => _lastError;

  @override
  Stream<AudioFrame> get frames => _controller.stream;

  @override
  Future<bool> start() async {
    if (_running) return true;
    if (!teacherJsAvailable) {
      _lastError =
          'Teacher script not loaded (web/teacher/sursaar_teacher.js).';
      return false;
    }
    try {
      final ok = await teacherJs
          .startAudio(_onChunk.toJS, _onError.toJS)
          .toDart;
      _running = ok.toDart;
      if (_running) _lastError = null;
      return _running;
    } catch (error) {
      _lastError = 'Microphone unavailable: $error';
      _running = false;
      return false;
    }
  }

  void _onError(JSString message) {
    _lastError = message.toDart;
  }

  void _onChunk(JSFloat32Array chunk, JSNumber sampleRate, JSNumber timestamp) {
    if (_controller.isClosed) return;
    final samples = Float32List.fromList(chunk.toDart);
    final rate = sampleRate.toDartInt;
    final durationMs = (samples.length * 1000 / rate).round();
    _controller.add(
      AudioFrame(
        samples: samples,
        sampleRate: rate,
        timestampMs: DateTime.now().millisecondsSinceEpoch - durationMs,
      ),
    );
  }

  @override
  Future<void> stop() async {
    if (!_running) return;
    _running = false;
    if (teacherJsAvailable) teacherJs.stopAudio();
  }

  @override
  Future<void> dispose() async {
    await stop();
    await _controller.close();
  }
}
