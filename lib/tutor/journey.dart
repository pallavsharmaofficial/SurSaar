import 'dart:math' as math;

import '../models/coaching_mode.dart';
import '../models/song.dart';
import '../models/song_section.dart';
import '../models/strumming_pattern.dart';
import '../teacher/engine/practice_plan.dart';
import '../teacher/melody/melody_tab.dart';
import '../teacher/melody/tab_parser.dart';
import 'skill_profile.dart';

/// What a journey step practises.
enum StageKind {
  /// Learn mode on the chords the player doesn't know yet.
  meetChords,

  /// Learn mode, swapping back and forth across the hardest changes.
  changes,

  /// Play-along on two chords to lock the strumming pattern in.
  groove,

  /// Learn mode through one section of the song.
  section,

  /// Play-along through the whole song, slowly.
  slowPlay,

  /// Play-along at (near) song speed.
  perform,

  /// Melody: every note of the tune, low to high.
  meetNotes,

  /// Melody: one phrase / section note by note.
  phrase,

  /// Melody: the whole tune on the beat, slowly.
  melodySlow,

  /// Melody: the whole tune at speed.
  melodyPerform;

  static StageKind parse(String? value) =>
      values.firstWhere((k) => k.name == value, orElse: () => section);

  String get emoji => switch (this) {
    StageKind.meetChords => '🤝',
    StageKind.changes => '🔁',
    StageKind.groove => '🥁',
    StageKind.section => '🧩',
    StageKind.slowPlay => '🐢',
    StageKind.perform => '🎤',
    StageKind.meetNotes => '🎼',
    StageKind.phrase => '🧩',
    StageKind.melodySlow => '🐢',
    StageKind.melodyPerform => '🎤',
  };
}

enum StageStatus { ready, passed }

/// One step of a song journey. Frozen when the journey is created so the
/// numbering stays stable while the player's profile changes.
class JourneyStage {
  JourneyStage({
    required this.kind,
    required this.title,
    required this.goal,
    required this.passScore,
    this.chords = const <String>[],
    this.sequence = const <String>[],
    this.section,
    this.tempo = 1.0,
    this.status = StageStatus.ready,
    this.bestScore = 0,
    this.attempts = 0,
  });

  factory JourneyStage.fromJson(Map<String, dynamic> json) => JourneyStage(
    kind: StageKind.parse(json['kind'] as String?),
    title: json['title'] as String? ?? '',
    goal: json['goal'] as String? ?? '',
    passScore: (json['passScore'] as num?)?.toDouble() ?? 70,
    chords: _strings(json['chords']),
    sequence: _strings(json['sequence']),
    section: json['section'] as String?,
    tempo: (json['tempo'] as num?)?.toDouble() ?? 1,
    status: json['status'] == 'passed' ? StageStatus.passed : StageStatus.ready,
    bestScore: (json['bestScore'] as num?)?.toDouble() ?? 0,
    attempts: (json['attempts'] as num?)?.toInt() ?? 0,
  );

  final StageKind kind;
  final String title;

  /// Why this step matters, in the tutor's words.
  final String goal;

  /// 0..100 needed to move on.
  final double passScore;
  final List<String> chords;

  /// Explicit learn-mode order (chord changes drill).
  final List<String> sequence;
  final String? section;

  /// Fraction of the song tempo; lowered when the player struggles.
  double tempo;
  StageStatus status;
  double bestScore;
  int attempts;

  bool get passed => status == StageStatus.passed;

  CoachingMode get mode => switch (kind) {
    StageKind.groove ||
    StageKind.slowPlay ||
    StageKind.perform ||
    StageKind.melodySlow ||
    StageKind.melodyPerform => CoachingMode.playAlong,
    _ => CoachingMode.learn,
  };

  bool get isPlayAlong => mode == CoachingMode.playAlong;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'kind': kind.name,
    'title': title,
    'goal': goal,
    'passScore': passScore,
    'chords': chords,
    'sequence': sequence,
    'section': section,
    'tempo': tempo,
    'status': status.name,
    'bestScore': bestScore,
    'attempts': attempts,
  };

  static List<String> _strings(Object? value) => value is List
      ? value.map((e) => e.toString()).toList(growable: false)
      : const <String>[];
}

/// The tutor's step-by-step path through one song.
class SongJourney {
  SongJourney({
    required this.songId,
    required this.stages,
    this.current = 0,
    this.startedMs = 0,
    this.lastPlayedMs = 0,
    this.completedMs = 0,
  });

  factory SongJourney.fromJson(Map<String, dynamic> json) => SongJourney(
    songId: json['songId'] as String? ?? '',
    stages: <JourneyStage>[
      for (final s in (json['stages'] as List<dynamic>? ?? const <dynamic>[]))
        if (s is Map<String, dynamic>) JourneyStage.fromJson(s),
    ],
    current: (json['current'] as num?)?.toInt() ?? 0,
    startedMs: (json['startedMs'] as num?)?.toInt() ?? 0,
    lastPlayedMs: (json['lastPlayedMs'] as num?)?.toInt() ?? 0,
    completedMs: (json['completedMs'] as num?)?.toInt() ?? 0,
  );

  final String songId;
  final List<JourneyStage> stages;

  /// Index of the next step to play.
  int current;
  int startedMs;
  int lastPlayedMs;
  int completedMs;

  bool get completed => stages.isNotEmpty && stages.every((s) => s.passed);

  int get passedCount => stages.where((s) => s.passed).length;

  double get progress => stages.isEmpty ? 0 : passedCount / stages.length;

  JourneyStage? get currentStage =>
      current >= 0 && current < stages.length ? stages[current] : null;

  /// 0–3 stars from the final performance step.
  int get stars {
    final last = stages.isEmpty ? null : stages.last;
    if (last == null || !last.passed) return 0;
    return last.bestScore >= 92
        ? 3
        : last.bestScore >= 85
        ? 2
        : 1;
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'songId': songId,
    'stages': stages.map((s) => s.toJson()).toList(),
    'current': current,
    'startedMs': startedMs,
    'lastPlayedMs': lastPlayedMs,
    'completedMs': completedMs,
  };
}

/// Builds journeys and turns stages into practice plans.
class JourneyBuilder {
  const JourneyBuilder._();

  /// Learn-mode changes faster than this don't need a drill.
  static const int fluentChangeMs = 2500;

  static SongJourney build(
    Song song,
    SkillProfile profile, {
    bool Function(String chord)? isBarre,
    int? nowMs,
  }) {
    final barre = isBarre ?? (_) => false;
    final stages = song.hasMelody
        ? _melodyStages(song, profile, barre)
        : _chordStages(song, profile, barre);
    final now = nowMs ?? DateTime.now().millisecondsSinceEpoch;
    return SongJourney(songId: song.id, stages: stages, startedMs: now);
  }

  static List<JourneyStage> _chordStages(
    Song song,
    SkillProfile profile,
    bool Function(String chord) isBarre,
  ) {
    final stages = <JourneyStage>[];
    final chords = song.uniqueChords;
    // Nothing to play yet (e.g. an instrumental waiting for a pasted tab).
    if (chords.isEmpty) return stages;
    final beginner = profile.level.index <= TutorLevel.beginner.index;

    final weak = chords.where((c) => !profile.knows(c)).toList();
    if (weak.isNotEmpty) {
      final barres = weak.where(isBarre).toList();
      stages.add(
        JourneyStage(
          kind: StageKind.meetChords,
          title: weak.length == 1
              ? 'Meet ${weak.first}'
              : 'Meet the chords: ${weak.join(' · ')}',
          goal: barres.isEmpty
              ? 'Get each new shape ringing clean. No tempo – I wait for you.'
              : 'Get each new shape ringing clean. ${barres.join(', ')} '
                    '${barres.length > 1 ? 'are barre chords' : 'is a barre chord'} '
                    '– press with the side of your index finger.',
          passScore: 70,
          chords: weak,
        ),
      );
    }

    // The song's changes that are new or slow for this player.
    final pairs = <String, (String, String)>{};
    final seq = song.chordSequence;
    for (var i = 0; i + 1 < seq.length; i++) {
      if (seq[i] != seq[i + 1]) {
        pairs.putIfAbsent(
          '${seq[i]}>${seq[i + 1]}',
          () => (seq[i], seq[i + 1]),
        );
      }
    }
    int cost((String, String) p) {
      final known = profile.transitions['${p.$1}>${p.$2}'];
      if (known == null || known.averageMs == 0) {
        return 100000 -
            (profile.knows(p.$1) && profile.knows(p.$2) ? 50000 : 0);
      }
      return known.averageMs + known.fails * 4000;
    }

    final hard = pairs.values.where((p) {
      final known = profile.transitions['${p.$1}>${p.$2}'];
      return known == null ||
          known.averageMs == 0 ||
          known.averageMs > fluentChangeMs ||
          known.fails > known.count ~/ 3;
    }).toList()..sort((a, b) => cost(b).compareTo(cost(a)));
    final drill = hard.take(3).toList();
    if (drill.isNotEmpty) {
      final sequence = <String>[
        for (final p in drill) ...<String>[p.$1, p.$2, p.$1, p.$2],
      ];
      stages.add(
        JourneyStage(
          kind: StageKind.changes,
          title:
              'Smooth changes: ${drill.map((p) => '${p.$1}→${p.$2}').join(', ')}',
          goal:
              'Songs live in the changes. Lift all fingers together and land '
              'the next shape as one movement.',
          passScore: 75,
          sequence: sequence,
          chords: <String>{
            for (final p in drill) ...<String>[p.$1, p.$2],
          }.toList(growable: false),
        ),
      );
    }

    final distinct = <String>[];
    for (final c in seq) {
      if (!distinct.contains(c)) distinct.add(c);
      if (distinct.length == 2) break;
    }
    if (distinct.isNotEmpty) {
      stages.add(
        JourneyStage(
          kind: StageKind.groove,
          title: 'Groove: ${song.strummingPattern}',
          goal:
              'Lock the strumming pattern in on ${distinct.join(' and ')} '
              'before the full song. Keep your arm swinging even on the gaps.',
          passScore: 65,
          chords: distinct,
          tempo: 0.6,
        ),
      );
    }

    final sectionNames = <String>[];
    for (final section in song.sections) {
      if (!sectionNames.contains(section.name) &&
          section.chordSequence.isNotEmpty) {
        sectionNames.add(section.name);
      }
    }
    for (final name in sectionNames.take(4)) {
      stages.add(
        JourneyStage(
          kind: StageKind.section,
          title: '$name, chord by chord',
          goal: 'Walk through the $name in order. I wait on every chord.',
          passScore: 80,
          section: name,
        ),
      );
    }

    stages.add(
      JourneyStage(
        kind: StageKind.slowPlay,
        title: 'Play along – slow',
        goal:
            'The whole song at 60% speed with the click. Chords change on '
            'the beat now.',
        passScore: 70,
        tempo: 0.6,
      ),
    );
    stages.add(
      JourneyStage(
        kind: StageKind.perform,
        title: beginner ? 'Perform it (85% speed)' : 'Perform it',
        goal: 'Play the song through, start to finish. This is the real thing!',
        passScore: 80,
        tempo: beginner ? 0.85 : 1.0,
      ),
    );
    return stages;
  }

  static List<JourneyStage> _melodyStages(
    Song song,
    SkillProfile profile,
    bool Function(String chord) isBarre,
  ) {
    final tab = TabParser.parse(song.tabs ?? '');
    final unique = tab.uniqueNotes;
    final stages = <JourneyStage>[
      JourneyStage(
        kind: StageKind.meetNotes,
        title: 'Meet the notes (${unique.length})',
        goal:
            'Every note of the tune from low to high. Keep one finger per '
            'fret and let each note ring.',
        passScore: 75,
        sequence: unique.map((n) => n.token).toList(growable: false),
      ),
    ];
    for (final name in tab.sections.take(5)) {
      stages.add(
        JourneyStage(
          kind: StageKind.phrase,
          title: '$name, note by note',
          goal: 'Learn the $name phrase. I wait on every note.',
          passScore: 80,
          section: name,
        ),
      );
    }
    // Beginners accompany with open chords only.
    final vamp = song.originalChords
        .where(
          (c) => profile.level.index > TutorLevel.beginner.index || !isBarre(c),
        )
        .take(3)
        .toList(growable: false);
    if (vamp.isNotEmpty) {
      stages.add(
        JourneyStage(
          kind: StageKind.groove,
          title: 'Backing groove: ${vamp.join(' · ')}',
          goal:
              'The chords that sit under the melody – so you can accompany '
              'a friend or loop it.',
          passScore: 65,
          chords: vamp,
          tempo: 0.7,
        ),
      );
    }
    stages
      ..add(
        JourneyStage(
          kind: StageKind.melodySlow,
          title: 'Play the tune – slow',
          goal: 'The whole melody on the beat at 60% speed.',
          passScore: 70,
          tempo: 0.6,
        ),
      )
      ..add(
        JourneyStage(
          kind: StageKind.melodyPerform,
          title: 'Perform the tune',
          goal: 'Start to finish at full speed.',
          passScore: 80,
        ),
      );
    return stages;
  }

  /// The practice plan for one stage of [song].
  static PracticePlan planFor(Song song, JourneyStage stage) {
    final songBpm = song.bpm ?? 80;
    final bpm = math.max(40, (songBpm * stage.tempo).round());
    final subtitle = '${song.title} · ${stage.title}';
    switch (stage.kind) {
      case StageKind.meetChords:
        return PracticePlan.forChords(
          stage.chords,
          pattern: song.strummingPattern,
          bpm: math.max(50, (songBpm * 0.6).round()),
          title: stage.title,
          subtitle: song.title,
          mode: PracticeMode.song,
          sourceId: song.id,
        );
      case StageKind.changes:
        return _sequencePlan(
          stage.sequence,
          song: song,
          title: stage.title,
          bpm: math.max(50, (songBpm * 0.6).round()),
        );
      case StageKind.groove:
        return PracticePlan.forChords(
          stage.chords,
          pattern: song.strummingPattern,
          bpm: bpm,
          rounds: 2,
          title: stage.title,
          subtitle: song.title,
          mode: PracticeMode.song,
          sourceId: song.id,
        );
      case StageKind.section:
        final sections = song.sections
            .where((s) => s.name == stage.section)
            .take(1)
            .map(
              (s) => SongSection(
                name: s.name,
                lines: s.lines,
                strumming: s.strumming,
                barsPerChord: s.barsPerChord,
              ),
            )
            .toList(growable: false);
        final plan = PracticePlan.forSong(
          song.copyWith(sections: sections),
          bpm: bpm,
        );
        return _retitle(plan, stage.title, song.title);
      case StageKind.slowPlay:
      case StageKind.perform:
        return _retitle(
          PracticePlan.forSong(song, bpm: bpm),
          song.title,
          stage.title,
        );
      case StageKind.meetNotes:
        final notes = stage.sequence
            .map(TabNote.fromToken)
            .whereType<TabNote>()
            .toList(growable: false);
        final tab = TabParser.parse(song.tabs ?? '');
        return PracticePlan.forMelody(
          notes,
          title: stage.title,
          subtitle: song.title,
          bpm: bpm,
          sourceId: song.id,
          boxStart: tab.boxStart,
        );
      case StageKind.phrase:
        final tab = TabParser.parse(song.tabs ?? '');
        return PracticePlan.forMelody(
          tab.notesIn(stage.section ?? ''),
          title: stage.title,
          subtitle: song.title,
          bpm: bpm,
          sourceId: song.id,
          boxStart: tab.boxStart,
        );
      case StageKind.melodySlow:
      case StageKind.melodyPerform:
        final tab = TabParser.parse(song.tabs ?? '');
        return PracticePlan.forMelody(
          tab.notes,
          title: song.title,
          subtitle: subtitle,
          bpm: bpm,
          sourceId: song.id,
        );
    }
  }

  static PracticePlan _sequencePlan(
    List<String> sequence, {
    required Song song,
    required String title,
    required int bpm,
  }) {
    final list = sequence.isEmpty ? song.uniqueChords : sequence;
    final targets = <ChordTarget>[];
    var beat = 0.0;
    for (final chord in list) {
      targets.add(
        ChordTarget(
          chord: chord,
          startBeat: beat,
          endBeat: beat + 8,
          section: 'Changes',
        ),
      );
      beat += 8;
    }
    return PracticePlan(
      title: title,
      subtitle: song.title,
      targets: targets,
      pattern: StrummingPattern.parse(song.strummingPattern),
      bpm: bpm,
      mode: PracticeMode.song,
      sourceId: song.id,
      learnSequence: list,
    );
  }

  static PracticePlan _retitle(
    PracticePlan plan,
    String title,
    String subtitle,
  ) => PracticePlan(
    title: title,
    subtitle: subtitle,
    targets: plan.targets,
    pattern: plan.pattern,
    bpm: plan.bpm,
    mode: plan.mode,
    capo: plan.capo,
    sourceId: plan.sourceId,
    beatsPerBar: plan.beatsPerBar,
  );
}
