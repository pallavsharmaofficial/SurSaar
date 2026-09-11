import 'dart:js_interop';

import 'sound_service.dart';
import 'teacher_js.dart';

TeacherSoundService createPlatformSoundService() => WebSoundService();

/// Web Audio clicks and plucked-string chords, Web Speech coaching.
class WebSoundService implements TeacherSoundService {
  @override
  bool get canPlayChords => teacherJsAvailable;

  @override
  bool get canSpeak => teacherJsAvailable && teacherJs.speechSupported().toDart;

  @override
  void click({bool accent = false}) {
    if (teacherJsAvailable) teacherJs.click(accent.toJS);
  }

  @override
  Duration playChord(List<int> midiNotes, {bool down = true}) {
    if (!teacherJsAvailable || midiNotes.isEmpty) return Duration.zero;
    final notes = <JSNumber>[for (final n in midiNotes) n.toJS].toJS;
    final ms = teacherJs.playChord(notes, down.toJS).toDartInt;
    return Duration(milliseconds: ms);
  }

  @override
  Duration playNote(int midi) {
    if (!teacherJsAvailable) return Duration.zero;
    return Duration(milliseconds: teacherJs.playNote(midi.toJS).toDartInt);
  }

  @override
  void speak(String text, {String language = 'en-US', double rate = 1}) {
    if (!canSpeak || text.isEmpty) return;
    teacherJs.speak(text.toJS, language.toJS, rate.toJS);
  }

  @override
  void stopSpeaking() {
    if (teacherJsAvailable) teacherJs.cancelSpeech();
  }
}
