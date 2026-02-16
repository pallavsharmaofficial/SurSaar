import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
import '../../widgets/section_header.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SongFinderBloc(
        repository: context.read<SongRepository>(),
      )..add(const SongFinderStarted()),
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
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar.large(
            title: Text(l10n.appTitle),
            actions: <Widget>[
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  // TODO: Implement search
                },
              ),
            ],
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
                  ).animate().fadeIn(duration: 400.ms).slideX(
                        begin: -0.2,
                        end: 0,
                        curve: Curves.easeOut,
                      ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.songFinderDescription,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textOnDark,
                    ),
                  ).animate().fadeIn(
                        delay: 100.ms,
                        duration: 400.ms,
                      ),
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
                      const SizedBox(height: 16),
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
                      )
                          .animate()
                          .fadeIn(delay: 200.ms, duration: 400.ms)
                          .slideY(begin: 0.1, end: 0),
                      const SizedBox(height: 24),
                      CapoSlider(
                        capoFret: state.capoFret,
                        maxCapoFret: AppConstants.maxCapoFret,
                        onChanged: (value) => context
                            .read<SongFinderBloc>()
                            .add(SongFinderCapoUpdated(value)),
                      )
                          .animate()
                          .fadeIn(delay: 300.ms, duration: 400.ms)
                          .slideY(begin: 0.1, end: 0),
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
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                sliver: SliverToBoxAdapter(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 450),
                    switchInCurve: Curves.elasticOut,
                    switchOutCurve: Curves.easeIn,
                    child: ListView.builder(
                      key: ValueKey<String>(
                        '${state.selectedChord}-${state.capoFret}',
                      ),
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: state.filteredSongs.length,
                      itemBuilder: (context, index) {
                        final song = state.filteredSongs[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: EnhancedSongCard(
                            song: song,
                            capoFret: state.capoFret,
                            onTap: () async {
                              await context.pushNamed(
                                'songDetail',
                                pathParameters: {'id': song.id},
                                extra: song,
                              );
                              if (context.mounted) {
                                context
                                    .read<SongFinderBloc>()
                                    .add(const SongFinderStarted());
                              }
                            },
                          )
                              .animate(
                                delay: Duration(milliseconds: 80 * index),
                              )
                              .fadeIn(duration: 350.ms)
                              .scale(
                                begin: const Offset(0.98, 0.98),
                                end: const Offset(1, 1),
                                curve: Curves.elasticOut,
                              ),
                        );
                      },
                    ),
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
