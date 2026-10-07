import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sursaar/l10n/app_localizations.dart';

import '../../blocs/teacher/teacher_bloc.dart';
import '../../blocs/teacher/teacher_event.dart';
import '../../blocs/teacher/teacher_state.dart';
import '../../core/theme/app_colors.dart';
import '../../data/content/chord_library.dart';
import '../../models/song.dart';
import '../../repositories/lesson_repository.dart';
import '../../repositories/practice_repository.dart';
import '../../repositories/progress_repository.dart';
import '../../repositories/settings_repository.dart';
import '../../repositories/song_repository.dart';
import '../../teacher/engine/practice_plan.dart';
import '../../teacher/engine/teacher_engine.dart';
import '../../teacher/services/audio_capture_service.dart';
import '../../teacher/services/sound_service.dart';
import '../../teacher/services/vision_service.dart';
import '../../tutor/journey.dart';
import '../../tutor/tutor_repository.dart';
import '../../widgets/tutor/sheet_views.dart';
import '../../widgets/app_back_button.dart';
import 'practice_settings_sheet.dart';
import 'session_summary.dart';
import 'teacher_panel.dart';
import 'teacher_stage.dart';
import 'tutor_feedback_card.dart';

/// What the teacher should practise. Resolved to a [PracticePlan] once the
/// content is loaded.
class TeacherRequest {
  const TeacherRequest.song(this.songId, {this.mode})
    : lessonId = null,
      chords = null,
      pattern = null,
      bpm = null,
      stageIndex = null;

  const TeacherRequest.lesson(this.lessonId, {this.mode})
    : songId = null,
      chords = null,
      pattern = null,
      bpm = null,
      stageIndex = null;

  const TeacherRequest.adhoc({
    required this.chords,
    this.pattern,
    this.bpm,
    this.mode,
  }) : songId = null,
       lessonId = null,
       stageIndex = null;

  /// Step [stageIndex] of the tutor journey for [songId].
  const TeacherRequest.stage(String this.songId, int this.stageIndex)
    : lessonId = null,
      chords = null,
      pattern = null,
      bpm = null,
      mode = null;

  final String? songId;

  /// Tutor journey step, when this session is one.
  final int? stageIndex;
  final String? lessonId;
  final List<String>? chords;
  final String? pattern;
  final int? bpm;

  /// Forces learn / play-along instead of the learner's saved preference.
  final CoachingMode? mode;
}

/// Location of step [stageIndex] of the tutor journey for [songId].
String tutorStepLocation(String songId, int stageIndex) =>
    '/tutor/song/$songId/step/$stageIndex';

/// Location of an ad-hoc practice session for [chords].
String adhocPracticeLocation(
  List<String> chords, {
  String? pattern,
  int? bpm,
  CoachingMode mode = CoachingMode.learn,
}) {
  return Uri(
    path: '/practice/adhoc',
    queryParameters: <String, String>{
      'chords': chords.join(','),
      'pattern': ?pattern,
      if (bpm != null) 'bpm': '$bpm',
      'mode': mode.name,
    },
  ).toString();
}

class TeacherScreen extends StatelessWidget {
  const TeacherScreen({
    super.key,
    required this.request,
    this.audioService,
    this.visionService,
    this.soundService,
  });

  final TeacherRequest request;

  /// Replace the microphone, camera and speaker (tests, store screenshots);
  /// by default the platform's own are used.
  final AudioCaptureService? audioService;
  final VisionService? visionService;
  final TeacherSoundService? soundService;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TeacherBloc>(
      create: (context) => TeacherBloc(
        chordLibrary: context.read<ChordLibrary>(),
        settingsRepository: context.read<SettingsRepository>(),
        practiceRepository: context.read<PracticeRepository>(),
        progressRepository: context.read<ProgressRepository>(),
        tutorRepository: context.read<TutorRepository>(),
        audioService: audioService,
        visionService: visionService,
        soundService: soundService,
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
  CoachingMode? _stageMode;

  Future<PracticePlan?> _resolve() async {
    final request = widget.request;
    final settingsRepository = context.read<SettingsRepository>();
    final songRepository = context.read<SongRepository>();
    final lessonRepository = context.read<LessonRepository>();
    final tutorRepository = context.read<TutorRepository>();
    final settings = await settingsRepository.getSettings();
    final stageIndex = request.stageIndex;
    if (request.songId != null && stageIndex != null) {
      final song = await songRepository.getSongById(request.songId!);
      if (song == null) return null;
      final journey = await tutorRepository.journeyFor(song);
      if (stageIndex < 0 || stageIndex >= journey.stages.length) return null;
      final stage = journey.stages[stageIndex];
      _stageMode = stage.mode;
      return JourneyBuilder.planFor(song, stage);
    }
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
            backgroundColor: AppColors.backgroundDark,
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
        return _TeacherView(
          plan: plan,
          mode: widget.request.mode ?? _stageMode,
          journeySongId: widget.request.stageIndex == null
              ? null
              : widget.request.songId,
          stageIndex: widget.request.stageIndex,
        );
      },
    );
  }
}

class _TeacherView extends StatefulWidget {
  const _TeacherView({
    required this.plan,
    this.mode,
    this.journeySongId,
    this.stageIndex,
  });

  final PracticePlan plan;
  final CoachingMode? mode;
  final String? journeySongId;
  final int? stageIndex;

  @override
  State<_TeacherView> createState() => _TeacherViewState();
}

class _TeacherViewState extends State<_TeacherView> {
  @override
  void initState() {
    super.initState();
    context.read<TeacherBloc>().add(
      TeacherInitialized(
        widget.plan,
        mode: widget.mode,
        journeySongId: widget.journeySongId,
        stageIndex: widget.stageIndex,
      ),
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return BlocBuilder<TeacherBloc, TeacherState>(
      buildWhen: (a, b) =>
          a.status != b.status || a.plan?.title != b.plan?.title,
      builder: (context, state) {
        final plan = state.plan ?? widget.plan;
        final appBar = AppBar(
          leading: const AppBackButton(),
          backgroundColor: AppColors.backgroundDark,
          title: Column(
            children: <Widget>[
              Text(plan.title, maxLines: 1, overflow: TextOverflow.ellipsis),
              if (plan.subtitle != null)
                Text(
                  plan.subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.textOnDark.withValues(alpha: 0.7),
                  ),
                ),
            ],
          ),
          actions: <Widget>[
            IconButton(
              tooltip: l10n.displaySettings,
              icon: const Icon(Icons.tune_rounded),
              onPressed: () => PracticeSettingsSheet.show(
                context,
                context.read<TeacherBloc>(),
              ),
            ),
            IconButton(
              tooltip: l10n.aiTeacherHowItWorks,
              icon: const Icon(Icons.info_outline),
              onPressed: () => _showInfo(context),
            ),
          ],
        );
        if (state.status == TeacherStatus.initial) {
          return Scaffold(
            backgroundColor: AppColors.backgroundDark,
            appBar: appBar,
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        final summary = SessionSummary(
          onPracticeTricky: (chords) =>
              context.pushReplacement(adhocPracticeLocation(chords)),
          onDone: () => popOrGoHome(context),
        );
        final showSheet = _followsSong(plan);
        return Scaffold(
          backgroundColor: AppColors.backgroundDark,
          appBar: appBar,
          body: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 900;
              final extraWide = constraints.maxWidth >= 1280 && showSheet;
              if (extraWide) {
                // Camera | the song's sheet | coach panel, side by side.
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const Expanded(flex: 3, child: TeacherStage()),
                    SizedBox(
                      width: 340,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 0, 16),
                        child: SheetPanel(
                          maxHeight: constraints.maxHeight - 120,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 420,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            summary,
                            const TutorFeedbackCard(),
                            const TeacherPanel(),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }
              if (wide) {
                return Row(
                  children: <Widget>[
                    const Expanded(flex: 3, child: TeacherStage()),
                    SizedBox(
                      width: 420,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            summary,
                            const TutorFeedbackCard(),
                            if (showSheet) const SheetPanel(),
                            const TeacherPanel(),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }
              return CustomScrollView(
                slivers: <Widget>[
                  const SliverToBoxAdapter(
                    child: AspectRatio(
                      aspectRatio: 4 / 3,
                      child: TeacherStage(),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          summary,
                          const TutorFeedbackCard(),
                          if (showSheet) const SheetPanel(),
                          const TeacherPanel(),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

/// Whether [plan] walks through a song's own timeline (so the chord chart
/// or tab is worth showing next to the camera).
bool _followsSong(PracticePlan plan) =>
    plan.isMelody ||
    (plan.mode == PracticeMode.song &&
        plan.targets.any(
          (t) => !t.section.startsWith('Round ') && t.section != 'Changes',
        ));

/// The song's chord chart (or tab, for melodies) following the tutor.
class SheetPanel extends StatelessWidget {
  const SheetPanel({super.key, this.maxHeight = 240});

  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return BlocBuilder<TeacherBloc, TeacherState>(
      buildWhen: (a, b) =>
          a.plan != b.plan ||
          a.mode != b.mode ||
          a.phase != b.phase ||
          a.snapshot?.targetIndex != b.snapshot?.targetIndex ||
          a.snapshot?.noteDetection?.midi != b.snapshot?.noteDetection?.midi,
      builder: (context, state) {
        final plan = state.plan;
        final snap = state.snapshot;
        if (plan == null) return const SizedBox.shrink();
        var current = -1;
        if (snap != null && state.phase != TeacherPhase.idle) {
          if (state.mode == CoachingMode.learn) {
            final map = stepTargets(plan);
            if (snap.targetIndex < map.length) current = map[snap.targetIndex];
          } else {
            current = snap.targetIndex;
          }
        }
        final heard = snap?.noteDetection;
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                plan.isMelody ? l10n.tabSheet : l10n.chordSheet,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              if (plan.isMelody)
                TabStaffView(
                  plan: plan,
                  currentTarget: current,
                  heardMidi: heard == null || heard.isSilent
                      ? null
                      : heard.midi,
                )
              else
                SongSheetView(
                  plan: plan,
                  currentTarget: current,
                  maxHeight: maxHeight,
                ),
            ],
          ),
        );
      },
    );
  }
}
