import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:sursaar/l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../blocs/lesson/lesson_bloc.dart';
import '../../blocs/lesson/lesson_event.dart';
import '../../blocs/lesson/lesson_state.dart';
import '../../repositories/content_repository.dart';
import '../../repositories/lesson_repository.dart';
import '../../widgets/lesson_card.dart';
import '../../widgets/section_header.dart';

class LessonsScreen extends StatelessWidget {
  const LessonsScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LessonBloc(
        repository: context.read<LessonRepository>(),
        contentRepository: context.read<ContentRepository>(),
      )..add(const LessonLoadRequested()),
      child: const _LessonsView(),
    );
  }
}

class _LessonsView extends StatelessWidget {
  const _LessonsView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar.large(
            title: Text(l10n.lessons),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    l10n.lessonsDescription,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: AppColors.textOnDark,
                    ),
                  ).animate().fadeIn(duration: 400.ms),
                  const SizedBox(height: 24),
                  SectionHeader(title: l10n.allLessons),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          BlocBuilder<LessonBloc, LessonState>(
            builder: (context, state) {
              if (state.status == LessonStatus.loading) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (state.lessons.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Text(l10n.noLessonsAvailable),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                sliver: SliverList.builder(
                  itemCount: state.lessons.length,
                  itemBuilder: (context, index) {
                    final lesson = state.lessons[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: LessonCard(
                        lesson: lesson,
                        onTap: () async {
                          await context.pushNamed(
                            'lessonDetail',
                            pathParameters: {'id': lesson.id},
                            extra: lesson,
                          );
                          if (context.mounted) {
                            context
                                .read<LessonBloc>()
                                .add(const LessonLoadRequested());
                          }
                        },
                      )
                          .animate(delay: Duration(milliseconds: 100 * index))
                          .fadeIn(duration: 400.ms)
                          .slideX(begin: 0.1, end: 0),
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
}
