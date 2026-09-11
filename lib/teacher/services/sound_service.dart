import 'sound_service_stub.dart'
    if (dart.library.io) 'sound_service_io.dart'
    if (dart.library.js_interop) 'sound_service_web.dart';

/// Metronome clicks, reference chord sounds and the spoken coach.
abstract class TeacherSoundService {
  /// True when [playChord] and [playNote] make a sound.
  bool get canPlayChords;

  /// True when [speak] talks.
  bool get canSpeak;

  void click({bool accent = false});

  /// Strums [midiNotes] (low to high). Returns how long the sound lasts.
  Duration playChord(List<int> midiNotes, {bool down = true});

  Duration playNote(int midi);

  void speak(String text, {String language = 'en-US', double rate = 1});

  void stopSpeaking();
}

TeacherSoundService createTeacherSoundService() => createPlatformSoundService();
