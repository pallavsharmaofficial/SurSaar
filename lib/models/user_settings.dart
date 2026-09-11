import 'package:equatable/equatable.dart';

/// Learner preferences that shape the AI teacher session.
class UserSettings extends Equatable {
  const UserSettings({
    this.leftHanded = false,
    this.mirrorCamera = true,
    this.metronomeEnabled = true,
    this.defaultBpm = 80,
    this.showHandOverlay = true,
  });

  factory UserSettings.fromMap(Map<String, dynamic> map) => UserSettings(
    leftHanded: map['left_handed'] as bool? ?? false,
    mirrorCamera: map['mirror_camera'] as bool? ?? true,
    metronomeEnabled: map['metronome_enabled'] as bool? ?? true,
    defaultBpm: (map['default_bpm'] as num?)?.toInt() ?? 80,
    showHandOverlay: map['show_hand_overlay'] as bool? ?? true,
  );

  final bool leftHanded;
  final bool mirrorCamera;
  final bool metronomeEnabled;
  final int defaultBpm;
  final bool showHandOverlay;

  Map<String, dynamic> toMap() => <String, dynamic>{
    'left_handed': leftHanded,
    'mirror_camera': mirrorCamera,
    'metronome_enabled': metronomeEnabled,
    'default_bpm': defaultBpm,
    'show_hand_overlay': showHandOverlay,
  };

  UserSettings copyWith({
    bool? leftHanded,
    bool? mirrorCamera,
    bool? metronomeEnabled,
    int? defaultBpm,
    bool? showHandOverlay,
  }) {
    return UserSettings(
      leftHanded: leftHanded ?? this.leftHanded,
      mirrorCamera: mirrorCamera ?? this.mirrorCamera,
      metronomeEnabled: metronomeEnabled ?? this.metronomeEnabled,
      defaultBpm: defaultBpm ?? this.defaultBpm,
      showHandOverlay: showHandOverlay ?? this.showHandOverlay,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    leftHanded,
    mirrorCamera,
    metronomeEnabled,
    defaultBpm,
    showHandOverlay,
  ];
}
