import 'sound_service.dart';

TeacherSoundService createPlatformSoundService() => SilentSoundService();

class SilentSoundService implements TeacherSoundService {
  @override
  bool get canPlayChords => false;

  @override
  bool get canSpeak => false;

  @override
  void click({bool accent = false}) {}

  @override
  Duration playChord(List<int> midiNotes, {bool down = true}) => Duration.zero;

  @override
  Duration playNote(int midi) => Duration.zero;

  @override
  void speak(String text, {String language = 'en-US', double rate = 1}) {}

  @override
  void stopSpeaking() {}
}
