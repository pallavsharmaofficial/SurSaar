import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sursaar/teacher/analysis/note_detector.dart';
import 'package:sursaar/teacher/melody/melody_tab.dart';
import 'package:sursaar/teacher/melody/tab_parser.dart';
import 'package:sursaar/teacher/models/audio_frame.dart';

/// A plucked string: decaying fundamental plus a few harmonics.
Float32List pluck(double hz, int sampleRate, double seconds) {
  final n = (sampleRate * seconds).round();
  final out = Float32List(n);
  for (var i = 0; i < n; i++) {
    final t = i / sampleRate;
    final env = math.exp(-2.5 * t);
    var v = 0.0;
    for (var h = 1; h <= 4; h++) {
      v += math.sin(2 * math.pi * hz * h * t) / (h * h);
    }
    out[i] = (0.3 * env * v).toDouble();
  }
  return out;
}

List<AudioFrame> frames(Float32List samples, int sampleRate) {
  const size = 1024;
  return <AudioFrame>[
    for (var i = 0; i + size <= samples.length; i += size)
      AudioFrame(
        samples: Float32List.sublistView(samples, i, i + size),
        sampleRate: sampleRate,
        timestampMs: (i * 1000 / sampleRate).round(),
      ),
  ];
}

void main() {
  group('TabNote', () {
    test('pitch, tokens and labels', () {
      const note = TabNote(string: 4, fret: 3);
      expect(note.midi, 62);
      expect(note.noteName, 'D4');
      expect(note.token, 'n:4:3');
      expect(TabNote.fromToken('n:4:3')!.midi, 62);
      expect(TabNote.isToken('G'), isFalse);
      expect(TabNote.display('n:4:3'), 'B3');
      expect(TabNote.display('Am'), 'Am');
      expect(note.placement, 'B string · 3rd fret');
    });

    test('one-finger-per-fret voicing from the box position', () {
      const note = TabNote(string: 3, fret: 7);
      final voicing = note.voicing(boxStart: 5);
      expect(voicing.frets[3], 7);
      expect(voicing.fingers[3], 3);
      expect(voicing.frets.where((f) => f >= 0).length, 1);
    });
  });

  group('TabParser', () {
    test('reads a six-string block, highest string wins a column', () {
      const tab = '''
[Intro]
e|-------0-----|
B|---1-------3-|
G|-------------|
D|-------------|
A|---3---------|
E|-------------|
''';
      final melody = TabParser.parse(tab);
      expect(melody.notes.map((n) => n.shortLabel).toList(), <String>[
        'B1',
        'e0',
        'B3',
      ]);
      expect(melody.notes.first.section, 'Intro');
      expect(melody.notes.first.beats, 1);
    });

    test('single-string tabs, double-digit frets and sections', () {
      const tab = '''
Sthayi:
B|--5--7--8--10--8--|

Antara:
G|--7-5-4--|
''';
      final melody = TabParser.parse(tab);
      expect(melody.notes.map((n) => n.fret).toList(), <int>[
        5,
        7,
        8,
        10,
        8,
        7,
        5,
        4,
      ]);
      expect(melody.sections, <String>['Sthayi', 'Antara']);
      expect(melody.notes.every((n) => n.string == 4 || n.string == 3), isTrue);
      expect(melody.boxStart, 4);
    });

    test('spacing becomes rhythm relative to the common gap', () {
      const tab = 'e|--0--0--0-----3--|';
      final melody = TabParser.parse(tab);
      expect(melody.notes.map((n) => n.beats).toList(), <double>[1, 1, 2, 1]);
    });

    test('format and parse round-trip', () {
      const notes = <TabNote>[
        TabNote(string: 4, fret: 1, beats: 1, section: 'A'),
        TabNote(string: 4, fret: 3, beats: 2, section: 'A'),
        TabNote(string: 5, fret: 0, beats: 1, section: 'B'),
        TabNote(string: 3, fret: 2, beats: 1, section: 'B'),
      ];
      final text = TabParser.format(notes);
      final back = TabParser.parse(text).notes;
      expect(back.map((n) => n.token), notes.map((n) => n.token));
      expect(back.map((n) => n.section), notes.map((n) => n.section));
      expect(back[0].beats, 1);
      expect(back[1].beats, 2);
    });

    test('ignores lyrics and chord lines', () {
      expect(TabParser.looksLikeTab('G   C   D\nsome words here'), isFalse);
      expect(TabParser.parse('Am  F  C  G').isEmpty, isTrue);
    });
  });

  group('NoteDetector', () {
    for (final rate in <int>[44100, 48000]) {
      test('hears a plucked D4 at $rate Hz', () {
        final detector = NoteDetector(sampleRate: rate);
        final detections = <NoteDetection>[];
        for (final f in frames(pluck(293.66, rate, 0.6), rate)) {
          detections.addAll(detector.feed(f));
        }
        final voiced = detections.where((d) => !d.isSilent).toList();
        expect(voiced.length, greaterThan(5));
        expect(voiced.last.midi, 62);
        expect(voiced.last.cents.abs(), lessThan(15));
      });
    }

    test('low E and high frets stay in range', () {
      const rate = 48000;
      for (final midi in <int>[40, 52, 76]) {
        final detector = NoteDetector(sampleRate: rate);
        final hz = NoteName.frequency(midi);
        final voiced = <NoteDetection>[
          for (final f in frames(pluck(hz, rate, 0.6), rate))
            ...detector.feed(f).where((d) => !d.isSilent),
        ];
        expect(voiced, isNotEmpty, reason: 'midi $midi');
        expect(voiced.last.midi, midi, reason: 'midi $midi');
      }
    });

    test('silence is silent', () {
      final detector = NoteDetector(sampleRate: 48000);
      final out = <NoteDetection>[
        for (final f in frames(Float32List(48000), 48000)) ...detector.feed(f),
      ];
      expect(out.every((d) => d.isSilent), isTrue);
    });
  });
}
