import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/chord_transposer.dart';
import '../models/song.dart';
import 'difficulty_badge.dart';

class EnhancedSongCard extends StatelessWidget {
  const EnhancedSongCard({
    super.key,
    required this.song,
    required this.capoFret,
    required this.onTap,
  });

  final Song song;
  final int capoFret;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final playableChords = ChordTransposer.transposeProgression(
      song.originalChords,
      song.capo - capoFret,
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          song.title,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textOnLight,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          song.artist,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.textOnLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (song.isFavorite)
                    Icon(
                      Icons.favorite,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: playableChords
                    .map(
                      (chord) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          chord,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.surfaceLight,
                          ),
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  DifficultyBadge(difficulty: song.difficulty),
                  const SizedBox(width: 8),
                  if (song.bpm != null) ...[
                    const Icon(
                      Icons.speed,
                      size: 14,
                      color: AppColors.textOnLight,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${song.bpm} BPM',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textOnLight,
                        ),
                      ),
                    ),
                  ],
                  if (song.bpm == null) const Spacer(),
                  const Icon(Icons.chevron_right, color: AppColors.textOnLight),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
