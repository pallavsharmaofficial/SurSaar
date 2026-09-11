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
import '../../widgets/app_back_button.dart';
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
  bool _refreshing = false;

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

  /// Pulls the published catalogue again, so songs added since the app was
  /// opened show up.
  Future<void> _refreshCatalogue() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _refreshing = true);
    await context.read<SongRepository>().refreshCatalogue();
    await _search(_controller.text);
    if (!mounted) return;
    setState(() => _refreshing = false);
    messenger.showSnackBar(SnackBar(content: Text(l10n.songsUpdated)));
  }

  Future<void> _findOnline() async {
    await launchUrl(
      Uri.parse(AppConstants.webSearchUrl(_controller.text)),
      mode: LaunchMode.externalApplication,
    );
  }

  void _pasteSheet() {
    context.push(
      '/import?q=${Uri.encodeQueryComponent(_controller.text.trim())}',
    );
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
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: const AppBackButton(),
        title: TextField(
          controller: _controller,
          autofocus: widget.initialQuery.isEmpty,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: l10n.searchHint,
            border: InputBorder.none,
          ),
          onChanged: _search,
        ),
        actions: <Widget>[
          IconButton(
            tooltip: l10n.refreshSongs,
            onPressed: _refreshing ? null : _refreshCatalogue,
            icon: _refreshing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: l10n.addSong,
            onPressed: _pasteSheet,
            icon: const Icon(Icons.library_add_rounded),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _results.isEmpty
          ? _EmptyResults(
              query: _controller.text,
              onFindOnline: _findOnline,
              onPaste: _pasteSheet,
              onRequest: _requestSong,
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _results.length + 1,
              itemBuilder: (context, index) {
                if (index == _results.length) {
                  return _MoreWays(
                    onFindOnline: _findOnline,
                    onPaste: _pasteSheet,
                    onRequest: _requestSong,
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
    );
  }
}

class _MoreWays extends StatelessWidget {
  const _MoreWays({
    required this.onFindOnline,
    required this.onPaste,
    required this.onRequest,
  });

  final VoidCallback onFindOnline;
  final VoidCallback onPaste;
  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: <Widget>[
          TextButton.icon(
            onPressed: onFindOnline,
            icon: const Icon(Icons.travel_explore_rounded),
            label: Text(l10n.findChordsOnline),
          ),
          TextButton.icon(
            onPressed: onPaste,
            icon: const Icon(Icons.content_paste_rounded),
            label: Text(l10n.pasteSheet),
          ),
          TextButton.icon(
            onPressed: onRequest,
            icon: const Icon(Icons.add_circle_outline),
            label: Text(l10n.requestSong),
          ),
        ],
      ),
    );
  }
}

class _EmptyResults extends StatelessWidget {
  const _EmptyResults({
    required this.query,
    required this.onFindOnline,
    required this.onPaste,
    required this.onRequest,
  });

  final String query;
  final VoidCallback onFindOnline;
  final VoidCallback onPaste;
  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
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
              l10n.searchOnlineHint,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                FilledButton.icon(
                  onPressed: onFindOnline,
                  icon: const Icon(Icons.travel_explore_rounded),
                  label: Text(l10n.findChordsOnline),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: onPaste,
                  icon: const Icon(Icons.content_paste_rounded),
                  label: Text(l10n.pasteSheet),
                ),
                TextButton.icon(
                  onPressed: onRequest,
                  icon: const Icon(Icons.cloud_download_outlined),
                  label: Text(l10n.requestSong),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
