import 'journey.dart';

double _d(Object? v, [double fallback = 0]) =>
    v is num ? v.toDouble() : fallback;

int _i(Object? v, [int fallback = 0]) => v is num ? v.toInt() : fallback;

Map<String, dynamic> _m(Object? v) =>
    v is Map<String, dynamic> ? v : <String, dynamic>{};

/// Moving average that starts at the first sample.
double ewma(double current, double sample, int samplesSoFar, double alpha) =>
    samplesSoFar == 0 ? sample : current * (1 - alpha) + sample * alpha;

/// How well the player knows one chord (or note).
class ChordSkill {
  ChordSkill(
    this.name, {
    this.attempts = 0,
    this.successes = 0,
    this.mastery = 0,
    this.averageMs = 0,
    this.sessions = 0,
    this.lastPracticedMs = 0,
  });

  factory ChordSkill.fromJson(Map<String, dynamic> json) => ChordSkill(
    json['name'] as String? ?? '',
    attempts: _i(json['attempts']),
    successes: _i(json['successes']),
    mastery: _d(json['mastery']),
    averageMs: _i(json['averageMs']),
    sessions: _i(json['sessions']),
    lastPracticedMs: _i(json['lastPracticedMs']),
  );

  final String name;
  int attempts;
  int successes;

  /// 0..1 – right *and* quick. ≥ [known] counts as known.
  double mastery;

  /// Typical time to land the chord.
  int averageMs;
  int sessions;
  int lastPracticedMs;

  static const double known = 0.6;
  static const double mastered = 0.82;

  bool get isKnown => mastery >= known;

  bool get isMastered => mastery >= mastered;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'name': name,
    'attempts': attempts,
    'successes': successes,
    'mastery': mastery,
    'averageMs': averageMs,
    'sessions': sessions,
    'lastPracticedMs': lastPracticedMs,
  };
}

/// How fast the player moves between two chords.
class TransitionSkill {
  TransitionSkill(
    this.from,
    this.to, {
    this.averageMs = 0,
    this.count = 0,
    this.fails = 0,
  });

  factory TransitionSkill.fromJson(Map<String, dynamic> json) =>
      TransitionSkill(
        json['from'] as String? ?? '',
        json['to'] as String? ?? '',
        averageMs: _i(json['averageMs']),
        count: _i(json['count']),
        fails: _i(json['fails']),
      );

  final String from;
  final String to;
  int averageMs;
  int count;
  int fails;

  String get key => '$from>$to';

  /// A change you can make within a bar at a relaxed tempo.
  bool get isFluent => count > 0 && averageMs > 0 && averageMs <= 2000;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'from': from,
    'to': to,
    'averageMs': averageMs,
    'count': count,
    'fails': fails,
  };
}

/// Rhythm habits across sessions.
class TimingSkill {
  TimingSkill({
    this.offsetMs = 0,
    this.spreadMs = 0,
    this.accuracy = 0,
    this.direction = 0,
    this.samples = 0,
    this.directionSamples = 0,
  });

  factory TimingSkill.fromJson(Map<String, dynamic> json) => TimingSkill(
    offsetMs: _d(json['offsetMs']),
    spreadMs: _d(json['spreadMs']),
    accuracy: _d(json['accuracy']),
    direction: _d(json['direction']),
    samples: _i(json['samples']),
    directionSamples: _i(json['directionSamples']),
  );

  /// Negative = rushing, positive = dragging.
  double offsetMs;
  double spreadMs;
  double accuracy;

  /// Share of strokes played in the right direction.
  double direction;
  int samples;
  int directionSamples;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'offsetMs': offsetMs,
    'spreadMs': spreadMs,
    'accuracy': accuracy,
    'direction': direction,
    'samples': samples,
    'directionSamples': directionSamples,
  };
}

/// Habits the camera and microphone pick up.
class StyleSkill {
  StyleSkill({
    this.handVisible = 0,
    this.handSamples = 0,
    this.level = 0,
    this.levelSamples = 0,
    Map<String, double>? posture,
    this.pitchCents = 0,
    this.pitchSamples = 0,
    this.offByOneFrets = 0,
    this.hearItUses = 0,
    this.skips = 0,
    this.steps = 0,
  }) : posture = posture ?? <String, double>{};

  factory StyleSkill.fromJson(Map<String, dynamic> json) => StyleSkill(
    handVisible: _d(json['handVisible']),
    handSamples: _i(json['handSamples']),
    level: _d(json['level']),
    levelSamples: _i(json['levelSamples']),
    posture: <String, double>{
      for (final e in _m(json['posture']).entries) e.key: _d(e.value),
    },
    pitchCents: _d(json['pitchCents']),
    pitchSamples: _i(json['pitchSamples']),
    offByOneFrets: _i(json['offByOneFrets']),
    hearItUses: _i(json['hearItUses']),
    skips: _i(json['skips']),
    steps: _i(json['steps']),
  );

  double handVisible;
  int handSamples;
  double level;
  int levelSamples;

  /// Posture hint → how often it shows up (decays each session).
  final Map<String, double> posture;

  /// Melody: average cents off (+ sharp, − flat).
  double pitchCents;
  int pitchSamples;

  /// Melody: wrong notes exactly one fret away.
  int offByOneFrets;
  int hearItUses;
  int skips;
  int steps;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'handVisible': handVisible,
    'handSamples': handSamples,
    'level': level,
    'levelSamples': levelSamples,
    'posture': posture,
    'pitchCents': pitchCents,
    'pitchSamples': pitchSamples,
    'offByOneFrets': offByOneFrets,
    'hearItUses': hearItUses,
    'skips': skips,
    'steps': steps,
  };
}

/// One line of the tutor's diary, shown on the insights screen.
class TutorDiaryEntry {
  const TutorDiaryEntry({
    required this.atMs,
    required this.title,
    required this.headline,
    required this.score,
    this.songId,
  });

  factory TutorDiaryEntry.fromJson(Map<String, dynamic> json) =>
      TutorDiaryEntry(
        atMs: _i(json['atMs']),
        title: json['title'] as String? ?? '',
        headline: json['headline'] as String? ?? '',
        score: _d(json['score']),
        songId: json['songId'] as String?,
      );

  final int atMs;
  final String title;
  final String headline;
  final double score;
  final String? songId;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'atMs': atMs,
    'title': title,
    'headline': headline,
    'score': score,
    'songId': songId,
  };
}

/// Everything the tutor remembers about the player.
class SkillProfile {
  SkillProfile({
    Map<String, ChordSkill>? chords,
    Map<String, TransitionSkill>? transitions,
    TimingSkill? timing,
    StyleSkill? style,
    Map<String, SongJourney>? journeys,
    List<TutorDiaryEntry>? diary,
    Map<String, int>? collections,
    this.sessions = 0,
    this.totalMs = 0,
    this.lastSessionMs = 0,
  }) : chords = chords ?? <String, ChordSkill>{},
       transitions = transitions ?? <String, TransitionSkill>{},
       timing = timing ?? TimingSkill(),
       style = style ?? StyleSkill(),
       journeys = journeys ?? <String, SongJourney>{},
       diary = diary ?? <TutorDiaryEntry>[],
       collections = collections ?? <String, int>{};

  factory SkillProfile.fromJson(Map<String, dynamic> json) => SkillProfile(
    chords: <String, ChordSkill>{
      for (final e in _m(json['chords']).entries)
        e.key: ChordSkill.fromJson(_m(e.value)),
    },
    transitions: <String, TransitionSkill>{
      for (final e in _m(json['transitions']).entries)
        e.key: TransitionSkill.fromJson(_m(e.value)),
    },
    timing: TimingSkill.fromJson(_m(json['timing'])),
    style: StyleSkill.fromJson(_m(json['style'])),
    journeys: <String, SongJourney>{
      for (final e in _m(json['journeys']).entries)
        e.key: SongJourney.fromJson(_m(e.value)),
    },
    diary: <TutorDiaryEntry>[
      for (final e in (json['diary'] as List<dynamic>? ?? const <dynamic>[]))
        if (e is Map<String, dynamic>) TutorDiaryEntry.fromJson(e),
    ],
    collections: <String, int>{
      for (final e in _m(json['collections']).entries) e.key: _i(e.value),
    },
    sessions: _i(json['sessions']),
    totalMs: _i(json['totalMs']),
    lastSessionMs: _i(json['lastSessionMs']),
  );

  final Map<String, ChordSkill> chords;
  final Map<String, TransitionSkill> transitions;
  final TimingSkill timing;
  final StyleSkill style;
  final Map<String, SongJourney> journeys;
  final List<TutorDiaryEntry> diary;

  /// Library shelf → songs started from it (taste).
  final Map<String, int> collections;
  int sessions;
  int totalMs;
  int lastSessionMs;

  bool get isNew => sessions == 0;

  ChordSkill? chord(String name) => chords[name];

  double masteryOf(String chord) => chords[chord]?.mastery ?? 0;

  bool knows(String chord) => masteryOf(chord) >= ChordSkill.known;

  List<ChordSkill> get knownChords =>
      chords.values.where((c) => c.isKnown).toList()
        ..sort((a, b) => b.mastery.compareTo(a.mastery));

  /// Rough stage of the player.
  TutorLevel get level {
    final known = knownChords.length;
    if (sessions == 0) return TutorLevel.firstDay;
    if (known < 5) return TutorLevel.beginner;
    if (known < 10) return TutorLevel.improver;
    return TutorLevel.confident;
  }

  SkillProfile copy() => SkillProfile.fromJson(toJson());

  Map<String, dynamic> toJson() => <String, dynamic>{
    'chords': <String, dynamic>{
      for (final e in chords.entries) e.key: e.value.toJson(),
    },
    'transitions': <String, dynamic>{
      for (final e in transitions.entries) e.key: e.value.toJson(),
    },
    'timing': timing.toJson(),
    'style': style.toJson(),
    'journeys': <String, dynamic>{
      for (final e in journeys.entries) e.key: e.value.toJson(),
    },
    'diary': diary.map((e) => e.toJson()).toList(),
    'collections': collections,
    'sessions': sessions,
    'totalMs': totalMs,
    'lastSessionMs': lastSessionMs,
  };
}

enum TutorLevel {
  firstDay,
  beginner,
  improver,
  confident;

  String get label => switch (this) {
    TutorLevel.firstDay => 'First day',
    TutorLevel.beginner => 'Beginner',
    TutorLevel.improver => 'Improver',
    TutorLevel.confident => 'Confident player',
  };
}
