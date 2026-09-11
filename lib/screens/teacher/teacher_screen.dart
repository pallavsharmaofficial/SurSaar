import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sursaar/l10n/app_localizations.dart';

import '../../blocs/teacher/teacher_bloc.dart';
import '../../blocs/teacher/teacher_event.dart';
import '../../blocs/teacher/teacher_state.dart';
import '../../core/theme/app_colors.dart';
import '../../data/content/chord_library.dart';
import '../../models/lesson.dart';
import '../../models/song.dart';
import '../../repositories/lesson_repository.dart';
import '../../repositories/practice_repository.dart';
import '../../repositories/progress_repository.dart';
import '../../repositories/settings_repository.dart';
import '../../repositories/song_repository.dart';
import '../../teacher/analysis/chord_shape_coach.dart';
import '../../teacher/engine/practice_plan.dart';
import '../../teacher/engine/teacher_engine.dart';
import '../../teacher/models/strum_event.dart';
import '../../widgets/teacher/accuracy_ring.dart';
import '../../widgets/teacher/chord_diagram.dart';
import '../../widgets/teacher/chord_ribbon.dart';
import '../../widgets/teacher/coach_banner.dart';
import '../../widgets/teacher/hand_overlay_painter.dart';
import '../../widgets/teacher/strumming_timeline.dart';
import '../../widgets/app_back_button.dart';

/// Describes what the teacher should practise. Resolved to a
/// [PracticePlan] once the content is loaded.
class TeacherRequest {
  const TeacherRequest.song(this.songId)
    : lessonId = null,
      chords = null,
      pattern = null,
      bpm = null;

  const TeacherRequest.lesson(this.lessonId)
    : songId = null,
      chords = null,
      pattern = null,
      bpm = null;

  const TeacherRequest.adhoc({required this.chords, this.pattern, this.bpm})
    : songId = null,
      lessonId = null;

  final String? songId;
  final String? lessonId;
  final List<String>? chords;
  final String? pattern;
  final int? bpm;
}

class TeacherScreen extends StatelessWidget {
  const TeacherScreen({super.key, required this.request});

  final TeacherRequest request;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TeacherBloc>(
      create: (context) => TeacherBloc(
        chordLibrary: context.read<ChordLibrary>(),
        settingsRepository: context.read<SettingsRepository>(),
        practiceRepository: context.read<PracticeRepository>(),
        progressRepository: context.read<ProgressRepository>(),
      ),
      child: _PlanResolver(request: request),
    );
  }
}

class _PlanResolver extends StatefulWidget {
  const _PlanResolver({required this.request});

  final TeacherRequest request;

  @override
  State<_PlanResolver> createState() => _PlanResolverState();
}

class _PlanResolverState extends State<_PlanResolver> {
  late final Future<PracticePlan?> _plan = _resolve();

  Future<PracticePlan?> _resolve() async {
    final request = widget.request;
    final settingsRepository = context.read<SettingsRepository>();
    final songRepository = context.read<SongRepository>();
    final lessonRepository = context.read<LessonRepository>();
    final settings = await settingsRepository.getSettings();
    if (request.songId != null) {
      final song = await songRepository.getSongById(request.songId!);
      return song == null ? null : PracticePlan.forSong(song);
    }
    if (request.lessonId != null) {
      final lesson = await lessonRepository.getLessonById(request.lessonId!);
      if (lesson == null) return null;
      Song? song;
      if (lesson.songId != null) {
        song = await songRepository.getSongById(lesson.songId!);
      }
      return PracticePlan.forLesson(lesson, song: song);
    }
    return PracticePlan.forChords(
      request.chords ?? const <String>['G', 'C', 'D'],
      pattern: request.pattern ?? 'D DU UDU',
      bpm: request.bpm ?? settings.defaultBpm,
      title: 'Quick practice',
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PracticePlan?>(
      future: _plan,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final plan = snapshot.data;
        if (plan == null) {
          return Scaffold(
            appBar: AppBar(leading: const AppBackButton()),
            body: const Center(child: Text('Nothing to practise here yet.')),
          );
        }
        return _TeacherView(plan: plan);
      },
    );
  }
}

class _TeacherView extends StatefulWidget {
  const _TeacherView({required this.plan});

  final PracticePlan plan;

  @override
  State<_TeacherView> createState() => _TeacherViewState();
}

class _TeacherViewState extends State<_TeacherView> {
  @override
  void initState() {
    super.initState();
    context.read<TeacherBloc>().add(TeacherInitialized(widget.plan));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<TeacherBloc, TeacherState>(
      builder: (context, state) {
        final plan = state.plan ?? widget.plan;
        if (state.status == TeacherStatus.initial || state.plan == null) {
          return Scaffold(
            backgroundColor: AppColors.backgroundDark,
            appBar: AppBar(
              leading: const AppBackButton(),
              backgroundColor: AppColors.backgroundDark,
              title: Text(plan.title),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        return Scaffold(
          backgroundColor: AppColors.backgroundDark,
          appBar: AppBar(
            leading: const AppBackButton(),
            backgroundColor: AppColors.backgroundDark,
            title: Column(
              children: <Widget>[
                Text(plan.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                if (plan.subtitle != null)
                  Text(
                    plan.subtitle!,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textOnDark.withValues(alpha: 0.7),
                    ),
                  ),
              ],
            ),
            actions: <Widget>[
              IconButton(
                tooltip: l10n.aiTeacherHowItWorks,
                icon: const Icon(Icons.info_outline),
                onPressed: () => _showInfo(context),
              ),
            ],
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 900;
              final stage = _Stage(state: state);
              final panel = _Panel(state: state);
              if (wide) {
                return Row(
                  children: <Widget>[
                    Expanded(flex: 3, child: stage),
                    SizedBox(
                      width: 400,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: panel,
                      ),
                    ),
                  ],
                );
              }
              return CustomScrollView(
                slivers: <Widget>[
                  SliverToBoxAdapter(
                    child: AspectRatio(aspectRatio: 4 / 3, child: stage),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverToBoxAdapter(child: panel),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  void _showInfo(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.aiTeacherHowItWorks),
        content: Text(l10n.aiTeacherExplanation),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
  }
}

/// Camera preview + AR overlays.
class _Stage extends StatelessWidget {
  const _Stage({required this.state});

  final TeacherState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final bloc = context.read<TeacherBloc>();
    final snapshot = state.snapshot;
    final target = snapshot?.currentTarget;
    final voicing = snapshot?.targetVoicing;
    final showCamera = state.cameraEnabled && state.cameraRunning;

    return ClipRRect(
      borderRadius: BorderRadius.circular(0),
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          if (showCamera)
            bloc.vision.buildPreview(context)
          else
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[Color(0xFF1E293B), Color(0xFF0F172A)],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      state.cameraEnabled ? Icons.videocam : Icons.videocam_off,
                      size: 64,
                      color: Colors.white24,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.cameraError ??
                          (state.cameraSupported
                              ? l10n.cameraStartsOnPlay
                              : l10n.cameraUnavailable),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white54,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          if (showCamera &&
              snapshot != null &&
              state.settings.showHandOverlay &&
              state.handTrackingSupported)
            IgnorePointer(
              child: CustomPaint(
                painter: HandOverlayPainter(
                  frame: snapshot.hands,
                  shape: snapshot.shape,
                  leftHanded: state.settings.leftHanded,
                ),
              ),
            ),
          // target chord card
          Positioned(
            left: 12,
            top: 12,
            child: _GlassCard(
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
                      Text(
                        target?.chord ?? '—',
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1,
                        ),
                      ),
                      if (snapshot?.nextTarget != null &&
                          snapshot!.nextTarget!.chord != target?.chord)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            '${l10n.nextChord}: ${snapshot.nextTarget!.chord}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.successGold,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (voicing != null) ...<Widget>[
                    const SizedBox(width: 12),
                    ChordDiagram(
                      voicing: voicing,
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
          // scores
          if (snapshot != null && snapshot.phase != TeacherPhase.idle)
            Positioned(
              right: 12,
              top: 12,
              child: Row(
                children: <Widget>[
                  AccuracyRing(
                    value: snapshot.chordAccuracy,
                    label: l10n.chordsShort,
                    size: 72,
                  ),
                  const SizedBox(width: 6),
                  AccuracyRing(
                    value: snapshot.timingAccuracy,
                    label: l10n.timing,
                    size: 72,
                    color: snapshot.strums == 0 ? Colors.white24 : null,
                  ),
                ],
              ),
            ),
          // detected chord pill
          if (snapshot?.detection != null && state.micRunning)
            Positioned(
              right: 12,
              bottom: 64,
              child: _DetectedPill(snapshot: snapshot!),
            ),
          // count-in
          if (snapshot?.phase == TeacherPhase.countIn)
            Center(
              child:
                  Text(
                        '${snapshot!.countInBeatsLeft}',
                        style: theme.textTheme.displayLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 120,
                        ),
                      )
                      .animate(key: ValueKey<int>(snapshot.countInBeatsLeft))
                      .scale(
                        begin: const Offset(1.3, 1.3),
                        end: const Offset(1, 1),
                        duration: 300.ms,
                      )
                      .fadeIn(duration: 150.ms),
            ),
          // coach
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: Align(
              alignment: Alignment.bottomLeft,
              child: CoachBanner(message: snapshot?.message),
            ),
          ),
          // beat indicator
          if (snapshot != null && snapshot.phase == TeacherPhase.running)
            Positioned(
              left: 12,
              bottom: 64,
              child: _BeatDots(
                beatInBar: snapshot.beatInBar,
                beatsPerBar: snapshot.plan.beatsPerBar,
              ),
            ),
        ],
      ),
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
      children: List<Widget>.generate(beatsPerBar, (i) {
        final active = i + 1 == beatInBar;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          width: active ? 16 : 10,
          height: active ? 16 : 10,
          margin: const EdgeInsets.only(right: 6),
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

class _DetectedPill extends StatelessWidget {
  const _DetectedPill({required this.snapshot});

  final TeacherSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final detection = snapshot.detection!;
    final match =
        detection.matchesTarget ||
        TeacherEngine.sameChordFamily(
          detection.chord,
          snapshot.currentTarget?.chord,
        );
    final color = detection.isSilent
        ? Colors.white24
        : match
        ? const Color(0xFF22C55E)
        : const Color(0xFFF87171);
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            l10n.hearing,
            style: theme.textTheme.labelSmall?.copyWith(color: Colors.white70),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                detection.isSilent ? Icons.mic_none : Icons.graphic_eq,
                color: color,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                detection.isSilent ? '…' : (detection.chord ?? '?'),
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(
            width: 90,
            child: LinearProgressIndicator(
              value: detection.isSilent ? 0 : detection.confidence,
              minHeight: 4,
              color: color,
              backgroundColor: Colors.white12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xCC0F172A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: child,
    );
  }
}

/// Timeline, controls and the "how to play" guide.
class _Panel extends StatelessWidget {
  const _Panel({required this.state});

  final TeacherState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final bloc = context.read<TeacherBloc>();
    final snapshot = state.snapshot;
    final plan = state.plan!;
    final running =
        snapshot?.phase == TeacherPhase.running ||
        snapshot?.phase == TeacherPhase.countIn;
    final paused = snapshot?.phase == TeacherPhase.paused;
    final finished = snapshot?.phase == TeacherPhase.finished;

    final slotResults = <int, TimingResult>{};
    if (snapshot != null) {
      final slotsLen = plan.pattern.slots.length;
      final cycleStart = ((snapshot.beat * 2).floor() ~/ slotsLen) * slotsLen;
      for (final t in snapshot.recentTimings) {
        if (t.absoluteSlot >= cycleStart &&
            t.absoluteSlot < cycleStart + slotsLen) {
          slotResults[t.slotInPattern] = t.result;
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (finished && snapshot != null) ...<Widget>[
          _SummaryCard(state: state),
          const SizedBox(height: 16),
        ],
        // transport
        Row(
          children: <Widget>[
            Expanded(
              child: FilledButton.icon(
                onPressed: state.status == TeacherStatus.starting
                    ? null
                    : running
                    ? () => bloc.add(const TeacherPaused())
                    : paused
                    ? () => bloc.add(const TeacherResumed())
                    : () => bloc.add(const TeacherStarted()),
                icon: Icon(
                  running
                      ? Icons.pause
                      : paused
                      ? Icons.play_arrow
                      : finished
                      ? Icons.replay
                      : Icons.play_arrow,
                ),
                label: Text(
                  running
                      ? l10n.pause
                      : paused
                      ? l10n.resume
                      : finished
                      ? l10n.playAgain
                      : l10n.startPractice,
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.surfaceLight,
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (running || paused)
              FilledButton.tonalIcon(
                onPressed: () => bloc.add(const TeacherStopped()),
                icon: const Icon(Icons.stop),
                label: Text(l10n.finish),
              ),
          ],
        ),
        if (state.cameraError != null || state.micError != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              <String>[
                if (state.cameraError != null) state.cameraError!,
                if (state.micError != null) state.micError!,
              ].join('\n'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.secondary,
              ),
            ),
          ),
        const SizedBox(height: 16),
        // chord ribbon
        Text(l10n.chords, style: _h(theme)),
        const SizedBox(height: 8),
        ChordRibbon(
          plan: plan,
          currentIndex: snapshot?.targetIndex ?? 0,
          targetProgress: snapshot?.targetProgress ?? 0,
        ),
        const SizedBox(height: 16),
        // strumming
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(l10n.strummingPatternLabel, style: _h(theme)),
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
          currentSlot: snapshot?.phase == TeacherPhase.running
              ? snapshot!.slotIndex
              : -1,
          results: slotResults,
        ),
        const SizedBox(height: 16),
        // tempo & capo
        Row(
          children: <Widget>[
            Text('${l10n.tempo}: ${state.bpm} BPM', style: _h(theme)),
            const Spacer(),
            Text(
              '${l10n.bar} ${snapshot?.bar ?? 0}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textOnDark.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        Slider(
          value: state.bpm.toDouble(),
          min: 40,
          max: 180,
          divisions: 140,
          label: '${state.bpm}',
          onChanged: (v) => bloc.add(TeacherBpmChanged(v.round())),
        ),
        if (plan.mode == PracticeMode.song) ...<Widget>[
          Text(l10n.capoLabel(state.capo), style: _h(theme)),
          Slider(
            value: state.capo.toDouble(),
            min: 0,
            max: 7,
            divisions: 7,
            label: '${state.capo}',
            onChanged: running
                ? null
                : (v) => bloc.add(TeacherCapoChanged(v.round())),
          ),
        ],
        // toggles
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: <Widget>[
            FilterChip(
              avatar: Icon(
                state.cameraEnabled ? Icons.videocam : Icons.videocam_off,
                size: 18,
              ),
              label: Text(l10n.camera),
              labelStyle: _chipLabel(state.cameraEnabled),
              selected: state.cameraEnabled,
              onSelected: state.cameraSupported
                  ? (v) => bloc.add(TeacherCameraToggled(v))
                  : null,
            ),
            FilterChip(
              avatar: Icon(
                state.micEnabled ? Icons.mic : Icons.mic_off,
                size: 18,
              ),
              label: Text(l10n.microphone),
              labelStyle: _chipLabel(state.micEnabled),
              selected: state.micEnabled,
              onSelected: state.micSupported
                  ? (v) => bloc.add(TeacherMicToggled(v))
                  : null,
            ),
            FilterChip(
              avatar: const Icon(Icons.timer_outlined, size: 18),
              label: Text(l10n.metronome),
              labelStyle: _chipLabel(state.metronomeEnabled),
              selected: state.metronomeEnabled,
              onSelected: (v) => bloc.add(TeacherMetronomeToggled(v)),
            ),
          ],
        ),
        if (!state.handTrackingSupported && state.cameraSupported)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              l10n.handTrackingWebOnly,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textOnDark.withValues(alpha: 0.6),
              ),
            ),
          ),
        const SizedBox(height: 16),
        // how to play
        if (snapshot?.targetVoicing != null) ...<Widget>[
          Text(
            '${l10n.howToPlay} ${snapshot!.targetVoicing!.name}',
            style: _h(theme),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ChordDiagram(
                voicing: snapshot.targetVoicing!,
                size: 110,
                showName: false,
                color: AppColors.textOnDark,
                accent: AppColors.successGold,
                highlightFingers: snapshot.shape.usedFingers,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children:
                      ChordShapeCoach.placementText(snapshot.targetVoicing!)
                          .map(
                            (line) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                '• $line',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.textOnDark,
                                ),
                              ),
                            ),
                          )
                          .toList(growable: false),
                ),
              ),
            ],
          ),
          if (snapshot.shape.handVisible && snapshot.shape.hints.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                snapshot.shape.hints.first,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.successGold,
                ),
              ),
            ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  TextStyle _chipLabel(bool selected) => TextStyle(
    color: selected ? Colors.white : AppColors.textOnLight,
    fontWeight: FontWeight.w600,
  );

  TextStyle? _h(ThemeData theme) => theme.textTheme.titleSmall?.copyWith(
    fontWeight: FontWeight.bold,
    color: AppColors.textOnDark,
  );
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.state});

  final TeacherState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final bloc = context.read<TeacherBloc>();
    final snapshot = state.snapshot!;
    final minutes = (snapshot.elapsedMs / 60000).floor();
    final seconds = ((snapshot.elapsedMs / 1000) % 60).round();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[AppColors.primary, Color(0xFF6D28D9)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            l10n.sessionComplete,
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              AccuracyRing(
                value: snapshot.overallScore / 100,
                label: l10n.overall,
              ),
              AccuracyRing(
                value: snapshot.chordAccuracy,
                label: l10n.chordsShort,
              ),
              AccuracyRing(
                value: snapshot.timingAccuracy,
                label: l10n.timing,
                color: snapshot.strums == 0 ? Colors.white24 : null,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${snapshot.chordsPlayed} ${l10n.chordsPlayed} · ${snapshot.strums} ${l10n.strums} · '
            '${minutes}m ${seconds}s',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: FilledButton.icon(
                  onPressed: state.saved || state.saving
                      ? null
                      : () => bloc.add(const TeacherSessionSaveRequested()),
                  icon: Icon(state.saved ? Icons.check : Icons.save),
                  label: Text(
                    state.saved ? l10n.sessionSaved : l10n.savePractice,
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () => popOrGoHome(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white54),
                ),
                child: Text(l10n.done),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Helper so lesson screens can start the teacher for a lesson quickly.
TeacherRequest teacherRequestForLesson(Lesson lesson) =>
    TeacherRequest.lesson(lesson.id);
