import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Bindings for `web/teacher/sursaar_teacher.js`, which owns the camera,
/// the MediaPipe hand landmarker and the Web Audio capture graph.
@JS('SurSaarTeacher')
external JSObject? get surSaarTeacherObject;

bool get teacherJsAvailable => surSaarTeacherObject != null;

extension type SurSaarTeacherJS(JSObject _) implements JSObject {
  external JSPromise<JSAny?> startVision(
    JSBoolean frontCamera,
    JSFunction onFrame,
    JSFunction onError,
  );

  external void stopVision();

  external web.HTMLElement getVisionContainer();

  external void setMirror(JSBoolean mirror);

  external JSPromise<JSBoolean> startAudio(
    JSFunction onChunk,
    JSFunction onError,
  );

  external void stopAudio();

  external void click(JSBoolean accent);

  external JSBoolean isSupported();
}

SurSaarTeacherJS get teacherJs => SurSaarTeacherJS(surSaarTeacherObject!);
