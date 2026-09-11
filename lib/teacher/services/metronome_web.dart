import 'dart:js_interop';

import 'metronome_service.dart';
import 'teacher_js.dart';

MetronomeService createPlatformMetronomeService() => WebMetronomeService();

/// Web Audio oscillator click from `sursaar_teacher.js`.
class WebMetronomeService implements MetronomeService {
  @override
  void click({bool accent = false}) {
    if (!teacherJsAvailable) return;
    teacherJs.click(accent.toJS);
  }
}
