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
import '../../widgets/app_back_button.dart';
import 'practice_settings_sheet.dart';
import 'session_summary.dart';
import 'teacher_panel.dart';
import 'teacher_stage.dart';

/// What the teacher should practise. Resolved to a [PracticePlan] once the
/// content is loaded.
class TeacherRequest {
  const TeacherRequest.song(this.songId, {this.mode})
    : lessonId = null,
      chords = null,
      pattern = null,
      bpm = null;

  const TeacherRequest.lesson(this.lessonId, {this.mode})
    : songId = null,
      chords = null,
      pattern = null,
      bpm = null;

  const TeacherRequest.adhoc({
    required this.chords,
    this.pattern,
    this.bpm,
    this.mode,
  }) : songId = null,
       lessonId = null;

  final String? songId;
  final String? lessonId;
  final List<String>? chords;
  final String? pattern;
  final int? bpm;

  /// Forces learn / play-along instead of the learner's saved preference.
  final CoachingMode? mode;
}

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
        return _TeacherView(plan: plan, mode: widget.request.mode);
      },
    );
  }
}

class _TeacherView extends StatefulWidget {
  const _TeacherView({required this.plan, this.mode});

  final PracticePlan plan;
  final CoachingMode? mode;

  @override
  State<_TeacherView> createState() => _TeacherViewState();
}

class _TeacherViewState extends State<_TeacherView> {
  @override
  void initState() {
    super.initState();
    context.read<TeacherBloc>().add(
      TeacherInitialized(widget.plan, mode: widget.mode),
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
        return Scaffold(
          backgroundColor: AppColors.backgroundDark,
          appBar: appBar,
          body: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 900;
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
                          children: <Widget>[summary, const TeacherPanel()],
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
                        children: <Widget>[summary, const TeacherPanel()],
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
