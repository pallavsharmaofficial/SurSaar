import 'dart:math' as math;

import '../models/chord_voicing.dart';
import '../models/song.dart';
import '../teacher/engine/performance_recorder.dart';
import '../teacher/melody/melody_tab.dart';
import 'chord_theory.dart';
import 'journey.dart';
import 'skill_profile.dart';

/// A song the tutor suggests, and why.
class TutorPick {
  const TutorPick({
    required this.song,
    required this.score,
    required this.reason,
    required this.newChords,
    required this.knownChords,
    this.journey,
  });

  final Song song;
  final double score;
  final String reason;
  final List<String> newChords;
  final List<String> knownChords;

  /// Set when the player already started this song.
  final SongJourney? journey;

  bool get inProgress => journey != null && !journey!.completed;

  /// Share of the song's chords the player already knows.
  double get readiness {
    final total = newChords.length + knownChords.length;
    return total == 0 ? 1 : knownChords.length / total;
  }
}

enum TutorVerdict { advance, repeat, easier, finished }

/// A concrete thing to work on, optionally with a ready-made drill.
class TutorTip {
  const TutorTip(this.title, this.detail, {this.drillChords, this.drillLabel});

  final String title;
  final String detail;

  /// Chords for a quick learn-mode drill.
  final List<String>? drillChords;
  final String? drillLabel;
}

/// What the tutor says after a session.
class TutorFeedback {
  const TutorFeedback({
    required this.headline,
    required this.verdict,
    required this.score,
    required this.wentWell,
    required this.improve,
    required this.style,
    this.passScore,
    this.nextStageIndex,
    this.nextLabel,
  });

  final String headline;
  final TutorVerdict verdict;
  final double score;
  final double? passScore;
  final List<String> wentWell;
  final List<TutorTip> improve;

  /// Long-term observations about how this person plays.
  final List<String> style;

  /// Journey step to open next, if any.
  final int? nextStageIndex;
  final String? nextLabel;
}

/// The tutor's reasoning. Pure functions over [SkillProfile]s and
/// [SessionReport]s, so every rule is unit-tested.
class TutorBrain {
  const TutorBrain({this.voicingFor});

  /// Looks up chord shapes (for barre detection and finger advice).
  final ChordVoicing? Function(String chord)? voicingFor;

  bool isBarre(String chord) =>
      !TabNote.isToken(chord) && ChordTheory.isBarre(voicingFor?.call(chord));

  // --------------------------------------------------------------- learning

  /// Folds one session into the profile. When [songId]/[stageIndex] point at
  /// a journey step, its best score and status are updated as well.
  SkillProfile applyReport(
    SkillProfile before,
    SessionReport report, {
    String? songId,
    int? stageIndex,
    String? title,
    String? headline,
    int? nowMs,
  }) {
    final profile = before.copy();
    final now = nowMs ?? DateTime.now().millisecondsSinceEpoch;

    for (final entry in report.chordResults.entries) {
      final name = entry.key;
      final r = entry.value;
      if (r.attempts == 0) continue;
      final skill = profile.chords.putIfAbsent(name, () => ChordSkill(name));
      final rate = (r.successes / r.attempts).clamp(0.0, 1.0);
      final speed = r.successes == 0
          ? 0.0
          : ((8000 - r.avgMs) / 6500).clamp(0.0, 1.0);
      final sessionMastery = 0.65 * rate + 0.35 * speed * rate;
      skill.mastery = ewma(
        skill.mastery,
        sessionMastery,
        skill.sessions,
        0.45,
      ).clamp(0.0, 1.0);
      if (r.successes > 0) {
        skill.averageMs = ewma(
          skill.averageMs.toDouble(),
          r.avgMs.toDouble(),
          skill.successes,
          0.5,
        ).round();
      }
      skill.attempts += r.attempts;
      skill.successes += r.successes;
      skill.sessions++;
      skill.lastPracticedMs = now;
    }

    for (final t in report.transitions) {
      if (TabNote.isToken(t.from) || TabNote.isToken(t.to)) continue;
      final skill = profile.transitions.putIfAbsent(
        t.key,
        () => TransitionSkill(t.from, t.to),
      );
      if (t.successes > 0) {
        skill.averageMs = ewma(
          skill.averageMs.toDouble(),
          t.averageMs.toDouble(),
          skill.count - skill.fails,
          0.5,
        ).round();
      }
      skill.count += t.count;
      skill.fails += t.fails;
    }

    final timing = profile.timing;
    final mean = report.meanOffsetMs;
    if (mean != null) {
      timing.offsetMs = ewma(timing.offsetMs, mean, timing.samples, 0.35);
      timing.spreadMs = ewma(
        timing.spreadMs,
        report.offsetSpreadMs!,
        timing.samples,
        0.35,
      );
      timing.accuracy = ewma(
        timing.accuracy,
        report.timingAccuracy ?? 0,
        timing.samples,
        0.35,
      );
      timing.samples++;
    }
    final direction = report.directionAccuracy;
    if (direction != null) {
      timing.direction = ewma(
        timing.direction,
        direction,
        timing.directionSamples,
        0.35,
      );
      timing.directionSamples++;
    }

    final style = profile.style;
    final visible = report.handVisibleRatio;
    if (visible != null) {
      style.handVisible = ewma(
        style.handVisible,
        visible,
        style.handSamples,
        0.35,
      );
      style.handSamples++;
    }
    if (report.averageLevel > 0) {
      style.level = ewma(
        style.level,
        report.averageLevel,
        style.levelSamples,
        0.35,
      );
      style.levelSamples++;
    }
    style.posture.updateAll((_, v) => v * 0.6);
    if (report.shapeChecks >= 10) {
      for (final hint in report.postureHints.entries) {
        final share = hint.value / report.shapeChecks;
        style.posture[hint.key] = (style.posture[hint.key] ?? 0) + share;
      }
    }
    style.posture.removeWhere((_, v) => v < 0.05);
    final cents = report.averageCents;
    if (cents != null) {
      style.pitchCents = ewma(
        style.pitchCents,
        cents,
        style.pitchSamples,
        0.35,
      );
      style.pitchSamples++;
    }
    style.offByOneFrets += report.noteSemitoneErrors
        .where((e) => e.abs() == 1)
        .length;
    style.hearItUses += report.hearItUses;
    style.skips += report.skips;
    style.steps += report.successes + report.skips;

    profile.sessions++;
    profile.totalMs += report.durationMs;
    profile.lastSessionMs = now;

    if (songId != null && stageIndex != null) {
      final journey = profile.journeys[songId];
      if (journey != null &&
          stageIndex >= 0 &&
          stageIndex < journey.stages.length) {
        final stage = journey.stages[stageIndex];
        stage.attempts++;
        stage.bestScore = math.max(stage.bestScore, report.score);
        journey.lastPlayedMs = now;
        if (report.score >= stage.passScore) {
          stage.status = StageStatus.passed;
          final next = journey.stages.indexWhere((s) => !s.passed);
          journey.current = next < 0 ? journey.stages.length - 1 : next;
          if (journey.completed && journey.completedMs == 0) {
            journey.completedMs = now;
          }
        } else if (stage.isPlayAlong &&
            report.score < stage.passScore - 15 &&
            stage.tempo > 0.5) {
          // Too fast for now: the next attempt is a little slower.
          stage.tempo = math.max(0.5, stage.tempo - 0.1);
        }
      }
    }

    if (headline != null) {
      profile.diary.insert(
        0,
        TutorDiaryEntry(
          atMs: now,
          title: title ?? '',
          headline: headline,
          score: report.score,
          songId: songId,
        ),
      );
      if (profile.diary.length > 40) {
        profile.diary.removeRange(40, profile.diary.length);
      }
    }
    return profile;
  }

  // ---------------------------------------------------------- recommending

  /// Songs ordered by how good a next step they are for this player.
  List<TutorPick> recommend(
    SkillProfile profile,
    List<Song> songs, {
    SongCollection? collection,
  }) {
    final level = profile.level;
    final picks = <TutorPick>[];
    final totalTaste = profile.collections.values.fold<int>(0, (a, b) => a + b);
    for (final song in songs) {
      if (collection != null && song.collection != collection) continue;
      final journey = profile.journeys[song.id];
      final chords = song.hasMelody ? const <String>[] : song.uniqueChords;
      final known = chords.where(profile.knows).toList(growable: false);
      final fresh = chords.where((c) => !profile.knows(c)).toList();
      final freshBarres = fresh.where(isBarre).length;
      final playable = song.hasMelody || chords.isNotEmpty;

      var score = 100.0;
      final reasons = <String>[];

      if (journey != null && !journey.completed) {
        reasons.add(
          'You are ${journey.passedCount}/${journey.stages.length} steps in – '
          "let's finish it.",
        );
      } else if (journey != null && journey.completed) {
        score -= 45;
      }

      if (!song.hasMelody) {
        if (fresh.isEmpty) {
          score -= level == TutorLevel.firstDay ? 0 : 12;
          if (chords.isNotEmpty && journey == null) {
            reasons.add(
              'You already know all ${chords.length} chords – a fluency win.',
            );
          }
        } else {
          score -= known.isEmpty
              // Nothing known yet: a first song of 3–4 chords is ideal.
              ? 14.0 * (fresh.length - 3.5).abs()
              // Otherwise one new chord at a time (i + 1).
              : 22.0 * math.max(0, fresh.length - 1);
          if (fresh.length == 1 && known.isNotEmpty) {
            reasons.add(
              'You know ${known.take(4).join(', ')} – this adds just '
              '${fresh.first}.',
            );
          } else if (known.isNotEmpty) {
            reasons.add(
              'Builds on ${known.take(3).join(', ')} and adds '
              '${fresh.take(3).join(', ')}.',
            );
          } else {
            reasons.add(
              '${chords.length} friendly chords: ${chords.take(4).join(', ')}.',
            );
          }
        }
        // Barre chords are the big wall for beginners.
        score -= freshBarres * (level.index <= 1 ? 60.0 : 8.0);
        if (chords.length > 6) score -= (chords.length - 6) * 4.0;
        // Two-chord songs make a thin lesson.
        if (chords.length < 3) score -= 15;
      } else {
        reasons.add('A melody on single strings – great for finger accuracy.');
        // Chords come first for new players; melodies are the side dish.
        score -= level.index <= 1 ? 50 : 0;
      }

      score += switch ((level, song.difficulty)) {
        (TutorLevel.firstDay || TutorLevel.beginner, SongDifficulty.beginner) =>
          22,
        (TutorLevel.firstDay || TutorLevel.beginner, SongDifficulty.advanced) =>
          -45,
        (TutorLevel.firstDay || TutorLevel.beginner, _) => -12,
        (TutorLevel.improver, SongDifficulty.intermediate) => 16,
        (TutorLevel.improver, SongDifficulty.beginner) => 6,
        (TutorLevel.improver, SongDifficulty.advanced) => -18,
        (TutorLevel.confident, SongDifficulty.advanced) => 12,
        (TutorLevel.confident, SongDifficulty.intermediate) => 10,
        (TutorLevel.confident, SongDifficulty.beginner) => -6,
      };

      final shelf = song.collection?.name;
      if (shelf != null && totalTaste > 0) {
        score += 14 * (profile.collections[shelf] ?? 0) / totalTaste;
      }
      // Gentle preference for chord charts confirmed by several sources.
      if (song.tags.contains('verified')) score += 3;
      // Stable tie-break so the list doesn't shuffle on every rebuild.
      score -= (song.id.hashCode % 100) / 1000;

      // Nothing to play until a tab is pasted: always last.
      if (!playable) score = -1000;

      // A song the player chose and started always comes first.
      if (journey != null && !journey.completed) {
        score = 1000 + 100 * journey.progress;
      }

      picks.add(
        TutorPick(
          song: song,
          score: score,
          reason: reasons.isEmpty ? 'A good next challenge.' : reasons.first,
          newChords: fresh,
          knownChords: known,
          journey: journey,
        ),
      );
    }
    picks.sort((a, b) => b.score.compareTo(a.score));
    return picks;
  }

  // -------------------------------------------------------------- feedback

  /// What went well, what to fix, and where to go next.
  TutorFeedback feedback(
    SessionReport report, {
    required SkillProfile profile,
    SongJourney? journey,
    int? stageIndex,
  }) {
    final stage =
        journey != null &&
            stageIndex != null &&
            stageIndex >= 0 &&
            stageIndex < journey.stages.length
        ? journey.stages[stageIndex]
        : null;
    final pass = stage?.passScore ?? 70;
    final score = report.score;
    final wentWell = <String>[];
    final improve = <TutorTip>[];
    final melody = report.isMelody;
    String name(String t) => TabNote.display(t);

    // ------------------------------------------------ what went well
    final strong = report.chordResults.entries
        .where(
          (e) =>
              e.value.attempts > 0 &&
              e.value.successes == e.value.attempts &&
              e.value.avgMs > 0 &&
              e.value.avgMs < (report.isLearn ? 2500 : 900),
        )
        .map((e) => name(e.key))
        .toList();
    if (strong.isNotEmpty) {
      wentWell.add(
        report.isLearn
            ? '${_list(strong.take(4))} landed fast every time.'
            : '${_list(strong.take(4))} rang out right on the change.',
      );
    }
    final fast =
        report.transitions
            .where((t) => t.successes > 0 && t.fails == 0 && t.averageMs < 1800)
            .toList()
          ..sort((a, b) => a.averageMs.compareTo(b.averageMs));
    if (fast.isNotEmpty) {
      final t = fast.first;
      wentWell.add(
        'Your ${name(t.from)} → ${name(t.to)} change is quick '
        '(${_seconds(t.averageMs)}).',
      );
    }
    if (report.bestCombo >= 5) {
      wentWell.add(
        '${report.bestCombo} in a row without a slip – great focus.',
      );
    }
    final timingAccuracy = report.timingAccuracy;
    if (timingAccuracy != null && timingAccuracy >= 0.8) {
      wentWell.add(
        '${(timingAccuracy * 100).round()}% of your strums landed on the beat.',
      );
    }
    final direction = report.directionAccuracy;
    if (direction != null && direction >= 0.85) {
      wentWell.add('Your down/up strokes follow the pattern.');
    }
    final cents = report.averageCents;
    if (melody && cents != null && cents.abs() < 12) {
      wentWell.add('Your notes are in tune – clean fretting.');
    }
    if (report.skips == 0 && report.isLearn && report.successes > 0) {
      wentWell.add('No skips – you worked out every one yourself.');
    }

    // ------------------------------------------------ what to improve
    final slow = report.slowestTransitions
        .where(
          (t) => t.fails > 0 || t.averageMs > (report.isLearn ? 3500 : 900),
        )
        .take(2);
    for (final t in slow) {
      final from = name(t.from);
      final to = name(t.to);
      improve.add(
        TutorTip(
          t.fails > 0
              ? '$from → $to didn\'t land yet'
              : '$from → $to takes ${_seconds(t.averageMs)}',
          melody
              ? 'Practise just those two notes back and forth, slowly. Keep '
                    'your fingers hovering close to the strings.'
              : 'Do 10 slow swaps between $from and $to. Look for a finger '
                    'that can stay put or slide, and move the rest together '
                    'as one shape.',
          drillChords: melody ? null : <String>[t.from, t.to],
          drillLabel: melody ? null : 'Drill $from ↔ $to',
        ),
      );
    }

    final confusion = report.topConfusions
        .where((c) => c.count >= 1)
        .firstOrNull;
    if (confusion != null && !melody) {
      improve.add(
        TutorTip(
          '${confusion.target} sometimes sounds like ${confusion.heard}',
          ChordTheory.explainConfusion(
            confusion.target,
            confusion.heard,
            voicing: voicingFor?.call(confusion.target),
          ),
          drillChords: <String>[confusion.target],
          drillLabel: 'Polish ${confusion.target}',
        ),
      );
    }

    final skipped = report.chordResults.entries
        .where((e) => e.value.skips > 0)
        .map((e) => e.key)
        .toList();
    if (skipped.isNotEmpty && !melody) {
      improve.add(
        TutorTip(
          'Skipped: ${_list(skipped.take(3))}',
          "Tap 'Hear it' to hear the target, then build the shape one finger "
              'at a time. Strum, listen, adjust.',
          drillChords: skipped.take(3).toList(),
          drillLabel: 'Practise ${skipped.take(3).join(' ')}',
        ),
      );
    }

    final mean = report.meanOffsetMs;
    final spread = report.offsetSpreadMs;
    if (mean != null && mean < -45) {
      improve.add(
        TutorTip(
          'You rush the beat (${mean.round().abs()} ms early)',
          'Count "1 & 2 & 3 & 4 &" out loud and let the strum fall exactly '
              'on the click. Relaxed shoulders help.',
        ),
      );
    } else if (mean != null && mean > 45) {
      improve.add(
        TutorTip(
          'You drag behind the beat (${mean.round()} ms late)',
          'Prepare the next chord during the last strum of the bar, and '
              'keep the strumming arm moving even while you change.',
        ),
      );
    }
    if (spread != null && spread > 75) {
      improve.add(
        TutorTip(
          'Your rhythm wobbles (±${spread.round()} ms)',
          'Play just down-strokes on one chord with the metronome at 60 BPM '
              'for a minute, then add the up-strokes back in.',
        ),
      );
    }
    if (report.judgedStrums >= 8 &&
        report.timingMisses / report.judgedStrums > 0.3) {
      final ups = report.upStrokesMissed;
      final downs = report.downStrokesMissed;
      improve.add(
        TutorTip(
          'Missing ${(100 * report.timingMisses / report.judgedStrums).round()}% '
          'of the strokes',
          ups > downs * 1.5
              ? 'Mostly the up-strokes. Keep your hand swinging down-up like '
                    'a pendulum and just brush the top 3 strings on the way up.'
              : 'Keep the arm moving all the time – on rests, swing past the '
                    'strings without touching them (a "ghost strum").',
        ),
      );
    }
    if (direction != null && direction < 0.7) {
      improve.add(
        const TutorTip(
          'Up and down strokes are mixed up',
          'Every "D" is a down-stroke and every "U" an up-stroke. Your hand '
              'goes down on the beat and up on the "&".',
        ),
      );
    }

    final posture = report.topPostureHints
        .where(
          (h) => report.shapeChecks >= 10 && h.value / report.shapeChecks > 0.3,
        )
        .take(1);
    for (final hint in posture) {
      improve.add(
        TutorTip(
          'What I saw: ${hint.key}',
          'This showed up in ${(100 * hint.value / report.shapeChecks).round()}% '
              'of the moments I could see your hand.',
        ),
      );
    }
    final visible = report.handVisibleRatio;
    if (visible != null && visible < 0.5) {
      improve.add(
        TutorTip(
          'I could only see your fretting hand ${(visible * 100).round()}% of '
              'the time',
          'Tilt the camera so the neck and your whole fretting hand are in '
              'frame – then I can coach your fingers too.',
        ),
      );
    }
    if (report.averageLevel > 0 && report.averageLevel < 0.25) {
      improve.add(
        const TutorTip(
          'You are playing very softly',
          'Strum a little firmer (or move closer to the mic) so every string '
              'rings – I hear chords better and so will your audience.',
        ),
      );
    }
    if (melody) {
      if (cents != null && cents > 18) {
        improve.add(
          TutorTip(
            'Notes ring sharp (+${cents.round()} cents)',
            'You are pressing too hard or pushing the string sideways. '
                'Press just enough, right behind the fret wire.',
          ),
        );
      } else if (cents != null && cents < -18) {
        improve.add(
          TutorTip(
            'Notes ring flat (${cents.round()} cents)',
            'Check your tuning first (Tuner), then press closer to the fret.',
          ),
        );
      }
      final offByOne = report.noteSemitoneErrors.where((e) => e.abs() == 1);
      if (offByOne.length >= 2) {
        improve.add(
          TutorTip(
            '${offByOne.length} notes were one fret off',
            'Use one finger per fret: in this tune your index sits on '
                'the lowest fret and each finger owns the next fret up.',
          ),
        );
      }
    }

    // ------------------------------------------------ verdict & next step
    final TutorVerdict verdict;
    int? next;
    String? nextLabel;
    final String headline;
    if (stage == null || journey == null) {
      verdict = score >= pass ? TutorVerdict.advance : TutorVerdict.repeat;
      headline = score >= 85
          ? 'Excellent session!'
          : score >= pass
          ? 'Good work – that is coming together.'
          : 'Good effort. Let\'s polish the tricky bits.';
    } else if (score >= pass) {
      final index = stageIndex!;
      final upcoming = index + 1 < journey.stages.length ? index + 1 : null;
      if (upcoming == null) {
        verdict = TutorVerdict.finished;
        headline = '🎉 You can play it! Song complete.';
      } else {
        verdict = TutorVerdict.advance;
        next = upcoming;
        nextLabel = 'Next: ${journey.stages[upcoming].title}';
        headline = 'Step passed with ${score.round()}%!';
      }
    } else if (score >= pass - 15) {
      verdict = TutorVerdict.repeat;
      next = stageIndex;
      nextLabel = 'One more go';
      headline =
          'So close – ${score.round()}% (need ${pass.round()}%). One more try.';
    } else {
      verdict = TutorVerdict.easier;
      next = stageIndex;
      nextLabel = stage.isPlayAlong
          ? 'Try again a little slower'
          : 'Try again – take your time';
      headline = stage.isPlayAlong
          ? "Let's slow it down and build it up."
          : "Let's break it down and build it up.";
    }

    if (wentWell.isEmpty && report.successes > 0) {
      wentWell.add(
        'You stuck with it – every session builds the muscle memory.',
      );
    }

    return TutorFeedback(
      headline: headline,
      verdict: verdict,
      score: score,
      passScore: stage?.passScore,
      wentWell: wentWell.take(4).toList(growable: false),
      improve: improve.take(4).toList(growable: false),
      style: styleNotes(profile),
      nextStageIndex: next,
      nextLabel: nextLabel,
    );
  }

  /// Long-term observations about how the player plays.
  List<String> styleNotes(SkillProfile profile) {
    final notes = <String>[];
    final timing = profile.timing;
    if (timing.samples >= 2) {
      if (timing.offsetMs < -35) {
        notes.add(
          'You tend to rush – about ${timing.offsetMs.round().abs()} ms ahead '
          'of the beat across ${timing.samples} sessions.',
        );
      } else if (timing.offsetMs > 35) {
        notes.add(
          'You tend to lay back behind the beat (~${timing.offsetMs.round()} ms).',
        );
      } else {
        notes.add('Your sense of time is centred on the beat.');
      }
      if (timing.spreadMs > 0 && timing.spreadMs < 50) {
        notes.add('Your strumming is very even.');
      }
    }
    if (timing.directionSamples >= 2 && timing.direction < 0.7) {
      notes.add('Up-strokes are the weak side of your strumming hand.');
    }
    final known = profile.knownChords;
    if (known.isNotEmpty) {
      notes.add(
        'Strongest chords: ${known.take(5).map((c) => TabNote.display(c.name)).join(', ')}.',
      );
    }
    final slowest =
        profile.transitions.values
            .where((t) => t.averageMs > 0 && !TabNote.isToken(t.from))
            .toList()
          ..sort((a, b) => b.averageMs.compareTo(a.averageMs));
    if (slowest.isNotEmpty && slowest.first.averageMs > 2500) {
      final t = slowest.first;
      notes.add(
        'Slowest change to work on: ${t.from} → ${t.to} '
        '(${_seconds(t.averageMs)}).',
      );
    }
    final posture = profile.style.posture.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (posture.isNotEmpty && posture.first.value > 0.3) {
      notes.add('Recurring habit: ${posture.first.key}');
    }
    final style = profile.style;
    if (style.steps >= 20 && style.skips / style.steps > 0.25) {
      notes.add('You skip quite often – try "Hear it" before skipping.');
    }
    if (style.pitchSamples >= 2 && style.pitchCents.abs() > 15) {
      notes.add(
        style.pitchCents > 0
            ? 'Single notes tend to ring sharp – lighter fingers.'
            : 'Single notes tend to ring flat – check tuning.',
      );
    }
    final taste = profile.collections.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (taste.isNotEmpty) {
      notes.add('Favourite shelf: ${_shelf(taste.first.key)}.');
    }
    return notes;
  }

  static String _shelf(String name) => switch (name) {
    'bollywood' => 'Bollywood',
    'global' => 'Global hits',
    'band' => 'Band music',
    'instrumental' => 'Instrumental & devotional',
    _ => name,
  };

  static String _seconds(int ms) => '${(ms / 1000).toStringAsFixed(1)} s';

  static String _list(Iterable<String> items) {
    final list = items.toList();
    if (list.length <= 1) return list.join();
    return '${list.sublist(0, list.length - 1).join(', ')} and ${list.last}';
  }
}
