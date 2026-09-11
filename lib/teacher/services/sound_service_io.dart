import 'package:flutter/services.dart';

import 'sound_service.dart';

TeacherSoundService createPlatformSoundService() => SystemSoundService();

/// Mobile / desktop: the platform click for the metronome. Reference chords
/// and speech are web-only for now.
class SystemSoundService implements TeacherSoundService {
  @override
  bool get canPlayChords => false;

  @override
  bool get canSpeak => false;

  @override
  void click({bool accent = false}) {
    SystemSound.play(SystemSoundType.click);
  }

  @override
  Duration playChord(List<int> midiNotes, {bool down = true}) => Duration.zero;

  @override
  Duration playNote(int midi) => Duration.zero;

  @override
  void speak(String text, {String language = 'en-US', double rate = 1}) {}

  @override
  void stopSpeaking() {}
}
