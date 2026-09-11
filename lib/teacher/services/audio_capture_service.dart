import '../models/audio_frame.dart';
import 'audio_capture_stub.dart'
    if (dart.library.io) 'audio_capture_record.dart'
    if (dart.library.js_interop) 'audio_capture_web.dart';

/// Streams microphone audio as float PCM frames.
///
/// * Web: Web Audio API (AudioWorklet) via `sursaar_teacher.js`, with
///   echo cancellation / noise suppression / auto gain turned off so the
///   guitar's harmonics reach the chord detector untouched.
/// * Android / iOS / desktop: the `record` package streaming 16-bit PCM.
abstract class AudioCaptureService {
  bool get isSupported;
  bool get isRunning;
  String? get lastError;

  Stream<AudioFrame> get frames;

  /// Returns false when permission was denied or capture is unsupported.
  Future<bool> start();

  Future<void> stop();

  Future<void> dispose();
}

AudioCaptureService createAudioCaptureService() =>
    createPlatformAudioCaptureService();
