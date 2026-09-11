import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sursaar/l10n/app_localizations.dart';

import '../../core/theme/app_colors.dart';
import '../../repositories/course_repository.dart';
import '../../widgets/difficulty_badge.dart';
import '../../widgets/app_back_button.dart';

class CourseDetailScreen extends StatefulWidget {
  const CourseDetailScreen({super.key, required this.courseId});

  final String courseId;

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  late Future<CourseProgress?> _future = _load();

  Future<CourseProgress?> _load() =>
      context.read<CourseRepository>().getCourseById(widget.courseId);

  void _refresh() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return FutureBuilder<CourseProgress?>(
      future: _future,
      builder: (context, snapshot) {
        final progress = snapshot.data;
        if (snapshot.connectionState != ConnectionState.done) {
          return Scaffold(
            appBar: AppBar(leading: const AppBackButton()),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (progress == null) {
          return Scaffold(
            appBar: AppBar(leading: const AppBackButton()),
            body: Center(child: Text(l10n.noLessonsAvailable)),
          );
        }
        final course = progress.course;
        final next = progress.nextLesson;
        return Scaffold(
          appBar: AppBar(
            leading: const AppBackButton(),
            title: Text(course.title),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              Row(
                children: <Widget>[
                  Text(course.emoji, style: const TextStyle(fontSize: 40)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          course.description,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: AppColors.textOnDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: <Widget>[
                            DifficultyBadge(difficulty: course.difficulty),
                            const SizedBox(width: 10),
                            Text(
                              '${course.estimatedMinutes} min',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.textOnDark,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: progress.fraction,
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 6),
              Text(
                progress.isCompleted
                    ? l10n.courseComplete
                    : '${progress.completedCount}/${progress.lessons.length} ${l10n.lessonsCompleted}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textOnDark,
                ),
              ),
              const SizedBox(height: 16),
              if (next != null)
                FilledButton.icon(
                  onPressed: () async {
                    await context.pushNamed(
                      'lessonDetail',
                      pathParameters: <String, String>{'id': next.id},
                      extra: next,
                    );
                    _refresh();
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: Text(
                    '${progress.completedCount == 0 ? l10n.startCourse : l10n.continueCourse}: ${next.title}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.surfaceLight,
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              const SizedBox(height: 20),
              ...progress.lessons.asMap().entries.map((entry) {
                final index = entry.key;
                final lesson = entry.value;
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: lesson.isCompleted
                          ? AppColors.primary
                          : AppColors.backgroundDark,
                      child: lesson.isCompleted
                          ? const Icon(Icons.check, color: Colors.white)
                          : Text(
                              '${index + 1}',
                              style: const TextStyle(color: Colors.white),
                            ),
                    ),
                    title: Text(
                      lesson.title,
                      style: const TextStyle(
                        color: AppColors.textOnLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      '${lesson.duration} min · ${lesson.kind.name}',
                      style: const TextStyle(color: AppColors.textOnLight),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: AppColors.textOnLight,
                    ),
                    onTap: () async {
                      await context.pushNamed(
                        'lessonDetail',
                        pathParameters: <String, String>{'id': lesson.id},
                        extra: lesson,
                      );
                      _refresh();
                    },
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
