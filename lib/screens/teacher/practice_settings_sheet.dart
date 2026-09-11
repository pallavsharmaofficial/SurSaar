import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sursaar/l10n/app_localizations.dart';

import '../../blocs/teacher/teacher_bloc.dart';
import '../../blocs/teacher/teacher_event.dart';
import '../../blocs/teacher/teacher_state.dart';
import '../../core/theme/app_colors.dart';
import '../../models/user_settings.dart';

/// Switches for every live element on the practice screen.
class PracticeSettingsSheet extends StatelessWidget {
  const PracticeSettingsSheet({super.key});

  static Future<void> show(BuildContext context, TeacherBloc bloc) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.backgroundDark,
      builder: (_) => BlocProvider<TeacherBloc>.value(
        value: bloc,
        child: const PracticeSettingsSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return BlocBuilder<TeacherBloc, TeacherState>(
      buildWhen: (a, b) =>
          a.settings != b.settings ||
          a.cameraEnabled != b.cameraEnabled ||
          a.micEnabled != b.micEnabled ||
          a.metronomeEnabled != b.metronomeEnabled ||
          a.voiceEnabled != b.voiceEnabled,
      builder: (context, state) {
        final bloc = context.read<TeacherBloc>();
        final settings = state.settings;
        void update(UserSettings value) =>
            bloc.add(TeacherSettingsChanged(value));

        Widget row(
          String label,
          bool value,
          ValueChanged<bool> onChanged, {
          IconData? icon,
          bool enabled = true,
        }) {
          return SwitchListTile(
            value: value,
            onChanged: enabled ? onChanged : null,
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            secondary: icon == null
                ? null
                : Icon(icon, color: enabled ? Colors.white70 : Colors.white24),
            title: Text(
              label,
              style: TextStyle(
                color: enabled ? AppColors.textOnDark : Colors.white38,
              ),
            ),
          );
        }

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  l10n.displaySettings,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                row(
                  l10n.cameraView,
                  state.cameraEnabled,
                  (v) => bloc.add(TeacherCameraToggled(v)),
                  icon: Icons.videocam_rounded,
                  enabled: state.cameraSupported,
                ),
                row(
                  l10n.microphone,
                  state.micEnabled,
                  (v) => bloc.add(TeacherMicToggled(v)),
                  icon: Icons.mic_rounded,
                  enabled: state.micSupported,
                ),
                row(
                  l10n.showSoundField,
                  settings.showSoundField,
                  (v) => update(settings.copyWith(showSoundField: v)),
                  icon: Icons.graphic_eq_rounded,
                ),
                row(
                  l10n.showHandSkeleton,
                  settings.showHandSkeleton,
                  (v) => update(settings.copyWith(showHandSkeleton: v)),
                  icon: Icons.back_hand_rounded,
                  enabled: state.handTrackingSupported,
                ),
                row(
                  l10n.showFingerGuides,
                  settings.showFingerGuides,
                  (v) => update(settings.copyWith(showFingerGuides: v)),
                  icon: Icons.touch_app_rounded,
                  enabled: state.handTrackingSupported,
                ),
                row(
                  l10n.showNeckGuide,
                  settings.showNeckGuide,
                  (v) => update(settings.copyWith(showNeckGuide: v)),
                  icon: Icons.straighten_rounded,
                  enabled: state.handTrackingSupported,
                ),
                row(
                  l10n.showCoachMessages,
                  settings.showCoachMessages,
                  (v) => update(settings.copyWith(showCoachMessages: v)),
                  icon: Icons.chat_bubble_outline_rounded,
                ),
                row(
                  l10n.showBeatDots,
                  settings.showBeatDots,
                  (v) => update(settings.copyWith(showBeatDots: v)),
                  icon: Icons.more_horiz_rounded,
                ),
                row(
                  l10n.showStatusChips,
                  settings.showStatusChips,
                  (v) => update(settings.copyWith(showStatusChips: v)),
                  icon: Icons.info_outline_rounded,
                ),
                const Divider(color: Colors.white12),
                row(
                  l10n.voiceCoach,
                  state.voiceEnabled,
                  (v) => bloc.add(TeacherVoiceToggled(v)),
                  icon: Icons.record_voice_over_rounded,
                  enabled: state.canSpeak,
                ),
                row(
                  l10n.metronome,
                  state.metronomeEnabled,
                  (v) => bloc.add(TeacherMetronomeToggled(v)),
                  icon: Icons.timer_outlined,
                ),
                row(
                  l10n.mirrorPreview,
                  settings.mirrorCamera,
                  (v) => update(settings.copyWith(mirrorCamera: v)),
                  icon: Icons.flip_rounded,
                ),
                row(
                  l10n.leftHanded,
                  settings.leftHanded,
                  (v) => update(settings.copyWith(leftHanded: v)),
                  icon: Icons.swap_horiz_rounded,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
