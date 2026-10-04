import 'package:flutter_test/flutter_test.dart';
import 'package:sursaar/data/content/chord_library.dart';
import 'package:sursaar/models/song.dart';
import 'package:sursaar/models/song_section.dart';
import 'package:sursaar/models/strumming_pattern.dart';
import 'package:sursaar/teacher/engine/performance_recorder.dart';
import 'package:sursaar/teacher/engine/practice_plan.dart';
import 'package:sursaar/teacher/melody/melody_tab.dart';
import 'package:sursaar/teacher/models/strum_event.dart';
import 'package:sursaar/tutor/chord_theory.dart';
import 'package:sursaar/tutor/journey.dart';
import 'package:sursaar/tutor/skill_profile.dart';
import 'package:sursaar/tutor/tutor_brain.dart';

Song song(
  String id,
  List<String> chords, {
  SongDifficulty difficulty = SongDifficulty.beginner,
  SongCollection collection = SongCollection.bollywood,
  String? tabs,
}) => Song(
  id: id,
  title: id,
  artist: 'Artist',
  difficulty: difficulty,
  strummingPattern: 'D DU UDU',
  originalChords: chords,
  bpm: 100,
  collection: collection,
  tabs: tabs,
  sections: <SongSection>[
    SongSection(
      name: 'Verse',
      repeat: 2,
      lines: <SongLine>[SongLine.chords(chords)],
    ),
    SongSection(
      name: 'Chorus',
      lines: <SongLine>[SongLine.chords(chords.reversed.toList())],
    ),
  ],
);

SessionReport report({
  double score = 80,
  Map<String, ({int attempts, int successes, int avgMs, int skips})>? chords,
  void Function(PerformanceRecorder r)? record,
  bool learn = true,
  bool melody = false,
}) {
  final recorder = PerformanceRecorder();
  record?.call(recorder);
  return recorder.build(
    isLearn: learn,
    isMelody: melody,
    bpm: 80,
    durationMs: 120000,
    score: score,
    successes: chords?.values.fold<int>(0, (a, b) => a + b.successes) ?? 4,
    skips: chords?.values.fold<int>(0, (a, b) => a + b.skips) ?? 0,
    bestCombo: 3,
    chordResults: chords ?? const {},
    strums: 20,
  );
}

SkillProfile knowing(List<String> chords) => SkillProfile(
  sessions: 3,
  chords: <String, ChordSkill>{
    for (final c in chords) c: ChordSkill(c, mastery: 0.9, sessions: 3),
  },
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ChordLibrary library;
  late TutorBrain brain;

  setUpAll(() async {
    library = await ChordLibrary.loadFromAsset();
    brain = TutorBrain(voicingFor: library.voicingFor);
  });

  group('ChordTheory', () {
    test('chord tones', () {
      expect(ChordTheory.tones('Am'), <int>{9, 0, 4});
      expect(ChordTheory.tones('G7'), <int>{7, 11, 2, 5});
      expect(ChordTheory.tones('D/F#'), <int>{2, 6, 9});
      expect(ChordTheory.tones('Bbm'), <int>{10, 1, 5});
    });

    test(
      'explains a confusion with the strings that carry the missing note',
      () {
        final text = ChordTheory.explainConfusion(
          'Am',
          'C',
          voicing: library.voicingFor('Am'),
        );
        expect(text, contains("I'm not hearing the A note"));
        expect(text, contains('hear G instead'));
        expect(text, contains('share 2 notes'));
        expect(text, contains('A string'));
      },
    );

    test('knows barre chords', () {
      expect(ChordTheory.isBarre(library.voicingFor('F')), isTrue);
      expect(ChordTheory.isBarre(library.voicingFor('G')), isFalse);
      expect(brain.isBarre('Bm'), isTrue);
      expect(brain.isBarre('n:4:3'), isFalse);
    });
  });

  group('recommend', () {
    final songs = <Song>[
      song('easy_known', <String>['G', 'C', 'D']),
      song('plus_one', <String>['G', 'C', 'D', 'Em']),
      song('three_new', <String>['F', 'Bm', 'A#', 'G']),
      song('advanced', <String>[
        'G',
        'C',
        'D',
        'Em',
      ], difficulty: SongDifficulty.advanced),
    ];

    test('first day: friendly beginner songs, no barres', () {
      final picks = brain.recommend(SkillProfile(), songs);
      expect(picks.first.song.difficulty, SongDifficulty.beginner);
      expect(picks.last.song.id, anyOf('three_new', 'advanced'));
      expect(
        picks.indexWhere((p) => p.song.id == 'three_new'),
        greaterThan(picks.indexWhere((p) => p.song.id == 'easy_known')),
      );
    });

    test('i+1: one new chord on top of known ones wins', () {
      final picks = brain.recommend(knowing(<String>['G', 'C', 'D']), songs);
      expect(picks.first.song.id, 'plus_one');
      expect(picks.first.newChords, <String>['Em']);
      expect(picks.first.reason, contains('adds just Em'));
      expect(picks.first.readiness, 0.75);
    });

    test('an unfinished journey comes first', () {
      final profile = knowing(<String>['G', 'C', 'D'])
        ..journeys['three_new'] = JourneyBuilder.build(
          songs[2],
          SkillProfile(),
          nowMs: 1,
        );
      final picks = brain.recommend(profile, songs);
      expect(picks.first.song.id, 'three_new');
      expect(picks.first.inProgress, isTrue);
      expect(picks.first.reason, contains('steps in'));
    });

    test('filters by collection', () {
      final mixed = <Song>[
        ...songs,
        song('hit', <String>['G', 'C'], collection: SongCollection.global),
      ];
      final picks = brain.recommend(
        SkillProfile(),
        mixed,
        collection: SongCollection.global,
      );
      expect(picks.map((p) => p.song.id), <String>['hit']);
    });
  });

  group('journey', () {
    test(
      'a new player meets chords, drills changes, grooves, then performs',
      () {
        final s = song('j', <String>['G', 'C', 'D', 'Em']);
        final journey = JourneyBuilder.build(
          s,
          SkillProfile(),
          isBarre: brain.isBarre,
          nowMs: 1,
        );
        final kinds = journey.stages.map((st) => st.kind).toList();
        expect(kinds.first, StageKind.meetChords);
        expect(kinds, contains(StageKind.changes));
        expect(kinds, contains(StageKind.groove));
        expect(
          journey.stages
              .where((st) => st.kind == StageKind.section)
              .map((st) => st.section),
          <String>['Verse', 'Chorus'],
        );
        expect(kinds[kinds.length - 2], StageKind.slowPlay);
        expect(kinds.last, StageKind.perform);
        expect(journey.stages.last.tempo, 0.85);
      },
    );

    test('a player who knows the chords skips straight to the song', () {
      final s = song('j', <String>['G', 'C']);
      final profile = knowing(<String>['G', 'C'])
        ..transitions['G>C'] = TransitionSkill(
          'G',
          'C',
          averageMs: 900,
          count: 5,
        )
        ..transitions['C>G'] = TransitionSkill(
          'C',
          'G',
          averageMs: 900,
          count: 5,
        );
      final journey = JourneyBuilder.build(s, profile, nowMs: 1);
      expect(journey.stages.first.kind, StageKind.groove);
      expect(
        journey.stages.where((st) => st.kind == StageKind.changes),
        isEmpty,
      );
    });

    test('stages become practice plans', () {
      final s = song('j', <String>['G', 'C', 'D']);
      final journey = JourneyBuilder.build(s, SkillProfile(), nowMs: 1);
      for (final stage in journey.stages) {
        final plan = JourneyBuilder.planFor(s, stage);
        expect(plan.targets, isNotEmpty, reason: stage.title);
        expect(plan.sourceId, 'j');
      }
      final changes = journey.stages.firstWhere(
        (st) => st.kind == StageKind.changes,
      );
      expect(JourneyBuilder.planFor(s, changes).learnSteps, changes.sequence);
      final verse = journey.stages.firstWhere((st) => st.section == 'Verse');
      expect(JourneyBuilder.planFor(s, verse).learnSteps, <String>[
        'G',
        'C',
        'D',
      ]);
      final slow = journey.stages.firstWhere(
        (st) => st.kind == StageKind.slowPlay,
      );
      expect(JourneyBuilder.planFor(s, slow).bpm, 60);
    });

    test('melody songs get note stages', () {
      final s = song(
        'tune',
        <String>['C', 'G'],
        collection: SongCollection.instrumental,
        tabs: '[Sthayi]\nB|--1--3--1--0--|\n[Antara]\ne|--0--1--3--|',
      );
      final journey = JourneyBuilder.build(s, SkillProfile(), nowMs: 1);
      final kinds = journey.stages.map((st) => st.kind).toList();
      expect(kinds.first, StageKind.meetNotes);
      expect(kinds.where((k) => k == StageKind.phrase).length, 2);
      expect(kinds, contains(StageKind.groove));
      expect(kinds.last, StageKind.melodyPerform);
      final meet = JourneyBuilder.planFor(s, journey.stages.first);
      expect(meet.isMelody, isTrue);
      expect(meet.learnSteps.first, const TabNote(string: 4, fret: 0).token);
      final phrase = JourneyBuilder.planFor(s, journey.stages[1]);
      expect(phrase.learnSteps.length, 4);
    });

    test('journeys survive a JSON round-trip', () {
      final s = song('j', <String>['G', 'C', 'D', 'Em']);
      final profile = SkillProfile()
        ..journeys['j'] = JourneyBuilder.build(s, SkillProfile(), nowMs: 1);
      final back = SkillProfile.fromJson(profile.toJson());
      expect(
        back.journeys['j']!.stages.map((st) => st.title),
        profile.journeys['j']!.stages.map((st) => st.title),
      );
    });
  });

  group('applyReport', () {
    test('mastery rises with fast clean chords and falls with skips', () {
      var profile = SkillProfile();
      for (var i = 0; i < 3; i++) {
        profile = brain.applyReport(
          profile,
          report(
            chords: {
              'G': (attempts: 4, successes: 4, avgMs: 1500, skips: 0),
              'F': (attempts: 4, successes: 1, avgMs: 9000, skips: 3),
            },
          ),
          nowMs: 1000 + i,
        );
      }
      expect(profile.knows('G'), isTrue);
      expect(profile.knows('F'), isFalse);
      expect(profile.sessions, 3);
      expect(profile.level, TutorLevel.beginner);
    });

    test('timing habits and transitions accumulate', () {
      final profile = brain.applyReport(
        SkillProfile(),
        report(
          learn: false,
          record: (r) {
            for (var i = 0; i < 8; i++) {
              r.timing(
                SlotTiming(
                  absoluteSlot: i,
                  slotInPattern: i,
                  expectedMs: i * 300,
                  actualMs: i * 300 - 70,
                  result: TimingResult.hit,
                  expectedStroke: StrokeType.down,
                  playedStroke: StrokeType.down,
                ),
              );
            }
            r.transition('C', 'G', ms: 3000);
          },
        ),
        nowMs: 1,
      );
      expect(profile.timing.offsetMs, closeTo(-70, 0.01));
      expect(profile.transitions['C>G']!.averageMs, 3000);
      expect(
        brain.styleNotes(profile).join(' '),
        isNot(contains('Strongest')),
        reason: 'no chords known yet',
      );
    });

    test('passing a journey stage moves the journey on; failing slows it', () {
      final s = song('j', <String>['G', 'C']);
      var profile = SkillProfile()
        ..journeys['j'] = JourneyBuilder.build(s, SkillProfile(), nowMs: 1);
      final slowIndex = profile.journeys['j']!.stages.indexWhere(
        (st) => st.kind == StageKind.slowPlay,
      );
      profile = brain.applyReport(
        profile,
        report(score: 40, learn: false),
        songId: 'j',
        stageIndex: slowIndex,
        nowMs: 2,
      );
      final stage = profile.journeys['j']!.stages[slowIndex];
      expect(stage.passed, isFalse);
      expect(stage.tempo, closeTo(0.5, 1e-9));
      expect(stage.attempts, 1);

      profile = brain.applyReport(
        profile,
        report(score: 95),
        songId: 'j',
        stageIndex: 0,
        nowMs: 3,
        headline: 'Step passed',
        title: 'Meet',
      );
      final journey = profile.journeys['j']!;
      expect(journey.stages.first.passed, isTrue);
      expect(journey.current, 1);
      expect(profile.diary.first.headline, 'Step passed');
    });
  });

  group('feedback', () {
    test('praises strengths, points at slow changes and confusions', () {
      final r = report(
        score: 72,
        chords: {
          'G': (attempts: 2, successes: 2, avgMs: 1200, skips: 0),
          'C': (attempts: 2, successes: 2, avgMs: 1400, skips: 0),
          'Am': (attempts: 2, successes: 1, avgMs: 6000, skips: 1),
        },
        record: (r) {
          r.transition('G', 'C', ms: 1100);
          r.transition('C', 'Am', ms: 6000);
          r.transition('Am', 'G');
          for (var i = 0; i < 3; i++) {
            r.confusion('Am', 'C');
          }
          r.newStep();
        },
      );
      final fb = brain.feedback(r, profile: SkillProfile());
      expect(fb.wentWell.join(' '), contains('G and C landed fast'));
      expect(fb.wentWell.join(' '), contains('G → C change is quick'));
      expect(fb.improve.first.title, "Am → G didn't land yet");
      expect(fb.improve.first.drillChords, <String>['Am', 'G']);
      final confusion = fb.improve.firstWhere(
        (t) => t.title.contains('sounds like'),
      );
      expect(confusion.title, 'Am sometimes sounds like C');
      expect(confusion.detail, contains('A note'));
      expect(fb.improve.any((t) => t.title.startsWith('Skipped: Am')), isTrue);
    });

    test('timing: rushing and missed up-strokes', () {
      final r = report(
        learn: false,
        record: (r) {
          for (var i = 0; i < 10; i++) {
            r.timing(
              SlotTiming(
                absoluteSlot: i,
                slotInPattern: i % 8,
                expectedMs: i * 300,
                actualMs: i * 300 - 80,
                result: TimingResult.early,
                expectedStroke: StrokeType.down,
              ),
            );
          }
          for (var i = 0; i < 8; i++) {
            r.timing(
              SlotTiming(
                absoluteSlot: 20 + i,
                slotInPattern: 1,
                expectedMs: 0,
                result: TimingResult.miss,
                expectedStroke: StrokeType.up,
              ),
            );
          }
        },
      );
      final fb = brain.feedback(r, profile: SkillProfile());
      final titles = fb.improve.map((t) => t.title).join(' | ');
      expect(titles, contains('You rush the beat (80 ms early)'));
      expect(titles, contains('Missing 44% of the strokes'));
      expect(
        fb.improve.firstWhere((t) => t.title.startsWith('Missing')).detail,
        contains('up-strokes'),
      );
    });

    test('melody: sharp notes and one-fret slips', () {
      final r = report(
        melody: true,
        record: (r) {
          for (var i = 0; i < 4; i++) {
            r.noteInTune(25);
          }
          r.wrongNote(1);
          r.wrongNote(-1);
        },
      );
      final fb = brain.feedback(r, profile: SkillProfile());
      final titles = fb.improve.map((t) => t.title).join(' | ');
      expect(titles, contains('Notes ring sharp (+25 cents)'));
      expect(titles, contains('2 notes were one fret off'));
    });

    test('verdicts follow the stage pass mark', () {
      final s = song('j', <String>['G', 'C']);
      final journey = JourneyBuilder.build(s, SkillProfile(), nowMs: 1);
      final profile = SkillProfile()..journeys['j'] = journey;
      final pass = journey.stages.first.passScore;

      final advance = brain.feedback(
        report(score: pass + 5),
        profile: profile,
        journey: journey,
        stageIndex: 0,
      );
      expect(advance.verdict, TutorVerdict.advance);
      expect(advance.nextStageIndex, 1);
      expect(advance.nextLabel, startsWith('Next: '));

      final close = brain.feedback(
        report(score: pass - 5),
        profile: profile,
        journey: journey,
        stageIndex: 0,
      );
      expect(close.verdict, TutorVerdict.repeat);
      expect(close.nextStageIndex, 0);

      final far = brain.feedback(
        report(score: 10),
        profile: profile,
        journey: journey,
        stageIndex: 0,
      );
      expect(far.verdict, TutorVerdict.easier);

      final last = journey.stages.length - 1;
      final done = brain.feedback(
        report(score: 99),
        profile: profile,
        journey: journey,
        stageIndex: last,
      );
      expect(done.verdict, TutorVerdict.finished);
    });
  });

  test('melody plan sanity', () {
    final plan = PracticePlan.forMelody(const <TabNote>[
      TabNote(string: 5, fret: 0),
    ], title: 't');
    expect(plan.isMelody, isTrue);
  });
}
