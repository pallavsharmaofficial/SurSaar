import 'dart:async';
import 'dart:typed_data';

import 'package:record/record.dart';

import '../models/audio_frame.dart';
import 'audio_capture_service.dart';

AudioCaptureService createPlatformAudioCaptureService() =>
    RecordAudioCaptureService();

/// Microphone capture through the `record` package (Android, iOS, desktop).
class RecordAudioCaptureService implements AudioCaptureService {
  RecordAudioCaptureService({this.sampleRate = 22050});

  final int sampleRate;
  final AudioRecorder _recorder = AudioRecorder();
  final StreamController<AudioFrame> _controller =
      StreamController<AudioFrame>.broadcast();
  StreamSubscription<Uint8List>? _subscription;
  bool _running = false;
  String? _lastError;

  @override
  bool get isSupported => true;

  @override
  bool get isRunning => _running;

  @override
  String? get lastError => _lastError;

  @override
  Stream<AudioFrame> get frames => _controller.stream;

  @override
  Future<bool> start() async {
    if (_running) return true;
    try {
      if (!await _recorder.hasPermission()) {
        _lastError = 'Microphone permission denied.';
        return false;
      }
      final stream = await _recorder.startStream(
        RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: sampleRate,
          numChannels: 1,
          autoGain: false,
          echoCancel: false,
          noiseSuppress: false,
        ),
      );
      _subscription = stream.listen(
        _onBytes,
        onError: (Object e) {
          _lastError = e.toString();
        },
      );
      _running = true;
      _lastError = null;
      return true;
    } catch (error) {
      _lastError = 'Microphone unavailable: $error';
      _running = false;
      return false;
    }
  }

  void _onBytes(Uint8List bytes) {
    final count = bytes.lengthInBytes ~/ 2;
    final view = ByteData.sublistView(bytes);
    final samples = Float32List(count);
    for (var i = 0; i < count; i++) {
      samples[i] = view.getInt16(i * 2, Endian.little) / 32768.0;
    }
    final durationMs = (count * 1000 / sampleRate).round();
    if (_controller.isClosed) return;
    _controller.add(
      AudioFrame(
        samples: samples,
        sampleRate: sampleRate,
        timestampMs: DateTime.now().millisecondsSinceEpoch - durationMs,
      ),
    );
  }

  @override
  Future<void> stop() async {
    if (!_running) return;
    _running = false;
    await _subscription?.cancel();
    _subscription = null;
    try {
      await _recorder.stop();
    } catch (_) {}
  }

  @override
  Future<void> dispose() async {
    await stop();
    await _recorder.dispose();
    await _controller.close();
  }
}
