import 'package:flutter/material.dart';
import 'package:sursaar/l10n/app_localizations.dart';

import '../../core/theme/app_colors.dart';
import '../../models/song.dart';
import '../../tutor/tutor_brain.dart';
import '../difficulty_badge.dart';

const Color tutorSurface = Color(0xFF1E293B);
const Color tutorGreen = Color(0xFF22C55E);

/// Look and label of each library shelf.
class CollectionStyle {
  const CollectionStyle(this.emoji, this.colors);

  final String emoji;
  final List<Color> colors;

  static CollectionStyle of(SongCollection? collection) => switch (collection) {
    SongCollection.bollywood => const CollectionStyle('🎬', <Color>[
      Color(0xFFDB2777),
      Color(0xFFF97316),
    ]),
    SongCollection.global => const CollectionStyle('🌍', <Color>[
      Color(0xFF2563EB),
      Color(0xFF06B6D4),
    ]),
    SongCollection.band => const CollectionStyle('🎸', <Color>[
      Color(0xFF7C3AED),
      Color(0xFFDB2777),
    ]),
    SongCollection.instrumental => const CollectionStyle('🪕', <Color>[
      Color(0xFFD97706),
      Color(0xFF65A30D),
    ]),
    null => const CollectionStyle('🎵', <Color>[
      AppColors.primary,
      Color(0xFF7C3AED),
    ]),
  };

  static String label(AppLocalizations l10n, SongCollection? collection) =>
      switch (collection) {
        SongCollection.bollywood => l10n.shelfBollywood,
        SongCollection.global => l10n.shelfGlobal,
        SongCollection.band => l10n.shelfBand,
        SongCollection.instrumental => l10n.shelfInstrumental,
        null => l10n.shelfAll,
      };
}

/// A thin bar: how many of the song's chords the player already knows.
class ReadinessMeter extends StatelessWidget {
  const ReadinessMeter({super.key, required this.value, this.width = 64});

  final double value;
  final double width;

  @override
  Widget build(BuildContext context) {
    final color = value >= 0.99
        ? tutorGreen
        : value >= 0.6
        ? AppColors.successGold
        : AppColors.secondary;
    return SizedBox(
      width: width,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: value.clamp(0.0, 1.0),
          minHeight: 6,
          backgroundColor: Colors.white12,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ),
    );
  }
}

/// Small chord chips: known chords muted, new ones highlighted.
class ChordPills extends StatelessWidget {
  const ChordPills({
    super.key,
    required this.known,
    required this.fresh,
    this.max = 6,
  });

  final List<String> known;
  final List<String> fresh;
  final int max;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = <(String, bool)>[
      for (final c in fresh) (c, true),
      for (final c in known) (c, false),
    ];
    final shown = items.take(max).toList();
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: <Widget>[
        for (final (chord, isNew) in shown)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: isNew
                  ? AppColors.successGold.withValues(alpha: 0.18)
                  : Colors.white10,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isNew ? AppColors.successGold : Colors.white24,
                width: 0.8,
              ),
            ),
            child: Text(
              isNew ? '$chord ✦' : chord,
              style: theme.textTheme.labelSmall?.copyWith(
                color: isNew ? AppColors.successGold : Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        if (items.length > shown.length)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Text(
              '+${items.length - shown.length}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.white54,
              ),
            ),
          ),
      ],
    );
  }
}

/// One song in the tutor's library, with how ready the player is for it.
class TutorSongTile extends StatelessWidget {
  const TutorSongTile({super.key, required this.pick, required this.onTap});

  final TutorPick pick;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final song = pick.song;
    final style = CollectionStyle.of(song.collection);
    final journey = pick.journey;
    return Material(
      color: tutorSurface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: style.colors),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(style.emoji, style: const TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      song.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      <String>[
                        song.artist,
                        if (song.year != null) '${song.year}',
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white60,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (song.hasMelody)
                      Text(
                        '🎼 ${l10n.singleNoteTab}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.successGold,
                        ),
                      )
                    else
                      ChordPills(
                        known: pick.knownChords,
                        fresh: pick.newChords,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  DifficultyBadge(difficulty: song.difficulty),
                  const SizedBox(height: 8),
                  if (journey != null)
                    Text(
                      journey.completed
                          ? '★' * journey.stars.clamp(1, 3)
                          : '${journey.passedCount}/${journey.stages.length}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: journey.completed
                            ? AppColors.successGold
                            : tutorGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  else if (!song.hasMelody)
                    ReadinessMeter(value: pick.readiness, width: 54),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
