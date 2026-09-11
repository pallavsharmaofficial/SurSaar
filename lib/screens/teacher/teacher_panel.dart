import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sursaar/l10n/app_localizations.dart';

import '../../blocs/teacher/teacher_bloc.dart';
import '../../blocs/teacher/teacher_event.dart';
import '../../blocs/teacher/teacher_state.dart';
import '../../core/theme/app_colors.dart';
import '../../models/chord_voicing.dart';
import '../../models/strumming_pattern.dart';
import '../../teacher/analysis/chord_shape_coach.dart';
import '../../teacher/engine/practice_plan.dart';
import '../../teacher/engine/teacher_engine.dart';
import '../../teacher/models/strum_event.dart';
import '../../widgets/teacher/chord_diagram.dart';
import '../../widgets/teacher/chord_ribbon.dart';
import '../../widgets/teacher/finger_colors.dart';
import '../../widgets/teacher/strumming_timeline.dart';

const Color _surface = Color(0xFF1E293B);
const Color _green = Color(0xFF22C55E);

/// Everything next to the camera: mode, start, how to play, strumming,
/// progress and (tucked away) the advanced options.
class TeacherPanel extends StatelessWidget {
  const TeacherPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _ModeSwitch(),
        SizedBox(height: 12),
        _PrimaryActions(),
        SizedBox(height: 16),
        _NowPlaying(),
        SizedBox(height: 16),
        _Progress(),
        SizedBox(height: 16),
        _StrumSection(),
        SizedBox(height: 8),
        _MoreOptions(),
        SizedBox(height: 24),
      ],
    );
  }
}

TextStyle? _heading(ThemeData theme) => theme.textTheme.titleSmall?.copyWith(
  fontWeight: FontWeight.bold,
  color: AppColors.textOnDark,
);

class _ModeSwitch extends StatelessWidget {
  const _ModeSwitch();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return BlocSelector<TeacherBloc, TeacherState, (CoachingMode, bool)>(
      selector: (s) => (s.mode, s.inSession),
      builder: (context, d) {
        final bloc = context.read<TeacherBloc>();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SegmentedButton<CoachingMode>(
              segments: <ButtonSegment<CoachingMode>>[
                ButtonSegment<CoachingMode>(
                  value: CoachingMode.learn,
                  icon: const Icon(Icons.school_rounded),
                  label: Text(l10n.modeLearn),
                ),
                ButtonSegment<CoachingMode>(
                  value: CoachingMode.playAlong,
                  icon: const Icon(Icons.queue_music_rounded),
                  label: Text(l10n.modePlayAlong),
                ),
              ],
              selected: <CoachingMode>{d.$1},
              showSelectedIcon: false,
              onSelectionChanged: d.$2
                  ? null
                  : (selection) =>
                        bloc.add(TeacherModeChanged(selection.first)),
              style: ButtonStyle(
                foregroundColor: WidgetStateProperty.resolveWith(
                  (states) => states.contains(WidgetState.selected)
                      ? Colors.white
                      : Colors.white70,
                ),
                backgroundColor: WidgetStateProperty.resolveWith(
                  (states) => states.contains(WidgetState.selected)
                      ? AppColors.primary
                      : _surface,
                ),
              ),
            ),
            const SizedBox(height: 6),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Text(
                d.$1 == CoachingMode.learn
                    ? l10n.modeLearnHint
                    : l10n.modePlayAlongHint,
                key: ValueKey<CoachingMode>(d.$1),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textOnDark.withValues(alpha: 0.7),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PrimaryActions extends StatelessWidget {
  const _PrimaryActions();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return BlocSelector<
      TeacherBloc,
      TeacherState,
      (TeacherPhase, bool, bool, CoachingMode)
    >(
      selector: (s) => (s.phase, s.servicesStarting, s.servicesOn, s.mode),
      builder: (context, d) {
        final bloc = context.read<TeacherBloc>();
        final phase = d.$1;
        final running =
            phase == TeacherPhase.running || phase == TeacherPhase.countIn;
        final paused = phase == TeacherPhase.paused;
        final finished = phase == TeacherPhase.finished;
        // The session summary has its own Play again button.
        if (finished) return const SizedBox.shrink();
        final (IconData icon, String label, VoidCallback action) = running
            ? (
                Icons.pause_rounded,
                l10n.pause,
                () => bloc.add(const TeacherPaused()),
              )
            : paused
            ? (
                Icons.play_arrow_rounded,
                l10n.resume,
                () => bloc.add(const TeacherResumed()),
              )
            : finished
            ? (
                Icons.replay_rounded,
                l10n.playAgain,
                () => bloc.add(const TeacherStarted()),
              )
            : (
                Icons.play_arrow_rounded,
                l10n.startPractice,
                () => bloc.add(const TeacherStarted()),
              );
        Widget button = FilledButton.icon(
          onPressed: d.$2 ? null : action,
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(icon, key: ValueKey<IconData>(icon), size: 26),
          ),
          label: Text(label),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(54),
            textStyle: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        );
        if (phase == TeacherPhase.idle && d.$3) {
          // gentle "you're ready" pulse once camera/mic are on
          button = button
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .scaleXY(end: 1.03, duration: 900.ms, curve: Curves.easeInOut);
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(child: button),
                if (running || paused) ...<Widget>[
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 54,
                    child: FilledButton.tonalIcon(
                      onPressed: () => bloc.add(const TeacherStopped()),
                      icon: const Icon(Icons.stop_rounded),
                      label: Text(l10n.finish),
                    ),
                  ),
                ],
              ],
            ),
            if (phase == TeacherPhase.idle && d.$4 == CoachingMode.learn)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  l10n.readyHint,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textOnDark.withValues(alpha: 0.7),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

typedef _NowData = ({
  String? chord,
  ChordVoicing? voicing,
  String? hint,
  bool canHear,
  bool canSpeak,
  bool voiceOn,
  bool learn,
  bool running,
  bool paused,
});

class _NowPlaying extends StatelessWidget {
  const _NowPlaying();

  static Color _lineColor(String line) {
    final first = line.split(' ').first.toLowerCase();
    switch (first) {
      case 'index':
      case 'barre':
        return FingerColors.index;
      case 'middle':
        return FingerColors.middle;
      case 'ring':
        return FingerColors.ring;
      case 'pinky':
        return FingerColors.pinky;
      case 'thumb':
        return FingerColors.thumb;
      default:
        return Colors.white38;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return BlocSelector<TeacherBloc, TeacherState, _NowData>(
      selector: (s) {
        final shape = s.snapshot?.shape;
        return (
          chord: s.snapshot?.currentChord,
          voicing: s.snapshot?.targetVoicing,
          hint: shape != null && shape.handVisible && shape.hints.isNotEmpty
              ? shape.hints.first
              : null,
          canHear: s.canPlayChords,
          canSpeak: s.canSpeak,
          voiceOn: s.voiceEnabled,
          learn: s.mode == CoachingMode.learn,
          running: s.phase == TeacherPhase.running,
          paused: s.isPaused,
        );
      },
      builder: (context, d) {
        final voicing = d.voicing;
        if (d.chord == null || voicing == null) return const SizedBox.shrink();
        final bloc = context.read<TeacherBloc>();
        final lines = ChordShapeCoach.placementText(voicing);
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: Text(
                        '${l10n.howToPlay} ${d.chord}',
                        key: ValueKey<String>(d.chord!),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  if (d.canSpeak)
                    IconButton(
                      tooltip: l10n.voiceCoach,
                      onPressed: () =>
                          bloc.add(TeacherVoiceToggled(!d.voiceOn)),
                      icon: Icon(
                        d.voiceOn
                            ? Icons.record_voice_over_rounded
                            : Icons.voice_over_off_rounded,
                        color: d.voiceOn
                            ? AppColors.successGold
                            : Colors.white54,
                      ),
                    ),
                  if (d.canHear)
                    TextButton.icon(
                      onPressed: () =>
                          bloc.add(TeacherHearChordRequested(d.chord!)),
                      icon: const Icon(Icons.volume_up_rounded),
                      label: Text(l10n.hearIt),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.successGold,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  ChordDiagram(
                    voicing: voicing,
                    size: 118,
                    showName: false,
                    color: Colors.white,
                    accent: AppColors.successGold,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        for (var i = 0; i < lines.length; i++)
                          Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Container(
                                      width: 10,
                                      height: 10,
                                      margin: const EdgeInsets.only(
                                        top: 4,
                                        right: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _lineColor(lines[i]),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        lines[i],
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: AppColors.textOnDark,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                              .animate(key: ValueKey<String>('${d.chord}-$i'))
                              .fadeIn(delay: (80 * i).ms, duration: 250.ms)
                              .slideX(begin: 0.15),
                      ],
                    ),
                  ),
                ],
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                child: d.hint == null
                    ? const SizedBox(width: double.infinity)
                    : Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.successGold.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          d.hint!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.successGold,
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 10),
              const _FingerLegend(),
              if (d.learn && (d.running || d.paused)) ...<Widget>[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton.icon(
                    onPressed: d.running
                        ? () => bloc.add(const TeacherSkipRequested())
                        : null,
                    icon: const Icon(Icons.skip_next_rounded),
                    label: Text(l10n.skip),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white30),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _FingerLegend extends StatelessWidget {
  const _FingerLegend();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final names = <String>[
      l10n.fingerIndex,
      l10n.fingerMiddle,
      l10n.fingerRing,
      l10n.fingerPinky,
    ];
    return Wrap(
      spacing: 12,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        Text(
          l10n.fingerLegend,
          style: theme.textTheme.labelSmall?.copyWith(color: Colors.white54),
        ),
        for (var finger = 1; finger <= 4; finger++)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              CircleAvatar(
                radius: 8,
                backgroundColor: FingerColors.of(finger),
                child: Text(
                  '$finger',
                  style: const TextStyle(
                    fontSize: 9,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                names[finger - 1],
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.white70,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return BlocSelector<
      TeacherBloc,
      TeacherState,
      (PracticePlan?, int, bool, double, TeacherPhase)
    >(
      selector: (s) => (
        s.plan,
        s.snapshot?.targetIndex ?? 0,
        s.mode == CoachingMode.learn,
        ((s.snapshot?.targetProgress ?? 0) * 20).round() / 20,
        s.phase,
      ),
      builder: (context, d) {
        final plan = d.$1;
        if (plan == null) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(l10n.chords, style: _heading(theme)),
            const SizedBox(height: 8),
            if (d.$3)
              _StepChips(
                steps: plan.learnSteps,
                index: d.$5 == TeacherPhase.idle ? -1 : d.$2,
              )
            else
              ChordRibbon(plan: plan, currentIndex: d.$2, targetProgress: d.$4),
          ],
        );
      },
    );
  }
}

class _StepChips extends StatelessWidget {
  const _StepChips({required this.steps, required this.index});

  final List<String> steps;

  /// Current step, or -1 before the session starts.
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final start = (index - 2).clamp(0, steps.length);
    final end = (start + 8).clamp(0, steps.length);
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: <Widget>[
        for (var i = start; i < end; i++)
          AnimatedScale(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutBack,
            scale: i == index ? 1.12 : 1,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: i < index
                    ? _green.withValues(alpha: 0.2)
                    : i == index
                    ? AppColors.primary
                    : _surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: i < index ? _green : Colors.white12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (i < index) ...<Widget>[
                    const Icon(Icons.check_rounded, size: 14, color: _green),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    steps[i],
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (end < steps.length)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            child: Text(
              '+${steps.length - end}',
              style: theme.textTheme.labelMedium?.copyWith(
                color: Colors.white54,
              ),
            ),
          ),
      ],
    );
  }
}

class _StrumSection extends StatelessWidget {
  const _StrumSection();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return BlocBuilder<TeacherBloc, TeacherState>(
      buildWhen: (a, b) =>
          a.plan?.pattern != b.plan?.pattern ||
          a.snapshot?.slotIndex != b.snapshot?.slotIndex ||
          a.snapshot?.lastTiming != b.snapshot?.lastTiming ||
          a.phase != b.phase,
      builder: (context, state) {
        final plan = state.plan;
        final snapshot = state.snapshot;
        if (plan == null) return const SizedBox.shrink();
        final running = state.phase == TeacherPhase.running;
        final slot = running ? (snapshot?.slotIndex ?? -1) : -1;
        final results = <int, TimingResult>{};
        if (snapshot != null && !snapshot.isLearn) {
          final length = plan.pattern.slots.length;
          final cycleStart = ((snapshot.beat * 2).floor() ~/ length) * length;
          for (final t in snapshot.recentTimings) {
            if (t.absoluteSlot >= cycleStart &&
                t.absoluteSlot < cycleStart + length) {
              results[t.slotInPattern] = t.result;
            }
          }
        }
        final stroke = slot >= 0 && slot < plan.pattern.slots.length
            ? plan.pattern.slots[slot]
            : StrokeType.rest;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Text(l10n.strummingPatternLabel, style: _heading(theme)),
                const SizedBox(width: 10),
                SizedBox(
                  width: 28,
                  height: 28,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 140),
                    transitionBuilder: (child, animation) => SlideTransition(
                      position: Tween<Offset>(
                        begin: Offset(0, stroke == StrokeType.up ? 0.6 : -0.6),
                        end: Offset.zero,
                      ).animate(animation),
                      child: FadeTransition(opacity: animation, child: child),
                    ),
                    child: stroke == StrokeType.rest
                        ? const SizedBox.shrink(key: ValueKey<String>('rest'))
                        : Text(
                            StrummingPattern.arrow(stroke),
                            key: ValueKey<int>(slot),
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: AppColors.successGold,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    plan.pattern.notation,
                    textAlign: TextAlign.end,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textOnDark.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            StrummingTimeline(
              pattern: plan.pattern,
              currentSlot: slot,
              results: results,
            ),
          ],
        );
      },
    );
  }
}

class _MoreOptions extends StatelessWidget {
  const _MoreOptions();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return BlocBuilder<TeacherBloc, TeacherState>(
      buildWhen: (a, b) =>
          a.bpm != b.bpm ||
          a.songBpm != b.songBpm ||
          a.capo != b.capo ||
          a.inSession != b.inSession ||
          a.cameraEnabled != b.cameraEnabled ||
          a.micEnabled != b.micEnabled ||
          a.metronomeEnabled != b.metronomeEnabled ||
          a.voiceEnabled != b.voiceEnabled ||
          a.plan?.mode != b.plan?.mode,
      builder: (context, state) {
        final bloc = context.read<TeacherBloc>();
        TextStyle chipLabel(bool on) => TextStyle(
          color: on ? Colors.white : AppColors.textOnLight,
          fontWeight: FontWeight.w600,
        );
        final presets = <(String, int)>[
          (l10n.speedSlow, (state.songBpm * 0.6).round().clamp(40, 200)),
          (l10n.speedMedium, (state.songBpm * 0.8).round().clamp(40, 200)),
          (l10n.speedSong, state.songBpm),
        ];
        return Theme(
          data: theme.copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: EdgeInsets.zero,
            iconColor: Colors.white,
            collapsedIconColor: Colors.white70,
            title: Text(l10n.moreOptions, style: _heading(theme)),
            children: <Widget>[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${l10n.tempo}: ${state.bpm} BPM',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textOnDark,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: <Widget>[
                    for (final (label, bpm) in presets)
                      ChoiceChip(
                        label: Text(label, style: chipLabel(state.bpm == bpm)),
                        selected: state.bpm == bpm,
                        onSelected: (_) => bloc.add(TeacherBpmChanged(bpm)),
                      ),
                  ],
                ),
              ),
              Slider(
                value: state.bpm.toDouble().clamp(40, 180),
                min: 40,
                max: 180,
                divisions: 140,
                label: '${state.bpm}',
                onChanged: (v) => bloc.add(TeacherBpmChanged(v.round())),
              ),
              if (state.plan?.mode == PracticeMode.song) ...<Widget>[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    l10n.capoLabel(state.capo),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textOnDark,
                    ),
                  ),
                ),
                Slider(
                  value: state.capo.toDouble(),
                  min: 0,
                  max: 7,
                  divisions: 7,
                  label: '${state.capo}',
                  onChanged: state.inSession
                      ? null
                      : (v) => bloc.add(TeacherCapoChanged(v.round())),
                ),
              ],
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: <Widget>[
                    if (state.cameraSupported)
                      FilterChip(
                        avatar: Icon(
                          state.cameraEnabled
                              ? Icons.videocam_rounded
                              : Icons.videocam_off_rounded,
                          size: 18,
                        ),
                        label: Text(
                          l10n.camera,
                          style: chipLabel(state.cameraEnabled),
                        ),
                        selected: state.cameraEnabled,
                        onSelected: (v) => bloc.add(TeacherCameraToggled(v)),
                      ),
                    if (state.micSupported)
                      FilterChip(
                        avatar: Icon(
                          state.micEnabled
                              ? Icons.mic_rounded
                              : Icons.mic_off_rounded,
                          size: 18,
                        ),
                        label: Text(
                          l10n.microphone,
                          style: chipLabel(state.micEnabled),
                        ),
                        selected: state.micEnabled,
                        onSelected: (v) => bloc.add(TeacherMicToggled(v)),
                      ),
                    FilterChip(
                      avatar: const Icon(Icons.timer_outlined, size: 18),
                      label: Text(
                        l10n.metronome,
                        style: chipLabel(state.metronomeEnabled),
                      ),
                      selected: state.metronomeEnabled,
                      onSelected: (v) => bloc.add(TeacherMetronomeToggled(v)),
                    ),
                    if (state.canSpeak)
                      FilterChip(
                        avatar: const Icon(
                          Icons.record_voice_over_rounded,
                          size: 18,
                        ),
                        label: Text(
                          l10n.voiceCoach,
                          style: chipLabel(state.voiceEnabled),
                        ),
                        selected: state.voiceEnabled,
                        onSelected: (v) => bloc.add(TeacherVoiceToggled(v)),
                      ),
                  ],
                ),
              ),
              if (!state.handTrackingSupported && state.cameraSupported)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    l10n.handTrackingWebOnly,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textOnDark.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}
