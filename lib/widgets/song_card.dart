import 'package:flutter/material.dart';
import 'package:sursaar/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import '../core/utils/chord_transposer.dart';
import '../models/song.dart';

class SongCard extends StatelessWidget {
  const SongCard({
    super.key,
    required this.song,
    required this.capoFret,
  });

  final Song song;
  final int capoFret;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final playableChords = ChordTransposer.transposeProgression(
      song.originalChords,
      -capoFret,
    );

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.pushNamed('song', extra: song),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                song.title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                song.artist,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: playableChords
                    .map((chord) => Chip(label: Text(chord)))
                    .toList(growable: false),
              ),
              const SizedBox(height: 12),
              Text(
                '${l10n.difficultyLabel}: ${song.difficulty}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                '${l10n.strummingPatternLabel}: ${song.strummingPattern}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
