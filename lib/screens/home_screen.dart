import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sursaar/l10n/app_localizations.dart';
import '../blocs/song_finder/song_finder_bloc.dart';
import '../blocs/song_finder/song_finder_event.dart';
import '../blocs/song_finder/song_finder_state.dart';
import '../core/constants/app_constants.dart';
import '../repositories/song_repository.dart';
import '../widgets/capo_slider.dart';
import '../widgets/chord_chip.dart';
import '../widgets/song_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider(
      create: (_) => const SongRepository(),
      child: BlocProvider(
        create: (context) => SongFinderBloc(
          repository: context.read<SongRepository>(),
        )..add(const SongFinderStarted()),
        child: const _HomeView(),
      ),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
      ),
      body: BlocBuilder<SongFinderBloc, SongFinderState>(
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              Text(
                l10n.findSongsHeadline,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Text(
                l10n.selectChordLabel,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
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
              const SizedBox(height: 20),
              CapoSlider(
                capoFret: state.capoFret,
                maxCapoFret: AppConstants.maxCapoFret,
                onChanged: (value) => context
                    .read<SongFinderBloc>()
                    .add(SongFinderCapoUpdated(value)),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.recommendedSongsLabel,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (state.filteredSongs.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    l10n.noSongsFound,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                )
              else
                ...state.filteredSongs.map(
                  (song) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SongCard(
                      song: song,
                      capoFret: state.capoFret,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
