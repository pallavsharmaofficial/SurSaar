import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sursaar/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../data/content/chord_sheet_parser.dart';
import '../../repositories/song_repository.dart';
import '../../widgets/app_back_button.dart';
import '../../widgets/chord_sheet.dart';

/// Paste a chord sheet from anywhere and turn it into a practisable song.
class ImportSongScreen extends StatefulWidget {
  const ImportSongScreen({super.key, this.initialQuery = ''});

  final String initialQuery;

  @override
  State<ImportSongScreen> createState() => _ImportSongScreenState();
}

class _ImportSongScreenState extends State<ImportSongScreen> {
  late final TextEditingController _title = TextEditingController(
    text: widget.initialQuery,
  );
  final TextEditingController _artist = TextEditingController();
  final TextEditingController _sheet = TextEditingController();
  ParsedSheet? _parsed;
  bool _keepLyrics = true;
  bool _saving = false;

  void _parse(String text) {
    setState(
      () => _parsed = text.trim().isEmpty ? null : ChordSheetParser.parse(text),
    );
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text == null || text.isEmpty) return;
    _sheet.text = text;
    _parse(text);
  }

  Future<void> _searchOnline() async {
    await launchUrl(
      Uri.parse(AppConstants.webSearchUrl(_title.text)),
      mode: LaunchMode.externalApplication,
    );
  }

  Future<void> _save() async {
    final parsed = _parsed;
    if (parsed == null || parsed.isEmpty) return;
    setState(() => _saving = true);
    final l10n = AppLocalizations.of(context)!;
    final repository = context.read<SongRepository>();
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final song = parsed.toSong(
      id: ChordSheetParser.idFor(
        _title.text,
        _artist.text,
        await repository.knownIds(),
      ),
      title: _title.text,
      artist: _artist.text,
      keepLyrics: _keepLyrics,
    );
    final saved = await repository.addUserSong(song);
    if (!mounted) return;
    setState(() => _saving = false);
    messenger.showSnackBar(SnackBar(content: Text(l10n.songAdded)));
    router.pushReplacement('/song/${saved.id}', extra: saved);
  }

  @override
  void dispose() {
    _title.dispose();
    _artist.dispose();
    _sheet.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final parsed = _parsed;
    final ready =
        parsed != null && !parsed.isEmpty && _title.text.trim().isNotEmpty;
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        leading: const AppBackButton(),
        backgroundColor: AppColors.backgroundDark,
        title: Text(l10n.addSong),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: <Widget>[
              Text(
                l10n.addSongSubtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textOnDark.withValues(alpha: 0.75),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  OutlinedButton.icon(
                    onPressed: _searchOnline,
                    icon: const Icon(Icons.travel_explore_rounded),
                    label: Text(l10n.findChordsOnline),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white30),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _paste,
                    icon: const Icon(Icons.content_paste_rounded),
                    label: Text(l10n.pasteSheet),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white30),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _Field(
                controller: _title,
                label: l10n.songTitleLabel,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              _Field(controller: _artist, label: l10n.artistLabel),
              const SizedBox(height: 12),
              TextField(
                controller: _sheet,
                onChanged: _parse,
                minLines: 6,
                maxLines: 14,
                style: const TextStyle(
                  color: AppColors.textOnLight,
                  fontFamily: 'monospace',
                ),
                decoration: InputDecoration(
                  hintText: l10n.pasteSheetHint,
                  filled: true,
                  fillColor: AppColors.surfaceLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (parsed == null || parsed.isEmpty)
                Text(
                  l10n.noChordsFound,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textOnDark.withValues(alpha: 0.6),
                  ),
                )
              else
                _Preview(parsed: parsed).animate().fadeIn(duration: 250.ms),
              const SizedBox(height: 12),
              SwitchListTile(
                value: _keepLyrics,
                onChanged: (v) => setState(() => _keepLyrics = v),
                title: Text(
                  l10n.keepLyrics,
                  style: const TextStyle(color: AppColors.textOnDark),
                ),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: ready && !_saving ? _save : null,
                icon: const Icon(Icons.library_add_rounded),
                label: Text(l10n.saveToMySongs),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.controller, required this.label, this.onChanged});

  final TextEditingController controller;
  final String label;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: const TextStyle(color: AppColors.textOnLight),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textOnLight),
        filled: true,
        fillColor: AppColors.surfaceLight,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({required this.parsed});

  final ParsedSheet parsed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            l10n.chordsFound,
            style: theme.textTheme.titleSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: <Widget>[
              for (var i = 0; i < parsed.chords.length; i++)
                ActionChip(
                  label: Text(
                    parsed.chords[i],
                    style: const TextStyle(
                      color: AppColors.textOnLight,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () => ChordSheet.show(context, parsed.chords[i]),
                ).animate().scale(
                  delay: (40 * i).ms,
                  curve: Curves.easeOutBack,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${l10n.sectionsFound}: '
            '${parsed.sections.map((s) => '${s.name} (${s.lines.length})').join(', ')}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textOnDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            <String>[
              if (parsed.key != null) '${l10n.keyLabel} ${parsed.key}',
              if (parsed.capo > 0) l10n.capoLabel(parsed.capo),
              if (parsed.strumming != null) parsed.strumming!,
              if (parsed.bpm != null) '${parsed.bpm} BPM',
            ].join(' · '),
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.successGold,
            ),
          ),
        ],
      ),
    );
  }
}
