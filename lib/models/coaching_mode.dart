/// How the AI teacher paces a practice session.
enum CoachingMode {
  /// Waits on every chord until the learner plays it. No tempo pressure.
  learn,

  /// Chords change on the beat, like playing along with the song.
  playAlong;

  static CoachingMode parse(String? value, {CoachingMode fallback = learn}) {
    for (final mode in values) {
      if (mode.name == value) return mode;
    }
    if (value == 'play') return playAlong;
    return fallback;
  }
}
