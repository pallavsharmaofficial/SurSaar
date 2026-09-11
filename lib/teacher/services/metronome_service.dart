import 'metronome_stub.dart'
    if (dart.library.io) 'metronome_io.dart'
    if (dart.library.js_interop) 'metronome_web.dart';

/// Plays the metronome click.
abstract class MetronomeService {
  void click({bool accent = false});
}

MetronomeService createMetronomeService() => createPlatformMetronomeService();
