import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sursaar/l10n/app_localizations.dart';

import '../../core/theme/app_colors.dart';
import '../../models/song.dart';
import '../../tutor/tutor_brain.dart';
import '../../tutor/tutor_repository.dart';
import '../../widgets/app_back_button.dart';
import '../../widgets/tutor/tutor_widgets.dart';

/// The song library: four shelves, ordered by how good a next step each song
/// is for this player.
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key, this.initialShelf});

  final SongCollection? initialShelf;

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  late final TutorRepository _tutor = context.read<TutorRepository>();
  late Future<List<TutorPick>> _picks = _tutor.recommendations();
  late SongCollection? _shelf = widget.initialShelf;
  SongDifficulty? _difficulty;
  bool _readyOnly = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _tutor.revision.addListener(_reload);
  }

  @override
  void dispose() {
    _tutor.revision.removeListener(_reload);
    super.dispose();
  }

  void _reload() {
    if (mounted) setState(() => _picks = _tutor.recommendations());
  }

  List<TutorPick> _filter(List<TutorPick> all) {
    final terms = _query
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList();
    return all
        .where((p) {
          final song = p.song;
          if (_shelf != null && song.collection != _shelf) return false;
          if (_difficulty != null && song.difficulty != _difficulty) {
            return false;
          }
          if (_readyOnly && !song.hasMelody && p.newChords.length > 1) {
            return false;
          }
          if (terms.isEmpty) return true;
          final haystack = <String>[
            song.title,
            song.artist,
            song.album ?? '',
            ...song.tags,
            ...song.uniqueChords,
          ].join(' ').toLowerCase();
          return terms.every(haystack.contains);
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Text(l10n.songLibrary),
      ),
      body: FutureBuilder<List<TutorPick>>(
        future: _picks,
        builder: (context, snapshot) {
          final all = snapshot.data;
          if (all == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final shown = _filter(all);
          return CustomScrollView(
            slivers: <Widget>[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: TextField(
                    onChanged: (v) => setState(() => _query = v),
                    decoration: InputDecoration(
                      hintText: l10n.searchLibraryHint,
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: tutorSurface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: <Widget>[
                      for (final shelf in <SongCollection?>[
                        null,
                        ...SongCollection.values,
                      ])
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            // Plain text: emoji metrics on the web canvas
                            // aren't known until the emoji font loads.
                            label: Text(CollectionStyle.label(l10n, shelf)),
                            selected: _shelf == shelf,
                            onSelected: (_) => setState(() => _shelf = shelf),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: <Widget>[
                      for (final d in SongDifficulty.values)
                        FilterChip(
                          label: Text(_difficultyLabel(l10n, d)),
                          selected: _difficulty == d,
                          onSelected: (on) =>
                              setState(() => _difficulty = on ? d : null),
                        ),
                      FilterChip(
                        avatar: const Icon(Icons.bolt, size: 16),
                        label: Text(l10n.readyForMe),
                        selected: _readyOnly,
                        onSelected: (on) => setState(() => _readyOnly = on),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Text(
                    l10n.libraryCount(shown.length),
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              if (shown.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        l10n.noSongsFound,
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  sliver: SliverList.builder(
                    itemCount: shown.length,
                    itemBuilder: (context, index) {
                      final pick = shown[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child:
                            TutorSongTile(
                              pick: pick,
                              onTap: () =>
                                  context.push('/tutor/song/${pick.song.id}'),
                            ).animate().fadeIn(
                              delay: Duration(milliseconds: 25 * (index % 12)),
                              duration: 250.ms,
                            ),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  static String _difficultyLabel(AppLocalizations l10n, SongDifficulty d) =>
      switch (d) {
        SongDifficulty.beginner => l10n.difficultyBeginner,
        SongDifficulty.intermediate => l10n.difficultyIntermediate,
        SongDifficulty.advanced => l10n.difficultyAdvanced,
      };
}
