import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;

import '../data/content/content_normalizer.dart';
import '../data/local/local_store.dart';
import '../models/content_bundle.dart';

/// Loads lessons, courses, songs and chord voicings.
///
/// Strategy (works identically on web and mobile):
///  1. the bundled asset is always loaded first – the app is never empty;
///  2. the remote JSON on GitHub is fetched with a timeout and merged on top;
///  3. on failure the last successfully fetched remote JSON (cached in the
///     [LocalStore]) is merged instead.
///
/// Both the app's own v2 layout and the older "content engine" layout are
/// accepted; see [ContentNormalizer].
class ContentRepository {
  ContentRepository({
    required LocalStore store,
    http.Client? client,
    String? contentUrl,
  }) : _store = store,
       _client = client ?? http.Client(),
       contentUrl = contentUrl ?? defaultContentUrl;

  /// Override at build time with
  /// `--dart-define=SURSAAR_CONTENT_URL=https://.../sursaar_content.json`.
  static const String defaultContentUrl = String.fromEnvironment(
    'SURSAAR_CONTENT_URL',
    defaultValue:
        'https://raw.githubusercontent.com/pallavsharmaofficial/SurSaar/main/content/sursaar_content.json',
  );

  static const String assetPath = 'assets/data/local_bundle.json';
  static const String _cacheKey = 'content_cache_v2';
  static const Duration _timeout = Duration(seconds: 12);

  final LocalStore _store;
  final http.Client _client;
  final String contentUrl;

  /// The latest merged bundle; listen to it to react to refreshes.
  final ValueNotifier<ContentBundle?> bundle = ValueNotifier<ContentBundle?>(
    null,
  );

  /// Where the last load came from ("remote", "cache" or "bundle").
  String lastSource = 'none';

  Future<ContentBundle>? _inFlight;

  /// Returns the current bundle, loading it once if needed.
  Future<ContentBundle> ensureLoaded() {
    final current = bundle.value;
    if (current != null) return Future<ContentBundle>.value(current);
    return fetchContent();
  }

  /// Loads asset + (remote | cache) and publishes the merged result.
  Future<ContentBundle> fetchContent() {
    return _inFlight ??= _load().whenComplete(() => _inFlight = null);
  }

  /// Forces a remote fetch (used by pull-to-refresh).
  Future<ContentBundle> refresh() => _load();

  Future<ContentBundle> _load() async {
    final base = await _loadLocalBundle();
    ContentBundle result = base;
    try {
      final remote = await _fetchFromInternet();
      result = base.merge(remote);
      lastSource = 'remote';
    } catch (_) {
      final cached = await _loadFromCache();
      if (cached != null) {
        result = base.merge(cached);
        lastSource = 'cache';
      } else {
        lastSource = 'bundle';
      }
    }
    bundle.value = result;
    return result;
  }

  Future<ContentBundle> _fetchFromInternet() async {
    final response = await _client
        .get(
          Uri.parse(contentUrl),
          headers: const <String, String>{'Accept': 'application/json'},
        )
        .timeout(_timeout);
    if (response.statusCode != 200) {
      throw Exception('Failed to load content: ${response.statusCode}');
    }
    final parsed = parseBundle(response.body);
    await _store.setString(_cacheKey, response.body);
    return parsed;
  }

  Future<ContentBundle?> _loadFromCache() async {
    try {
      final raw = await _store.getString(_cacheKey);
      if (raw == null || raw.isEmpty) return null;
      return parseBundle(raw);
    } catch (_) {
      return null;
    }
  }

  Future<ContentBundle> _loadLocalBundle() async {
    final raw = await rootBundle.loadString(assetPath);
    return parseBundle(raw);
  }

  /// Parses any supported JSON layout into a [ContentBundle].
  static ContentBundle parseBundle(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Content root must be a JSON object');
    }
    return ContentBundle.fromJson(ContentNormalizer.normalize(decoded));
  }

  Future<void> clearCache() => _store.remove(_cacheKey);

  Future<bool> isConnected() async {
    try {
      final result = await _client
          .head(Uri.parse(contentUrl))
          .timeout(const Duration(seconds: 5));
      return result.statusCode < 500;
    } catch (_) {
      return false;
    }
  }

  void dispose() {
    bundle.dispose();
    _client.close();
  }
}
