import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sursaar/l10n/app_localizations.dart';

import '../../core/theme/app_colors.dart';
import '../../data/content/chord_library.dart';
import '../../models/lesson.dart';
import '../../models/strumming_pattern.dart';
import '../../repositories/lesson_repository.dart';
import '../../repositories/progress_repository.dart';
import '../../widgets/difficulty_badge.dart';
import '../../widgets/teacher/chord_diagram.dart';
import '../../widgets/teacher/strumming_timeline.dart';

class LessonDetailScreen extends StatefulWidget {
  const LessonDetailScreen({
    super.key,
    required this.lessonId,
    this.initialLesson,
  });

  final String lessonId;
  final Lesson? initialLesson;

  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen> {
  Lesson? _lesson;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _lesson = widget.initialLesson;
    _load();
  }

  Future<void> _load() async {
    final lesson = await context.read<LessonRepository>().getLessonById(
      widget.lessonId,
    );
    if (!mounted) return;
    setState(() {
      _lesson = lesson ?? _lesson;
      _loading = false;
    });
  }

  Future<void> _markComplete() async {
    final lesson = _lesson;
    if (lesson == null) return;
    final wasCompleted = lesson.isCompleted;
    await context.read<LessonRepository>().updateLessonProgress(
      lessonId: lesson.id,
      progress: 1.0,
      isCompleted: true,
    );
    if (!wasCompleted && mounted) {
      await context.read<ProgressRepository>().incrementLessonsCompleted();
    }
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final lesson = _lesson;
    if (lesson == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: _loading
              ? const CircularProgressIndicator()
              : Text(l10n.noLessonsAvailable),
        ),
      );
    }
    final library = context.read<ChordLibrary>();
    return Scaffold(
      appBar: AppBar(title: Text(lesson.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Row(
            children: <Widget>[
              DifficultyBadge(difficulty: lesson.difficulty),
              const SizedBox(width: 8),
              if (lesson.category != null)
                Text(
                  lesson.category!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textOnDark,
                  ),
                ),
              const Spacer(),
              Text(
                '${lesson.duration} min',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textOnDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            lesson.description,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: AppColors.textOnDark,
            ),
          ),
          const SizedBox(height: 16),
          if (lesson.isPracticable)
            FilledButton.icon(
              onPressed: () => context.pushNamed(
                'practiceLesson',
                pathParameters: <String, String>{'id': lesson.id},
              ),
              icon: const Icon(Icons.auto_awesome),
              label: Text(l10n.practiceWithTeacher),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.surfaceLight,
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          if (lesson.targetChords.isNotEmpty) ...<Widget>[
            const SizedBox(height: 20),
            Text(
              l10n.chords,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textOnDark,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 170,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: lesson.targetChords.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final voicing = library.voicingFor(
                    lesson.targetChords[index],
                  );
                  if (voicing == null) {
                    return Chip(label: Text(lesson.targetChords[index]));
                  }
                  return Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ChordDiagram(
                      voicing: voicing,
                      size: 90,
                      color: AppColors.textOnLight,
                    ),
                  );
                },
              ),
            ),
          ],
          if (lesson.targetStrumming != null) ...<Widget>[
            const SizedBox(height: 16),
            Text(
              '${l10n.strummingPatternLabel}: ${lesson.targetStrumming}'
              '${lesson.targetBpm != null ? ' · ${lesson.targetBpm} BPM' : ''}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textOnDark,
              ),
            ),
            const SizedBox(height: 8),
            StrummingTimeline(
              pattern: StrummingPattern.parse(lesson.targetStrumming!),
            ),
          ],
          const SizedBox(height: 24),
          Text(
            l10n.lessonSteps,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textOnDark,
            ),
          ),
          const SizedBox(height: 12),
          ...lesson.steps.asMap().entries.map((entry) {
            final index = entry.key;
            final step = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: AppColors.surfaceLight,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          step.title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textOnLight,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          step.description,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textOnLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${step.durationMinutes}m',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textOnLight,
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 16),
          FilledButton.tonalIcon(
            onPressed: lesson.isCompleted ? null : _markComplete,
            icon: Icon(lesson.isCompleted ? Icons.check_circle : Icons.check),
            label: Text(
              lesson.isCompleted ? l10n.completed : l10n.markComplete,
            ),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
