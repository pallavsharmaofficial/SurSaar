import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sursaar/l10n/app_localizations.dart';

import '../../blocs/course/course_cubit.dart';
import '../../blocs/lesson/lesson_bloc.dart';
import '../../blocs/lesson/lesson_event.dart';
import '../../blocs/lesson/lesson_state.dart';
import '../../core/theme/app_colors.dart';
import '../../models/lesson.dart';
import '../../repositories/course_repository.dart';
import '../../repositories/lesson_repository.dart';
import '../../widgets/course_card.dart';
import '../../widgets/lesson_card.dart';
import '../../widgets/section_header.dart';

/// Courses (guided paths) and the full lesson library.
class LearnScreen extends StatelessWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: <BlocProvider<dynamic>>[
        BlocProvider<CourseCubit>(
          create: (context) =>
              CourseCubit(repository: context.read<CourseRepository>())..load(),
        ),
        BlocProvider<LessonBloc>(
          create: (context) =>
              LessonBloc(repository: context.read<LessonRepository>())
                ..add(const LessonLoadRequested()),
        ),
      ],
      child: const _LearnView(),
    );
  }
}

class _LearnView extends StatelessWidget {
  const _LearnView();

  void _reload(BuildContext context) {
    context.read<CourseCubit>().load();
    context.read<LessonBloc>().add(const LessonLoadRequested());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar.large(title: Text(l10n.learn)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                l10n.lessonsDescription,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppColors.textOnDark,
                ),
              ).animate().fadeIn(duration: 400.ms),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: SectionHeader(title: l10n.courses),
            ),
          ),
          BlocBuilder<CourseCubit, CourseState>(
            builder: (context, state) {
              if (state.loading) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                );
              }
              return SliverToBoxAdapter(
                child: SizedBox(
                  height: 190,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: state.courses.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final course = state.courses[index];
                      return SizedBox(
                        width: 280,
                        child:
                            CourseCard(
                                  progress: course,
                                  onTap: () async {
                                    await context.pushNamed(
                                      'courseDetail',
                                      pathParameters: <String, String>{
                                        'id': course.course.id,
                                      },
                                    );
                                    if (context.mounted) _reload(context);
                                  },
                                )
                                .animate(
                                  delay: Duration(milliseconds: 80 * index),
                                )
                                .fadeIn(),
                      );
                    },
                  ),
                ),
              );
            },
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SectionHeader(title: l10n.allLessons),
                  const SizedBox(height: 8),
                  BlocBuilder<LessonBloc, LessonState>(
                    builder: (context, state) {
                      return Wrap(
                        spacing: 8,
                        children: <Widget>[
                          ChoiceChip(
                            label: Text(l10n.difficultyAll),
                            selected: state.selectedDifficulty == null,
                            onSelected: (_) => context.read<LessonBloc>().add(
                              const LessonDifficultyFilterChanged(null),
                            ),
                          ),
                          for (final d in LessonDifficulty.values)
                            ChoiceChip(
                              label: Text(_difficultyLabel(d)),
                              selected: state.selectedDifficulty == d,
                              onSelected: (_) => context.read<LessonBloc>().add(
                                LessonDifficultyFilterChanged(d),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          BlocBuilder<LessonBloc, LessonState>(
            builder: (context, state) {
              if (state.status == LessonStatus.loading) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                );
              }
              if (state.lessons.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(child: Text(l10n.noLessonsAvailable)),
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                sliver: SliverList.builder(
                  itemCount: state.lessons.length,
                  itemBuilder: (context, index) {
                    final lesson = state.lessons[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child:
                          LessonCard(
                                lesson: lesson,
                                onTap: () async {
                                  await context.pushNamed(
                                    'lessonDetail',
                                    pathParameters: <String, String>{
                                      'id': lesson.id,
                                    },
                                    extra: lesson,
                                  );
                                  if (context.mounted) _reload(context);
                                },
                              )
                              .animate(
                                delay: Duration(milliseconds: 50 * index),
                              )
                              .fadeIn(duration: 300.ms),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  static String _difficultyLabel(LessonDifficulty d) {
    switch (d) {
      case LessonDifficulty.beginner:
        return 'Beginner';
      case LessonDifficulty.intermediate:
        return 'Intermediate';
      case LessonDifficulty.advanced:
        return 'Advanced';
    }
  }
}
