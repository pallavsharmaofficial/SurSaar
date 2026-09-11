import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sursaar/l10n/app_localizations.dart';

import '../../blocs/song_finder/song_finder_bloc.dart';
import '../../blocs/song_finder/song_finder_event.dart';
import '../../blocs/song_finder/song_finder_state.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../repositories/song_repository.dart';
import '../../widgets/capo_slider.dart';
import '../../widgets/chord_chip.dart';
import '../../widgets/enhanced_song_card.dart';
import '../../widgets/quick_practice_sheet.dart';
import '../../widgets/section_header.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          SongFinderBloc(repository: context.read<SongRepository>())
            ..add(const SongFinderStarted()),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          context.read<SongFinderBloc>().add(const SongFinderRefreshed());
        },
        child: CustomScrollView(
          slivers: <Widget>[
            SliverAppBar.large(
              title: Text(l10n.appTitle),
              actions: <Widget>[
                IconButton(
                  tooltip: l10n.searchSongs,
                  icon: const Icon(Icons.search),
                  onPressed: () => context.pushNamed('search'),
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: _TeacherHero(l10n: l10n, theme: theme),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                          l10n.findSongsHeadline,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textOnDark,
                          ),
                        )
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .slideX(begin: -0.2, end: 0, curve: Curves.easeOut),
                    const SizedBox(height: 8),
                    Text(
                      l10n.songFinderDescription,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textOnDark,
                      ),
                    ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
                  ],
                ),
              ),
            ),
            BlocBuilder<SongFinderBloc, SongFinderState>(
              builder: (context, state) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        SectionHeader(title: l10n.selectChordLabel),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: AppConstants.chords
                              .map(
                                (chord) => ChordChip(
                                  chord: chord,
                                  isSelected: chord == state.selectedChord,
                                  onSelected: () => context
                                      .read<SongFinderBloc>()
                                      .add(SongFinderChordSelected(chord)),
                                ),
                              )
                              .toList(growable: false),
                        ),
                        const SizedBox(height: 24),
                        CapoSlider(
                          capoFret: state.capoFret,
                          maxCapoFret: AppConstants.maxCapoFret,
                          onChanged: (value) => context
                              .read<SongFinderBloc>()
                              .add(SongFinderCapoUpdated(value)),
                        ),
                        const SizedBox(height: 24),
                        SectionHeader(
                          title: l10n.recommendedSongsLabel,
                          trailing: state.filteredSongs.isNotEmpty
                              ? Text(
                                  '${state.filteredSongs.length} ${l10n.songs}',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: AppColors.secondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                );
              },
            ),
            BlocBuilder<SongFinderBloc, SongFinderState>(
              builder: (context, state) {
                if (state.status == SongFinderStatus.loading) {
                  return const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (state.filteredSongs.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            const Icon(
                              Icons.music_off,
                              size: 80,
                              color: AppColors.surfaceLight,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              l10n.noSongsFound,
                              style: theme.textTheme.titleMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.tryDifferentChord,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  sliver: SliverList.builder(
                    itemCount: state.filteredSongs.length,
                    itemBuilder: (context, index) {
                      final song = state.filteredSongs[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child:
                            EnhancedSongCard(
                                  song: song,
                                  capoFret: state.capoFret,
                                  onTap: () async {
                                    await context.pushNamed(
                                      'songDetail',
                                      pathParameters: <String, String>{
                                        'id': song.id,
                                      },
                                      extra: song,
                                    );
                                    if (context.mounted) {
                                      context.read<SongFinderBloc>().add(
                                        const SongFinderRefreshed(),
                                      );
                                    }
                                  },
                                )
                                .animate(
                                  delay: Duration(milliseconds: 60 * index),
                                )
                                .fadeIn(duration: 350.ms)
                                .slideY(begin: 0.05, end: 0),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _TeacherHero extends StatelessWidget {
  const _TeacherHero({required this.l10n, required this.theme});

  final AppLocalizations l10n;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[AppColors.primary, Color(0xFF7C3AED)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.auto_awesome, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                l10n.aiTeacher,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            l10n.aiTeacherTagline,
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              FilledButton.icon(
                onPressed: () => QuickPracticeSheet.show(context),
                icon: const Icon(Icons.bolt),
                label: Text(l10n.quickPractice),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => context.go('/learn'),
                icon: const Icon(Icons.school_outlined),
                label: Text(l10n.courses),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white54),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }
}
