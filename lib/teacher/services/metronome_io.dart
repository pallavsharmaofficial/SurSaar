import 'package:flutter/services.dart';

import 'metronome_service.dart';

MetronomeService createPlatformMetronomeService() => SystemMetronomeService();

/// Uses the platform click sound (audible on iOS; Android may be silent
/// depending on system settings). A sampled click is on the roadmap.
class SystemMetronomeService implements MetronomeService {
  @override
  void click({bool accent = false}) {
    SystemSound.play(SystemSoundType.click);
  }
}
