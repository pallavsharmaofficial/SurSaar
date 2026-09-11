import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sursaar/l10n/app_localizations.dart';

import '../../blocs/teacher/teacher_bloc.dart';
import '../../blocs/teacher/teacher_event.dart';
import '../../blocs/teacher/teacher_state.dart';
import '../../core/theme/app_colors.dart';
import '../../models/chord_voicing.dart';
import '../../teacher/analysis/chord_shape_coach.dart';
import '../../teacher/engine/teacher_engine.dart';
import '../../teacher/models/hand_frame.dart';
import '../../teacher/services/vision_service.dart';
import '../../widgets/teacher/accuracy_ring.dart';
import '../../widgets/teacher/chord_diagram.dart';
import '../../widgets/teacher/coach_banner.dart';
import '../../widgets/teacher/effects.dart';
import '../../widgets/teacher/glass_card.dart';
import '../../widgets/teacher/hand_overlay_painter.dart';

const Color _green = Color(0xFF22C55E);

/// Camera preview with the AR finger guide and all live feedback on top.
class TeacherStage extends StatelessWidget {
  const TeacherStage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          _CameraLayer(),
          _HandOverlay(),
          _CenterLayer(),
          Positioned(left: 12, top: 12, child: _ChordCard()),
          Positioned(right: 12, top: 12, child: _StatusColumn()),
          Positioned(left: 12, right: 12, bottom: 12, child: _CoachArea()),
        ],
      ),
    );
  }
}

class _StageBackground extends StatelessWidget {
  const _StageBackground();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF1E293B), Color(0xFF0F172A)],
        ),
      ),
      child: SizedBox.expand(),
    );
  }
}

/// Keeps the web preview mounted for the whole screen so the camera never
/// has to be re-attached between sessions.
class _CameraLayer extends StatelessWidget {
  const _CameraLayer();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TeacherBloc, TeacherState>(
      buildWhen: (a, b) =>
          a.cameraSupported != b.cameraSupported ||
          a.cameraRunning != b.cameraRunning,
      builder: (context, state) {
        final vision = context.read<TeacherBloc>().vision;
        final persistent = kIsWeb && state.cameraSupported;
        return Stack(
          fit: StackFit.expand,
          children: <Widget>[
            const _StageBackground(),
            if (persistent || state.cameraRunning)
              Positioned.fill(child: vision.buildPreview(context)),
            if (persistent && !state.cameraRunning) const _StageBackground(),
          ],
        );
      },
    );
  }
}

class _HandOverlay extends StatelessWidget {
  const _HandOverlay();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<
      TeacherBloc,
      TeacherState,
      (HandFrame, ShapeFeedback, bool, bool)
    >(
      selector: (s) => (
        s.snapshot?.hands ?? HandFrame.empty,
        s.snapshot?.shape ?? ShapeFeedback.none,
        s.cameraRunning &&
            s.handTrackingSupported &&
            s.settings.showHandOverlay,
        s.settings.leftHanded,
      ),
      builder: (context, data) {
        if (!data.$3) return const SizedBox.shrink();
        return IgnorePointer(
          child: RepaintBoundary(
            child: CustomPaint(
              painter: HandOverlayPainter(
                frame: data.$1,
                shape: data.$2,
                leftHanded: data.$4,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CenterLayer extends StatelessWidget {
  const _CenterLayer();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return BlocBuilder<TeacherBloc, TeacherState>(
      buildWhen: (a, b) =>
          a.showSetup != b.showSetup ||
          a.servicesStarting != b.servicesStarting ||
          a.phase != b.phase ||
          a.snapshot?.countInBeatsLeft != b.snapshot?.countInBeatsLeft ||
          a.cameraError != b.cameraError ||
          a.micError != b.micError,
      builder: (context, state) {
        if (state.phase == TeacherPhase.countIn) {
          final left = state.snapshot?.countInBeatsLeft ?? 0;
          return Center(
            child:
                Text(
                      '$left',
                      style: theme.textTheme.displayLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 120,
                      ),
                    )
                    .animate(key: ValueKey<int>(left))
                    .scale(
                      begin: const Offset(1.4, 1.4),
                      end: const Offset(1, 1),
                      duration: 300.ms,
                      curve: Curves.easeOutBack,
                    )
                    .fadeIn(duration: 150.ms),
          );
        }
        if (state.isPaused) {
          return ColoredBox(
            color: Colors.black45,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(
                    Icons.pause_circle_filled_rounded,
                    size: 72,
                    color: Colors.white,
                  ),
                  Text(
                    l10n.paused,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 200.ms),
          );
        }
        if (state.showSetup) return Center(child: _SetupCard(state: state));
        return const SizedBox.shrink();
      },
    );
  }
}

class _SetupCard extends StatelessWidget {
  const _SetupCard({required this.state});

  final TeacherState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final errors = <String>[
      if (state.cameraError != null) state.cameraError!,
      if (state.micError != null) state.micError!,
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 320;
        return Padding(
              padding: const EdgeInsets.all(12),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: GlassCard(
                  padding: EdgeInsets.all(compact ? 14 : 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      if (!compact) ...<Widget>[
                        const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            _SetupIcon(Icons.videocam_rounded),
                            SizedBox(width: 12),
                            _SetupIcon(Icons.mic_rounded),
                          ],
                        ).animate().scale(
                          begin: const Offset(0.6, 0.6),
                          curve: Curves.elasticOut,
                          duration: 700.ms,
                        ),
                        const SizedBox(height: 12),
                      ],
                      Text(
                        l10n.setupTitle,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.setupSubtitle,
                        textAlign: TextAlign.center,
                        maxLines: compact ? 2 : 3,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                      SizedBox(height: compact ? 10 : 16),
                      FilledButton.icon(
                        onPressed: state.servicesStarting
                            ? null
                            : () => context.read<TeacherBloc>().add(
                                const TeacherServicesRequested(),
                              ),
                        icon: state.servicesStarting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.power_settings_new_rounded),
                        label: Text(
                          state.servicesStarting
                              ? l10n.setupStarting
                              : l10n.setupTurnOn,
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      if (errors.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 8),
                        Text(
                          errors.join('\n'),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.successGold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            )
            .animate()
            .fadeIn(duration: 300.ms)
            .scale(begin: const Offset(0.96, 0.96), curve: Curves.easeOutBack);
      },
    );
  }
}

class _SetupIcon extends StatelessWidget {
  const _SetupIcon(this.icon);

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.25),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primary),
      ),
      child: Icon(icon, color: Colors.white),
    );
  }
}

typedef _CardData = ({
  String? chord,
  String? next,
  ChordVoicing? voicing,
  double hold,
  bool celebrating,
  int cueId,
  CueType? cue,
  bool learn,
  bool fresh,
  bool paused,
  bool hidden,
});

class _ChordCard extends StatelessWidget {
  const _ChordCard();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<TeacherBloc, TeacherState, _CardData>(
      selector: (s) {
        final snap = s.snapshot;
        return (
          chord: snap?.currentChord,
          next: snap?.nextChord,
          voicing: snap?.targetVoicing,
          hold: ((snap?.holdProgress ?? 0) * 20).round() / 20,
          celebrating: snap?.celebrating ?? false,
          cueId: snap?.cue?.id ?? 0,
          cue: snap?.cue?.type,
          learn: s.mode == CoachingMode.learn,
          fresh: snap?.waitingForFreshStrum ?? false,
          paused: snap?.listeningPaused ?? false,
          hidden: s.showSetup,
        );
      },
      builder: (context, d) {
        if (d.hidden || d.chord == null) return const SizedBox.shrink();
        final l10n = AppLocalizations.of(context)!;
        final theme = Theme.of(context);
        final burst = d.cue == CueType.correct ? d.cueId : 0;
        final shake = d.cue == CueType.missed || d.cue == CueType.skipped
            ? d.cueId
            : 0;
        final status = d.celebrating
            ? null
            : d.paused
            ? l10n.listeningPaused
            : d.fresh
            ? l10n.strumAgain
            : d.learn && d.hold > 0
            ? l10n.holdChord
            : null;
        return ShakeOnTrigger(
          trigger: shake,
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              HoldRing(
                value: d.learn ? d.hold : 0,
                padding: 0,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                  decoration: BoxDecoration(
                    color: d.celebrating
                        ? _green.withValues(alpha: 0.28)
                        : const Color(0xCC0F172A),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: d.celebrating ? _green : Colors.white12,
                      width: d.celebrating ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            l10n.playNow,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            transitionBuilder: (child, animation) =>
                                ScaleTransition(
                                  scale: CurvedAnimation(
                                    parent: animation,
                                    curve: Curves.easeOutBack,
                                  ),
                                  child: FadeTransition(
                                    opacity: animation,
                                    child: child,
                                  ),
                                ),
                            child: Text(
                              d.chord!,
                              key: ValueKey<String>(d.chord!),
                              style: theme.textTheme.displaySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                height: 1,
                              ),
                            ),
                          ),
                          if (d.next != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                '${l10n.nextChord}: ${d.next}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.successGold,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          if (status != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                status,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: _green,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (d.voicing != null) ...<Widget>[
                        const SizedBox(width: 12),
                        ChordDiagram(
                          voicing: d.voicing!,
                          size: 84,
                          showName: false,
                          color: Colors.white,
                          accent: AppColors.successGold,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Positioned.fill(
                child: CelebrationBurst(trigger: burst, spread: 1.4),
              ),
              if (d.celebrating)
                Positioned(
                  top: -12,
                  right: -12,
                  child:
                      Container(
                        width: 34,
                        height: 34,
                        decoration: const BoxDecoration(
                          color: _green,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                        ),
                      ).animate().scale(
                        begin: Offset.zero,
                        curve: Curves.elasticOut,
                        duration: 600.ms,
                      ),
                ),
            ],
          ),
        );
      },
    );
  }
}

typedef _StatusData = ({
  bool hidden,
  TrackingStatus tracking,
  bool handTracking,
  bool camera,
  bool mic,
  double level,
  String? hearing,
  bool handSeen,
  bool heard,
  bool inSession,
  bool finished,
  bool learn,
  int combo,
  int step,
  int total,
  double chordAccuracy,
  double timingAccuracy,
  int strums,
});

class _StatusColumn extends StatelessWidget {
  const _StatusColumn();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<TeacherBloc, TeacherState, _StatusData>(
      selector: (s) {
        final snap = s.snapshot;
        final detection = snap?.detection;
        return (
          hidden: s.showSetup,
          tracking: s.trackingStatus,
          handTracking: s.handTrackingSupported,
          camera: s.cameraRunning,
          mic: s.micRunning,
          level: ((snap?.inputLevel ?? 0) * 10).round() / 10,
          hearing: detection == null || detection.isSilent
              ? null
              : detection.chord,
          handSeen: snap?.handSeen ?? false,
          heard: snap?.heardStrum ?? false,
          inSession: s.inSession,
          finished: s.isFinished,
          learn: s.mode == CoachingMode.learn,
          combo: snap?.combo ?? 0,
          step: snap?.targetIndex ?? 0,
          total: snap?.targetCount ?? 0,
          chordAccuracy: ((snap?.chordAccuracy ?? 0) * 100).round() / 100,
          timingAccuracy: ((snap?.timingAccuracy ?? 1) * 100).round() / 100,
          strums: snap?.strums ?? 0,
        );
      },
      builder: (context, d) {
        if (d.hidden) return const SizedBox.shrink();
        final l10n = AppLocalizations.of(context)!;
        final theme = Theme.of(context);
        final label = theme.textTheme.labelMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (d.camera &&
                d.handTracking &&
                (d.tracking == TrackingStatus.loading ||
                    d.tracking == TrackingStatus.error))
              GlassCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (d.tracking == TrackingStatus.loading)
                      const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      const Icon(
                        Icons.info_outline,
                        size: 14,
                        color: AppColors.successGold,
                      ),
                    const SizedBox(width: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 180),
                      child: Text(
                        d.tracking == TrackingStatus.loading
                            ? l10n.trackingLoading
                            : l10n.trackingError,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(),
            if (d.mic)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: GlassCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      LevelMeter(level: d.level),
                      const SizedBox(width: 8),
                      Text(
                        '${l10n.hearing}: ${d.hearing ?? '…'}',
                        style: label,
                      ),
                    ],
                  ),
                ),
              ),
            if (!d.inSession && !d.finished && (d.camera || d.mic))
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      if (d.camera)
                        _CheckRow(
                          done: !d.handTracking || d.handSeen,
                          label: !d.handTracking
                              ? l10n.checkCamera
                              : d.handSeen
                              ? l10n.checkHandDone
                              : l10n.checkHandWaiting,
                        ),
                      if (d.mic)
                        _CheckRow(
                          done: d.heard,
                          label: d.heard
                              ? l10n.checkMicDone
                              : l10n.checkMicWaiting,
                        ),
                    ],
                  ),
                ).animate().fadeIn(duration: 250.ms).slideX(begin: 0.2),
              ),
            if (d.inSession && d.learn && d.total > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: GlassCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: Text(
                    l10n.chordOf((d.step + 1).clamp(1, d.total), d.total),
                    style: label,
                  ),
                ),
              ),
            if (d.inSession && d.combo >= 2)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child:
                    Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: <Color>[
                                Color(0xFFF97316),
                                Color(0xFFEF4444),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '🔥 ${l10n.inARow(d.combo)}',
                            style: label,
                          ),
                        )
                        .animate(key: ValueKey<int>(d.combo))
                        .scale(
                          begin: const Offset(1.35, 1.35),
                          curve: Curves.elasticOut,
                          duration: 600.ms,
                        ),
              ),
            if (d.inSession && !d.learn)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    AccuracyRing(
                      value: d.chordAccuracy,
                      label: l10n.chordsShort,
                      size: 62,
                      background: const Color(0xCC0F172A),
                    ),
                    const SizedBox(width: 6),
                    AccuracyRing(
                      value: d.timingAccuracy,
                      label: l10n.timing,
                      size: 62,
                      background: const Color(0xCC0F172A),
                      color: d.strums == 0 ? Colors.white24 : null,
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _CheckRow extends StatelessWidget {
  const _CheckRow({required this.done, required this.label});

  final bool done;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            transitionBuilder: (child, animation) => ScaleTransition(
              scale: CurvedAnimation(
                parent: animation,
                curve: Curves.elasticOut,
              ),
              child: child,
            ),
            child: Icon(
              done ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
              key: ValueKey<bool>(done),
              size: 18,
              color: done ? _green : Colors.white54,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: done ? Colors.white : Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}

class _CoachArea extends StatelessWidget {
  const _CoachArea();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<
      TeacherBloc,
      TeacherState,
      (CoachMessage?, bool, int, int, bool)
    >(
      selector: (s) => (
        s.snapshot?.message,
        s.showSetup,
        s.snapshot?.beatInBar ?? 0,
        s.plan?.beatsPerBar ?? 4,
        s.phase == TeacherPhase.running,
      ),
      builder: (context, d) {
        if (d.$2) return const SizedBox.shrink();
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            if (d.$5)
              Padding(
                padding: const EdgeInsets.only(right: 8, bottom: 12),
                child: _BeatDots(beatInBar: d.$3, beatsPerBar: d.$4),
              ),
            Expanded(
              child: Align(
                alignment: Alignment.bottomLeft,
                child: CoachBanner(message: d.$1),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BeatDots extends StatelessWidget {
  const _BeatDots({required this.beatInBar, required this.beatsPerBar});

  final int beatInBar;
  final int beatsPerBar;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List<Widget>.generate(beatsPerBar, (i) {
        final active = i + 1 == beatInBar;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          width: active ? 14 : 9,
          height: active ? 14 : 9,
          margin: const EdgeInsets.only(right: 5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active
                ? (i == 0 ? AppColors.secondary : Colors.white)
                : Colors.white30,
          ),
        );
      }),
    );
  }
}
