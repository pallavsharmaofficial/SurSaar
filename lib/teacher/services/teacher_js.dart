import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Bindings for `web/teacher/sursaar_teacher.js`, which owns the camera,
/// hand tracking (in a worker), microphone capture, sounds and speech.
@JS('SurSaarTeacher')
external JSObject? get surSaarTeacherObject;

bool get teacherJsAvailable => surSaarTeacherObject != null;

extension type SurSaarTeacherJS(JSObject _) implements JSObject {
  external JSBoolean isSupported();

  external JSPromise<JSBoolean> preloadVision(JSFunction onStatus);

  external JSString visionStatus();

  external web.HTMLElement createVisionView(JSNumber viewId);

  external JSPromise<JSAny?> startVision(
    JSBoolean frontCamera,
    JSFunction onFrame,
    JSFunction onError,
  );

  external void stopVision();

  external void setMirror(JSBoolean mirror);

  external JSPromise<JSBoolean> startAudio(
    JSFunction onChunk,
    JSFunction onError,
  );

  external void stopAudio();

  external void click(JSBoolean accent);

  external JSNumber playChord(JSArray<JSNumber> notes, JSBoolean down);

  external JSNumber playNote(JSNumber midi);

  external JSBoolean speechSupported();

  external void speak(JSString text, JSString lang, JSNumber rate);

  external void cancelSpeech();
}

SurSaarTeacherJS get teacherJs => SurSaarTeacherJS(surSaarTeacherObject!);
