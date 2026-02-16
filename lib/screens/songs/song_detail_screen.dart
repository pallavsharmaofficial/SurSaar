import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:sursaar/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/chord_transposer.dart';
import '../../models/song.dart';
import '../../repositories/song_repository.dart';
import '../../widgets/difficulty_badge.dart';
import '../../widgets/section_header.dart';

class SongDetailScreen extends StatefulWidget {
  const SongDetailScreen({
    super.key,
    required this.song,
  });

  final Song song;

  @override
  State<SongDetailScreen> createState() => _SongDetailScreenState();
}

class _SongDetailScreenState extends State<SongDetailScreen> {
  late bool _isFavorite;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.song.isFavorite;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final transposedChords = ChordTransposer.transposeProgression(
      widget.song.originalChords,
      0,
    );

    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar.large(
            title: Text(widget.song.title),
            actions: <Widget>[
              IconButton(
                icon: Icon(
                  _isFavorite ? Icons.favorite : Icons.favorite_border,
                ),
                onPressed: _toggleFavorite,
              ),
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () {
                  // TODO: Share song
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
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              widget.song.artist,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textOnLight,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: <Widget>[
                                DifficultyBadge(
                                  difficulty: widget.song.difficulty,
                                ),
                                if (widget.song.practiceCount > 0) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceLight,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: <Widget>[
                                        const Icon(
                                          Icons.music_note,
                                          size: 14,
                                          color: AppColors.textOnLight,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${widget.song.practiceCount}x',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: AppColors.textOnLight,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                      .animate()
                      .fadeIn(duration: 400.ms)
                      .slideX(begin: -0.1, end: 0),
                  const SizedBox(height: 24),
                  SectionHeader(title: l10n.chords),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: transposedChords
                        .map(
                          (chord) => Chip(
                            label: Text(
                              chord,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                        )
                        .toList(growable: false),
                  )
                      .animate()
                      .fadeIn(delay: 100.ms, duration: 400.ms)
                      .slideY(begin: 0.1, end: 0),
                  const SizedBox(height: 24),
                    _InfoCard(
                    icon: Icons.queue_music,
                    title: l10n.strummingPatternLabel,
                      value: widget.song.strummingPattern,
                  )
                      .animate()
                      .fadeIn(delay: 200.ms, duration: 400.ms)
                      .slideX(begin: 0.1, end: 0),
                  const SizedBox(height: 12),
                  if (widget.song.bpm != null)
                    _InfoCard(
                      icon: Icons.speed,
                      title: l10n.tempo,
                      value: '${widget.song.bpm} BPM',
                    )
                        .animate()
                        .fadeIn(delay: 250.ms, duration: 400.ms)
                        .slideX(begin: 0.1, end: 0),
                  if (widget.song.duration != null) ...[
                    const SizedBox(height: 12),
                    _InfoCard(
                      icon: Icons.timer,
                      title: l10n.duration,
                      value: _formatDuration(widget.song.duration!),
                    )
                        .animate()
                        .fadeIn(delay: 300.ms, duration: 400.ms)
                        .slideX(begin: 0.1, end: 0),
                  ],
                  const SizedBox(height: 32),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: FilledButton.icon(
                            onPressed: () =>
                              _launchTutorial(widget.song.tutorialUrl),
                          icon: const Icon(Icons.play_circle_fill),
                          label: Text(l10n.openTutorialButton),
                        ),
                      ),
                    ],
                  )
                      .animate()
                      .fadeIn(delay: 400.ms, duration: 400.ms)
                      .scale(begin: const Offset(0.9, 0.9)),
                  const SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: FilledButton.tonalIcon(
                          onPressed: () {
                            context.pushNamed(
                              'practice',
                              pathParameters: {'songId': widget.song.id},
                            );
                          },
                          icon: const Icon(Icons.mic),
                          label: Text(l10n.startPractice),
                        ),
                      ),
                    ],
                  )
                      .animate()
                      .fadeIn(delay: 450.ms, duration: 400.ms)
                      .scale(begin: const Offset(0.9, 0.9)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }

  Future<void> _launchTutorial(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  Future<void> _toggleFavorite() async {
    setState(() {
      _isFavorite = !_isFavorite;
    });
    await context.read<SongRepository>().toggleFavorite(
          widget.song.id,
          _isFavorite,
        );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            icon,
            color: AppColors.primary,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textOnLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
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
