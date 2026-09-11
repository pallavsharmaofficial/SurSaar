import 'package:flutter_test/flutter_test.dart';
import 'package:sursaar/teacher/analysis/guitar_pose.dart';
import 'package:sursaar/teacher/models/hand_frame.dart';

Hand handAt(Offset wrist, Handedness handedness, {double score = 0.9}) {
  return Hand(
    handedness: handedness,
    score: score,
    landmarks: List<HandLandmark>.generate(
      21,
      (i) => HandLandmark(wrist.dx + i * 0.002, wrist.dy - i * 0.002),
      growable: false,
    ),
  );
}

HandFrame frameOf(List<Hand> hands) =>
    HandFrame(hands: hands, timestampMs: 0, imageWidth: 1280, imageHeight: 720);

void main() {
  group('GuitarPoseTracker', () {
    test('two hands give a neck line and a body to play sound from', () {
      final tracker = GuitarPoseTracker();
      // right-handed: fretting hand (left) up the neck, strumming hand lower
      final frame = frameOf(<Hand>[
        handAt(const Offset(0.25, 0.45), Handedness.left),
        handAt(const Offset(0.65, 0.62), Handedness.right),
      ]);
      var pose = tracker.update(frame);
      for (var i = 0; i < 10; i++) {
        pose = tracker.update(frame);
      }

      expect(pose.hasNeck, isTrue);
      expect(pose.hint, isNull);
      expect(pose.confidence, greaterThan(0.4));
      // headstock beyond the fretting hand, body beyond the strumming hand
      expect(pose.neckStart.dx, lessThan(0.25));
      expect(pose.neckEnd.dx, greaterThan(0.65));
      expect(pose.bodyAnchor.dx, greaterThan(0.65));
      expect(pose.bodyAnchor.dy, greaterThan(0.62));
      expect(pose.angle, greaterThan(0));
    });

    test('one hand asks for the other, without a neck line', () {
      final tracker = GuitarPoseTracker();
      final pose = tracker.update(
        frameOf(<Hand>[handAt(const Offset(0.4, 0.5), Handedness.left)]),
      );
      expect(pose.hasNeck, isFalse);
      expect(pose.hint, contains('both hands'));
    });

    test('no hands falls back to the bottom of the frame', () {
      final pose = GuitarPoseTracker().update(frameOf(const <Hand>[]));
      expect(pose.bodyAnchor, const Offset(0.5, 0.82));
      expect(pose.hint, contains('Hold your guitar'));
      expect(pose.confidence, 0);
    });

    test('hands almost on top of each other asks the learner to move back', () {
      final pose = GuitarPoseTracker().update(
        frameOf(<Hand>[
          handAt(const Offset(0.50, 0.50), Handedness.left),
          handAt(const Offset(0.52, 0.51), Handedness.right),
        ]),
      );
      expect(pose.hasNeck, isFalse);
      expect(pose.hint, contains('Move back'));
    });

    test('left-handed players are mirrored', () {
      final tracker = GuitarPoseTracker(leftHanded: true);
      final frame = frameOf(<Hand>[
        handAt(const Offset(0.7, 0.45), Handedness.right),
        handAt(const Offset(0.3, 0.62), Handedness.left),
      ]);
      var pose = tracker.update(frame);
      for (var i = 0; i < 10; i++) {
        pose = tracker.update(frame);
      }
      expect(pose.hasNeck, isTrue);
      expect(pose.bodyAnchor.dx, lessThan(0.3));
    });
  });

  test('landmarks are smoothed between frames', () {
    final first = frameOf(<Hand>[
      handAt(const Offset(0.2, 0.2), Handedness.left),
    ]);
    final second = frameOf(<Hand>[
      handAt(const Offset(0.4, 0.2), Handedness.left),
    ]);
    final smoothed = second.smoothedFrom(first);
    expect(smoothed.hands.first.wrist.x, closeTo(0.3, 0.001));
    // a different number of hands is passed through untouched
    expect(
      second.smoothedFrom(frameOf(const <Hand>[])).hands.first.wrist.x,
      0.4,
    );
  });
}
