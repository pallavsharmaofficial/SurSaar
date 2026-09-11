import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sursaar/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../models/song.dart';
import '../../repositories/song_repository.dart';
import '../../widgets/enhanced_song_card.dart';

class SongSearchScreen extends StatefulWidget {
  const SongSearchScreen({super.key, this.initialQuery = ''});

  final String initialQuery;

  @override
  State<SongSearchScreen> createState() => _SongSearchScreenState();
}

class _SongSearchScreenState extends State<SongSearchScreen> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialQuery,
  );
  List<Song> _results = const <Song>[];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _search(widget.initialQuery);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    setState(() => _loading = true);
    final results = await context.read<SongRepository>().searchSongs(query);
    if (!mounted) return;
    setState(() {
      _results = results;
      _loading = false;
    });
  }

  Future<void> _requestSong() async {
    final query = _controller.text.trim();
    final uri = Uri.parse(AppConstants.songRequestUrl).replace(
      queryParameters: <String, String>{
        'labels': 'song-request',
        'template': 'song_request.yml',
        'title': 'Song request: ${query.isEmpty ? '<song title>' : query}',
        'song': query,
      },
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: widget.initialQuery.isEmpty,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: l10n.searchHint,
            border: InputBorder.none,
            suffixIcon: _controller.text.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _controller.clear();
                      _search('');
                    },
                  ),
          ),
          onChanged: _search,
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _results.isEmpty
          ? _EmptyResults(query: _controller.text, onRequest: _requestSong)
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _results.length + 1,
              itemBuilder: (context, index) {
                if (index == _results.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: TextButton.icon(
                      onPressed: _requestSong,
                      icon: const Icon(Icons.add_circle_outline),
                      label: Text(l10n.requestSong),
                    ),
                  );
                }
                final song = _results[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child:
                      EnhancedSongCard(
                            song: song,
                            capoFret: song.capo,
                            onTap: () => context.pushNamed(
                              'songDetail',
                              pathParameters: <String, String>{'id': song.id},
                              extra: song,
                            ),
                          )
                          .animate(delay: Duration(milliseconds: 40 * index))
                          .fadeIn(duration: 300.ms),
                );
              },
            ),
      backgroundColor: theme.scaffoldBackgroundColor,
    );
  }
}

class _EmptyResults extends StatelessWidget {
  const _EmptyResults({required this.query, required this.onRequest});

  final String query;
  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(
              Icons.search_off,
              size: 72,
              color: AppColors.surfaceLight,
            ),
            const SizedBox(height: 16),
            Text(
              '${l10n.noResultsFor} "$query"',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.requestSongHint,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRequest,
              icon: const Icon(Icons.cloud_download_outlined),
              label: Text(l10n.requestSong),
            ),
          ],
        ),
      ),
    );
  }
}
