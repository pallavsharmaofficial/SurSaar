import 'package:flutter/material.dart';
import 'package:sursaar/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/utils/chord_transposer.dart';
import '../models/song.dart';

class SongDetailScreen extends StatelessWidget {
  const SongDetailScreen({
    super.key,
    required this.song,
  });

  final Song song;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final transposedChords = ChordTransposer.transposeProgression(
      song.originalChords,
      0,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(song.title),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text(
            song.artist,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: transposedChords
                .map(
                  (chord) => Chip(
                    label: Text(chord),
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 16),
          _DetailRow(label: l10n.difficultyLabel, value: song.difficulty),
          _DetailRow(
            label: l10n.strummingPatternLabel,
            value: song.strummingPattern,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => _launchTutorial(song.tutorialUrl),
            icon: const Icon(Icons.play_circle_fill),
            label: Text(l10n.openTutorialButton),
          ),
        ],
      ),
    );
  }

  Future<void> _launchTutorial(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: <Widget>[
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
