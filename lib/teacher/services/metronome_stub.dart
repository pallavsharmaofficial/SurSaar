import 'metronome_service.dart';

MetronomeService createPlatformMetronomeService() => SilentMetronomeService();

class SilentMetronomeService implements MetronomeService {
  @override
  void click({bool accent = false}) {}
}
