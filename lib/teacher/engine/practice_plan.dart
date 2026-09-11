import '../../core/utils/chord_transposer.dart';
import '../../models/lesson.dart';
import '../../models/song.dart';
import '../../models/strumming_pattern.dart';

enum PracticeMode { song, lesson, adhoc }

/// One chord held for a span of beats.
class ChordTarget {
  const ChordTarget({
    required this.chord,
    required this.startBeat,
    required this.endBeat,
    this.section = '',
  });

  final String chord;
  final double startBeat;
  final double endBeat;
  final String section;

  double get beats => endBeat - startBeat;

  bool contains(double beat) => beat >= startBeat && beat < endBeat;

  double progressAt(double beat) =>
      beats <= 0 ? 1 : ((beat - startBeat) / beats).clamp(0.0, 1.0);
}

/// What the teacher will drill: a timeline of chord targets plus the
/// strumming pattern and tempo they are played with.
class PracticePlan {
  PracticePlan({
    required this.title,
    required this.targets,
    required this.pattern,
    required this.bpm,
    required this.mode,
    this.capo = 0,
    this.sourceId,
    this.beatsPerBar = 4,
    this.subtitle,
    List<String>? learnSequence,
  }) : _learnSequence = learnSequence;

  final String title;
  final String? subtitle;
  final List<ChordTarget> targets;
  final StrummingPattern pattern;
  final int bpm;
  final int capo;
  final PracticeMode mode;

  /// Song id, lesson id or null for ad-hoc practice.
  final String? sourceId;
  final int beatsPerBar;

  final List<String>? _learnSequence;

  /// The chords learn mode walks through, one at a time.
  ///
  /// Chord drills repeat their chords; songs follow their chord changes with
  /// back-to-back repeats of the same chord merged.
  List<String> get learnSteps {
    final explicit = _learnSequence;
    if (explicit != null && explicit.isNotEmpty) return explicit;
    final steps = <String>[];
    for (final target in targets) {
      if (steps.isEmpty || steps.last != target.chord) steps.add(target.chord);
    }
    return steps;
  }

  double get totalBeats => targets.isEmpty ? 0 : targets.last.endBeat;

  Duration get estimatedDuration =>
      Duration(milliseconds: (totalBeats * 60000 / bpm).round());

  /// Unique chords in order of first appearance.
  List<String> get chords {
    final seen = <String>{};
    final result = <String>[];
    for (final target in targets) {
      if (seen.add(target.chord)) result.add(target.chord);
    }
    return result;
  }

  int indexAt(double beat) {
    if (targets.isEmpty) return -1;
    if (beat < 0) return 0;
    var lo = 0;
    var hi = targets.length - 1;
    while (lo <= hi) {
      final mid = (lo + hi) ~/ 2;
      final t = targets[mid];
      if (beat < t.startBeat) {
        hi = mid - 1;
      } else if (beat >= t.endBeat) {
        lo = mid + 1;
      } else {
        return mid;
      }
    }
    return beat >= totalBeats
        ? targets.length - 1
        : lo.clamp(0, targets.length - 1);
  }

  ChordTarget? targetAt(double beat) {
    final i = indexAt(beat);
    return i < 0 ? null : targets[i];
  }

  ChordTarget? nextAfter(double beat) {
    final i = indexAt(beat);
    if (i < 0 || i + 1 >= targets.length) return null;
    return targets[i + 1];
  }

  PracticePlan copyWith({int? bpm, int? capo}) {
    if (capo != null && capo != this.capo && mode == PracticeMode.song) {
      // Re-transpose the chord shapes for the new capo position.
      final shift = this.capo - capo;
      return PracticePlan(
        title: title,
        subtitle: subtitle,
        targets: targets
            .map(
              (t) => ChordTarget(
                chord: ChordTransposer.transposeChord(t.chord, shift),
                startBeat: t.startBeat,
                endBeat: t.endBeat,
                section: t.section,
              ),
            )
            .toList(growable: false),
        pattern: pattern,
        bpm: bpm ?? this.bpm,
        mode: mode,
        capo: capo,
        sourceId: sourceId,
        beatsPerBar: beatsPerBar,
        learnSequence: _learnSequence
            ?.map((c) => ChordTransposer.transposeChord(c, shift))
            .toList(growable: false),
      );
    }
    return PracticePlan(
      title: title,
      subtitle: subtitle,
      targets: targets,
      pattern: pattern,
      bpm: bpm ?? this.bpm,
      mode: mode,
      capo: capo ?? this.capo,
      sourceId: sourceId,
      beatsPerBar: beatsPerBar,
      learnSequence: _learnSequence,
    );
  }

  /// Builds the chord timeline for a song.
  ///
  /// Chord sheets list the *shapes* to fret with the capo on [Song.capo], so
  /// they are used as written; picking a different [capo] re-transposes them
  /// (capo 2 + C shape sounds like D, so with no capo you play D).
  factory PracticePlan.forSong(
    Song song, {
    int? bpm,
    int? capo,
    int beatsPerBar = 4,
    int defaultBarsPerChord = 1,
  }) {
    final capoFret = capo ?? song.capo;
    final shift = song.capo - capoFret;
    final targets = <ChordTarget>[];
    var beat = 0.0;

    void add(String chord, double beats, String section) {
      final shape = ChordTransposer.transposeChord(chord, shift);
      targets.add(
        ChordTarget(
          chord: shape,
          startBeat: beat,
          endBeat: beat + beats,
          section: section,
        ),
      );
      beat += beats;
    }

    if (song.sections.isEmpty) {
      for (var round = 0; round < 2; round++) {
        for (final chord in song.originalChords) {
          add(
            chord,
            defaultBarsPerChord * beatsPerBar.toDouble(),
            'Progression',
          );
        }
      }
    } else {
      for (final section in song.sections) {
        final barsPerChord = section.barsPerChord ?? defaultBarsPerChord;
        for (var r = 0; r < section.repeat; r++) {
          for (final line in section.lines) {
            for (final placement in line.chords) {
              final beats =
                  placement.beats ?? barsPerChord * beatsPerBar.toDouble();
              add(placement.chord, beats, section.name);
            }
          }
        }
      }
    }

    return PracticePlan(
      title: song.title,
      subtitle: song.artist,
      targets: targets,
      pattern: song.strumming,
      bpm: bpm ?? song.bpm ?? 80,
      capo: capoFret,
      mode: PracticeMode.song,
      sourceId: song.id,
      beatsPerBar: beatsPerBar,
    );
  }

  /// Loops a list of chords – the ad-hoc / chord-drill plan.
  factory PracticePlan.forChords(
    List<String> chords, {
    required String pattern,
    required int bpm,
    int barsPerChord = 2,
    int rounds = 4,
    int beatsPerBar = 4,
    String title = 'Chord practice',
    String? subtitle,
    PracticeMode mode = PracticeMode.adhoc,
    String? sourceId,
  }) {
    final list = chords.isEmpty ? const <String>['G'] : chords;
    final targets = <ChordTarget>[];
    var beat = 0.0;
    for (var r = 0; r < rounds; r++) {
      for (final chord in list) {
        final beats = barsPerChord * beatsPerBar.toDouble();
        targets.add(
          ChordTarget(
            chord: chord,
            startBeat: beat,
            endBeat: beat + beats,
            section: 'Round ${r + 1}',
          ),
        );
        beat += beats;
      }
    }
    return PracticePlan(
      title: title,
      subtitle: subtitle ?? list.join(' · '),
      targets: targets,
      pattern: StrummingPattern.parse(pattern),
      bpm: bpm,
      mode: mode,
      sourceId: sourceId,
      beatsPerBar: beatsPerBar,
      // One chord: place it three times. Several: go through them twice.
      learnSequence: list.length == 1
          ? <String>[list.first, list.first, list.first]
          : <String>[...list, ...list],
    );
  }

  factory PracticePlan.forLesson(Lesson lesson, {Song? song, int? bpm}) {
    if (song != null) {
      final plan = PracticePlan.forSong(song, bpm: bpm ?? lesson.targetBpm);
      return PracticePlan(
        title: lesson.title,
        subtitle: song.title,
        targets: plan.targets,
        pattern: plan.pattern,
        bpm: plan.bpm,
        capo: plan.capo,
        mode: PracticeMode.lesson,
        sourceId: lesson.id,
        beatsPerBar: plan.beatsPerBar,
      );
    }
    return PracticePlan.forChords(
      lesson.targetChords,
      pattern: lesson.targetStrumming ?? 'D D D D',
      bpm: bpm ?? lesson.targetBpm ?? 70,
      barsPerChord: lesson.kind == LessonKind.strumming ? 4 : 2,
      rounds: lesson.kind == LessonKind.strumming ? 2 : 3,
      title: lesson.title,
      subtitle: lesson.category,
      mode: PracticeMode.lesson,
      sourceId: lesson.id,
    );
  }
}
