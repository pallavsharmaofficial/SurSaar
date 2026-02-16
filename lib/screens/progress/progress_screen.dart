import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sursaar/l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../blocs/progress/progress_bloc.dart';
import '../../blocs/progress/progress_event.dart';
import '../../blocs/progress/progress_state.dart';
import '../../models/achievement.dart';
import '../../repositories/achievement_repository.dart';
import '../../repositories/progress_repository.dart';
import '../../widgets/progress_stat_card.dart';
import '../../widgets/section_header.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ProgressBloc(
        repository: context.read<ProgressRepository>(),
      )..add(const ProgressLoadRequested()),
      child: const _ProgressView(),
    );
  }
}

class _ProgressView extends StatelessWidget {
  const _ProgressView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar.large(
            title: Text(l10n.progress),
          ),
          BlocBuilder<ProgressBloc, ProgressState>(
            builder: (context, state) {
              if (state.status == ProgressStatus.loading) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final progress = state.progress;

              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      SectionHeader(title: l10n.yourStats),
                      const SizedBox(height: 16),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.5,
                        children: <Widget>[
                          ProgressStatCard(
                            icon: Icons.access_time,
                            label: l10n.practiceTime,
                            value: '${progress.totalPracticeTime}',
                            unit: l10n.minutes,
                          )
                              .animate()
                              .fadeIn(delay: 100.ms, duration: 400.ms)
                              .scale(begin: const Offset(0.8, 0.8)),
                          ProgressStatCard(
                            icon: Icons.music_note,
                            label: l10n.songsLearned,
                            value: '${progress.songsLearned}',
                          )
                              .animate()
                              .fadeIn(delay: 200.ms, duration: 400.ms)
                              .scale(begin: const Offset(0.8, 0.8)),
                          ProgressStatCard(
                            icon: Icons.local_fire_department,
                            label: l10n.currentStreak,
                            value: '${progress.currentStreak}',
                            unit: l10n.days,
                          )
                              .animate()
                              .fadeIn(delay: 300.ms, duration: 400.ms)
                              .scale(begin: const Offset(0.8, 0.8)),
                          ProgressStatCard(
                            icon: Icons.school,
                            label: l10n.lessonsCompleted,
                            value: '${progress.lessonsCompleted}',
                          )
                              .animate()
                              .fadeIn(delay: 400.ms, duration: 400.ms)
                              .scale(begin: const Offset(0.8, 0.8)),
                          ProgressStatCard(
                            icon: Icons.bolt,
                            label: l10n.xpLabel,
                            value: '${progress.xp}',
                          )
                              .animate()
                              .fadeIn(delay: 450.ms, duration: 400.ms)
                              .scale(begin: const Offset(0.8, 0.8)),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SectionHeader(title: l10n.level),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              AppColors.primary,
                              AppColors.secondary,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  l10n.currentLevel,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: AppColors.surfaceLight,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${l10n.level} ${progress.level}',
                                  style: theme.textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.surfaceLight,
                                  ),
                                ),
                              ],
                            ),
                            const Icon(
                              Icons.emoji_events,
                              size: 48,
                              color: AppColors.successGold,
                            ),
                          ],
                        ),
                      )
                          .animate()
                          .fadeIn(delay: 500.ms, duration: 400.ms)
                          .slideY(begin: 0.2, end: 0),
                      const SizedBox(height: 24),
                      if (progress.averageAccuracy > 0) ...[
                        SectionHeader(title: l10n.accuracy),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: <Widget>[
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      l10n.averageAccuracy,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: AppColors.textOnLight,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    LinearProgressIndicator(
                                      value: progress.averageAccuracy / 100,
                                      minHeight: 8,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Text(
                                '${progress.averageAccuracy.toStringAsFixed(0)}%',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textOnLight,
                                ),
                              ),
                            ],
                          ),
                        )
                            .animate()
                            .fadeIn(delay: 600.ms, duration: 400.ms)
                            .slideY(begin: 0.2, end: 0),
                      ],
                      const SizedBox(height: 24),
                      SectionHeader(title: l10n.achievements),
                      const SizedBox(height: 12),
                      FutureBuilder<List<Achievement>>(
                        future: context
                            .read<AchievementRepository>()
                            .getAchievements(),
                        builder: (context, snapshot) {
                          final achievements = snapshot.data ?? <Achievement>[];
                          if (achievements.isEmpty) {
                            return Text(
                              l10n.noAchievements,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppColors.textOnDark,
                              ),
                            );
                          }
                          return Column(
                            children: achievements
                                .map(
                                  (achievement) => Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceLight,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: <Widget>[
                                        SvgPicture.asset(
                                          achievement.iconAsset,
                                          width: 32,
                                          height: 32,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: <Widget>[
                                              Text(
                                                achievement.title,
                                                style: theme
                                                    .textTheme.titleSmall
                                                    ?.copyWith(
                                                  color: AppColors.textOnLight,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                achievement.description,
                                                style: theme
                                                    .textTheme.bodySmall
                                                    ?.copyWith(
                                                  color: AppColors.textOnLight,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                                .toList(growable: false),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
