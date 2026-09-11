import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sursaar/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/chord_transposer.dart';
import '../../data/content/chord_library.dart';
import '../../models/song.dart';
import '../../repositories/song_repository.dart';
import '../../widgets/difficulty_badge.dart';
import '../../widgets/section_header.dart';
import '../../widgets/teacher/chord_diagram.dart';
import '../../widgets/teacher/strumming_timeline.dart';

class SongDetailScreen extends StatefulWidget {
  const SongDetailScreen({super.key, required this.songId, this.initialSong});

  final String songId;
  final Song? initialSong;

  @override
  State<SongDetailScreen> createState() => _SongDetailScreenState();
}

class _SongDetailScreenState extends State<SongDetailScreen> {
  Song? _song;
  bool _loading = true;
  late int _capo;

  @override
  void initState() {
    super.initState();
    _song = widget.initialSong;
    _capo = widget.initialSong?.capo ?? 0;
    _load();
  }

  Future<void> _load() async {
    final song = await context.read<SongRepository>().getSongById(
      widget.songId,
    );
    if (!mounted) return;
    setState(() {
      _song = song ?? _song;
      _capo = _song?.capo ?? 0;
      _loading = false;
    });
  }

  Future<void> _toggleFavorite() async {
    final song = _song;
    if (song == null) return;
    setState(() => _song = song.copyWith(isFavorite: !song.isFavorite));
    await context.read<SongRepository>().toggleFavorite(
      song.id,
      !song.isFavorite,
    );
  }

  Future<void> _launch(String url) async {
    if (url.isEmpty) return;
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final song = _song;
    if (song == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: _loading
              ? const CircularProgressIndicator()
              : Text(l10n.noSongsFound),
        ),
      );
    }
    final library = context.read<ChordLibrary>();
    final playable = ChordTransposer.transposeProgression(
      song.uniqueChords,
      song.capo - _capo,
    );

    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar.large(
            title: Text(song.title),
            actions: <Widget>[
              IconButton(
                icon: Icon(
                  song.isFavorite ? Icons.favorite : Icons.favorite_border,
                ),
                onPressed: _toggleFavorite,
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
                    song.artist,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textOnDark,
                    ),
                  ),
                  if (song.album != null)
                    Text(
                      song.album!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textOnDark.withValues(alpha: 0.7),
                      ),
                    ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: <Widget>[
                      DifficultyBadge(difficulty: song.difficulty),
                      if (song.key != null)
                        _Pill(
                          icon: Icons.music_note,
                          text: '${l10n.keyLabel} ${song.key}',
                        ),
                      if (song.bpm != null)
                        _Pill(icon: Icons.speed, text: '${song.bpm} BPM'),
                      if (song.duration != null)
                        _Pill(
                          icon: Icons.timer,
                          text: _formatDuration(song.duration!),
                        ),
                      ...song.tags.take(3).map((t) => _Pill(text: '#$t')),
                    ],
                  ).animate().fadeIn(duration: 400.ms),
                  const SizedBox(height: 20),
                  // teacher CTA
                  FilledButton.icon(
                        onPressed: () => context.pushNamed(
                          'practiceSong',
                          pathParameters: <String, String>{'id': song.id},
                        ),
                        icon: const Icon(Icons.auto_awesome),
                        label: Text(l10n.practiceWithTeacher),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.surfaceLight,
                          minimumSize: const Size.fromHeight(48),
                        ),
                      )
                      .animate()
                      .fadeIn(delay: 100.ms, duration: 400.ms)
                      .scale(begin: const Offset(0.95, 0.95)),
                  const SizedBox(height: 24),
                  // capo + chords
                  Row(
                    children: <Widget>[
                      Expanded(child: SectionHeader(title: l10n.chords)),
                      Text(
                        l10n.capoLabel(_capo),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textOnDark,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _capo.toDouble(),
                    min: 0,
                    max: 7,
                    divisions: 7,
                    label: '$_capo',
                    onChanged: (v) => setState(() => _capo = v.round()),
                  ),
                  SizedBox(
                    height: 190,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: playable.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final voicing = library.voicingFor(playable[index]);
                        if (voicing == null) {
                          return Chip(label: Text(playable[index]));
                        }
                        return Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceLight,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: ChordDiagram(
                                voicing: voicing,
                                size: 100,
                                color: AppColors.textOnLight,
                              ),
                            )
                            .animate(delay: Duration(milliseconds: 60 * index))
                            .fadeIn();
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  SectionHeader(
                    title: l10n.strummingPatternLabel,
                    trailing: Text(
                      song.strummingPattern,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  StrummingTimeline(pattern: song.strumming),
                  if (song.sections.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 24),
                    SectionHeader(title: l10n.sections),
                    const SizedBox(height: 12),
                    ...song.sections.map(
                      (section) => Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                Text(
                                  section.name,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textOnLight,
                                  ),
                                ),
                                if (section.repeat > 1) ...<Widget>[
                                  const SizedBox(width: 8),
                                  Text(
                                    '×${section.repeat}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: AppColors.textOnLight.withValues(
                                        alpha: 0.7,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 8),
                            ...section.lines.map((line) {
                              final chords =
                                  ChordTransposer.transposeProgression(
                                    line.chords
                                        .map((c) => c.chord)
                                        .toList(growable: false),
                                    song.capo - _capo,
                                  );
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 4,
                                      children: chords
                                          .map(
                                            (c) => Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 3,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: AppColors.primary,
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                c,
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                              ),
                                            ),
                                          )
                                          .toList(growable: false),
                                    ),
                                    if (line.lyric.isNotEmpty)
                                      Text(
                                        line.lyric,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              color: AppColors.textOnLight,
                                            ),
                                      ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                  ],
                  if (song.notes != null) ...<Widget>[
                    const SizedBox(height: 8),
                    Text(
                      song.notes!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textOnDark.withValues(alpha: 0.7),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  if (song.tutorialUrl.isNotEmpty)
                    FilledButton.tonalIcon(
                      onPressed: () => _launch(song.tutorialUrl),
                      icon: const Icon(Icons.play_circle_fill),
                      label: Text(l10n.openTutorialButton),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                    ),
                  if (song.sourceUrl != null)
                    TextButton.icon(
                      onPressed: () => _launch(song.sourceUrl!),
                      icon: const Icon(Icons.link, size: 16),
                      label: Text(l10n.source),
                    ),
                  const SizedBox(height: 24),
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
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, this.icon});

  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 14, color: AppColors.textOnLight),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textOnLight,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
