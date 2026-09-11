import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sursaar/l10n/app_localizations.dart';

import '../../blocs/progress/progress_bloc.dart';
import '../../blocs/progress/progress_event.dart';
import '../../blocs/progress/progress_state.dart';
import '../../core/theme/app_colors.dart';
import '../../models/achievement.dart';
import '../../models/practice_session.dart';
import '../../repositories/achievement_repository.dart';
import '../../repositories/practice_repository.dart';
import '../../repositories/progress_repository.dart';
import '../../widgets/progress_stat_card.dart';
import '../../widgets/section_header.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          ProgressBloc(repository: context.read<ProgressRepository>())
            ..add(const ProgressLoadRequested()),
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
          SliverAppBar.large(title: Text(l10n.progress)),
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
                        crossAxisCount: MediaQuery.of(context).size.width > 700
                            ? 4
                            : 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.5,
                        children:
                            <Widget>[
                                  ProgressStatCard(
                                    icon: Icons.access_time,
                                    label: l10n.practiceTime,
                                    value: '${progress.totalPracticeTime}',
                                    unit: l10n.minutes,
                                  ),
                                  ProgressStatCard(
                                    icon: Icons.music_note,
                                    label: l10n.songsLearned,
                                    value: '${progress.songsLearned}',
                                  ),
                                  ProgressStatCard(
                                    icon: Icons.local_fire_department,
                                    label: l10n.currentStreak,
                                    value: '${progress.currentStreak}',
                                    unit: l10n.days,
                                  ),
                                  ProgressStatCard(
                                    icon: Icons.school,
                                    label: l10n.lessonsCompleted,
                                    value: '${progress.lessonsCompleted}',
                                  ),
                                ]
                                .animate(interval: 80.ms)
                                .fadeIn(duration: 350.ms)
                                .scale(begin: const Offset(0.9, 0.9)),
                      ),
                      const SizedBox(height: 24),
                      Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: <Color>[
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
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: AppColors.surfaceLight,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${l10n.level} ${progress.level} · ${progress.xp} ${l10n.xpLabel}',
                                      style: theme.textTheme.headlineSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.surfaceLight,
                                          ),
                                    ),
                                    const SizedBox(height: 8),
                                    SizedBox(
                                      width: 180,
                                      child: LinearProgressIndicator(
                                        value: (progress.xp % 100) / 100,
                                        minHeight: 6,
                                        color: AppColors.successGold,
                                        backgroundColor: Colors.white24,
                                        borderRadius: BorderRadius.circular(3),
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
                          .fadeIn(delay: 300.ms, duration: 400.ms)
                          .slideY(begin: 0.2, end: 0),
                      if (progress.averageAccuracy > 0) ...<Widget>[
                        const SizedBox(height: 24),
                        SectionHeader(title: l10n.averageAccuracy),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: <Widget>[
                              Expanded(
                                child: LinearProgressIndicator(
                                  value: progress.averageAccuracy / 100,
                                  minHeight: 8,
                                  borderRadius: BorderRadius.circular(4),
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
                        ),
                      ],
                      const SizedBox(height: 24),
                      SectionHeader(title: l10n.recentSessions),
                      const SizedBox(height: 12),
                      FutureBuilder<List<PracticeSession>>(
                        future: context
                            .read<PracticeRepository>()
                            .getSessions(),
                        builder: (context, snapshot) {
                          final sessions =
                              (snapshot.data ?? const <PracticeSession>[])
                                  .take(8)
                                  .toList();
                          if (sessions.isEmpty) {
                            return Text(
                              l10n.noSessions,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppColors.textOnDark,
                              ),
                            );
                          }
                          return Column(
                            children: sessions
                                .map((s) => _SessionTile(session: s))
                                .toList(growable: false),
                          );
                        },
                      ),
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
                                                    .textTheme
                                                    .titleSmall
                                                    ?.copyWith(
                                                      color:
                                                          AppColors.textOnLight,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                achievement.description,
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                      color:
                                                          AppColors.textOnLight,
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
                      const SizedBox(height: 24),
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

class _SessionTile extends StatelessWidget {
  const _SessionTile({required this.session});

  final PracticeSession session;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = session.startTime;
    final when =
        '${date.day}/${date.month} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    final score = session.accuracyScore.round();
    final color = score >= 80
        ? const Color(0xFF22C55E)
        : score >= 50
        ? const Color(0xFFF59E0B)
        : const Color(0xFFEF4444);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$score%',
              style: theme.textTheme.labelLarge?.copyWith(
                color: color,
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
                  session.songId.replaceAll('_', ' '),
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppColors.textOnLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '$when · ${(session.duration / 60).ceil()} min · ${session.chordsPlayed} chords'
                  '${session.timingAccuracy != null ? ' · timing ${session.timingAccuracy!.round()}%' : ''}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textOnLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
