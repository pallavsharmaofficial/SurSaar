import 'package:equatable/equatable.dart';

import 'coaching_mode.dart';

/// Learner preferences that shape the AI teacher session.
class UserSettings extends Equatable {
  const UserSettings({
    this.leftHanded = false,
    this.mirrorCamera = true,
    this.metronomeEnabled = true,
    this.defaultBpm = 80,
    this.showHandOverlay = true,
    this.coachingMode = CoachingMode.learn,
    this.voiceEnabled = true,
    this.onboardingSeen = false,
    this.showHandSkeleton = true,
    this.showFingerGuides = true,
    this.showNeckGuide = true,
    this.showSoundField = true,
    this.showCoachMessages = true,
    this.showBeatDots = true,
    this.showStatusChips = true,
  });

  factory UserSettings.fromMap(Map<String, dynamic> map) => UserSettings(
    leftHanded: map['left_handed'] as bool? ?? false,
    mirrorCamera: map['mirror_camera'] as bool? ?? true,
    metronomeEnabled: map['metronome_enabled'] as bool? ?? true,
    defaultBpm: (map['default_bpm'] as num?)?.toInt() ?? 80,
    showHandOverlay: map['show_hand_overlay'] as bool? ?? true,
    coachingMode: CoachingMode.parse(map['coaching_mode'] as String?),
    voiceEnabled: map['voice_enabled'] as bool? ?? true,
    onboardingSeen: map['onboarding_seen'] as bool? ?? false,
  );

  final bool leftHanded;
  final bool mirrorCamera;

  /// Metronome clicks in play-along mode (learn mode is quiet by default).
  final bool metronomeEnabled;
  final int defaultBpm;
  final bool showHandOverlay;
  final CoachingMode coachingMode;

  /// Spoken coaching ("Now play C").
  final bool voiceEnabled;
  final bool onboardingSeen;

  // Which live elements are drawn over the camera.
  final bool showHandSkeleton;
  final bool showFingerGuides;
  final bool showNeckGuide;
  final bool showSoundField;
  final bool showCoachMessages;
  final bool showBeatDots;
  final bool showStatusChips;

  Map<String, dynamic> toMap() => <String, dynamic>{
    'left_handed': leftHanded,
    'mirror_camera': mirrorCamera,
    'metronome_enabled': metronomeEnabled,
    'default_bpm': defaultBpm,
    'show_hand_overlay': showHandOverlay,
    'coaching_mode': coachingMode.name,
    'voice_enabled': voiceEnabled,
    'onboarding_seen': onboardingSeen,
  };

  UserSettings copyWith({
    bool? leftHanded,
    bool? mirrorCamera,
    bool? metronomeEnabled,
    int? defaultBpm,
    bool? showHandOverlay,
    CoachingMode? coachingMode,
    bool? voiceEnabled,
    bool? onboardingSeen,
    bool? showHandSkeleton,
    bool? showFingerGuides,
    bool? showNeckGuide,
    bool? showSoundField,
    bool? showCoachMessages,
    bool? showBeatDots,
    bool? showStatusChips,
  }) {
    return UserSettings(
      leftHanded: leftHanded ?? this.leftHanded,
      mirrorCamera: mirrorCamera ?? this.mirrorCamera,
      metronomeEnabled: metronomeEnabled ?? this.metronomeEnabled,
      defaultBpm: defaultBpm ?? this.defaultBpm,
      showHandOverlay: showHandOverlay ?? this.showHandOverlay,
      coachingMode: coachingMode ?? this.coachingMode,
      voiceEnabled: voiceEnabled ?? this.voiceEnabled,
      onboardingSeen: onboardingSeen ?? this.onboardingSeen,
      showHandSkeleton: showHandSkeleton ?? this.showHandSkeleton,
      showFingerGuides: showFingerGuides ?? this.showFingerGuides,
      showNeckGuide: showNeckGuide ?? this.showNeckGuide,
      showSoundField: showSoundField ?? this.showSoundField,
      showCoachMessages: showCoachMessages ?? this.showCoachMessages,
      showBeatDots: showBeatDots ?? this.showBeatDots,
      showStatusChips: showStatusChips ?? this.showStatusChips,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    leftHanded,
    mirrorCamera,
    metronomeEnabled,
    defaultBpm,
    showHandOverlay,
    coachingMode,
    voiceEnabled,
    onboardingSeen,
  ];
}
