import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../models/content_bundle.dart';

class ContentRepository {
  ContentRepository();

  // GitHub raw content URL
  static const String _contentUrl =
      'https://raw.githubusercontent.com/thepallavsharma/SurSaarContent/main/sursaar_content.json';

  static const String _cacheFileName = 'content_cache.json';

  // Get cached content file path
  Future<File> _getCacheFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_cacheFileName');
  }

  /// Fetch content from internet, with cache and local fallback
  Future<ContentBundle> fetchContent() async {
    try {
      // Try to fetch from internet
      return await _fetchFromInternet();
    } catch (e) {
      // Fall back to cache
      try {
        return await _loadFromCache();
      } catch (cacheError) {
        // Fall back to local bundle
        return await _loadLocalBundle();
      }
    }
  }

  /// Fetch from GitHub
  Future<ContentBundle> _fetchFromInternet() async {
    try {
      final response = await http.get(
        Uri.parse(_contentUrl),
        headers: const {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final bundle = ContentBundle.fromJson(json);

        // Cache the content
        await _saveToCache(response.body);

        return bundle;
      } else {
        throw Exception('Failed to load content: ${response.statusCode}');
      }
    } on SocketException catch (e) {
      throw Exception('No internet connection: $e');
    } on TimeoutException catch (e) {
      throw Exception('Request timeout: $e');
    } catch (e) {
      throw Exception('Failed to fetch content: $e');
    }
  }

  /// Save content to local cache
  Future<void> _saveToCache(String jsonString) async {
    try {
      final file = await _getCacheFile();
      await file.writeAsString(jsonString);
    } catch (e) {
      // Silently fail - caching is optional
    }
  }

  /// Load content from local cache
  Future<ContentBundle> _loadFromCache() async {
    final file = await _getCacheFile();
    if (!await file.exists()) {
      throw Exception('Cache file does not exist');
    }
    final jsonString = await file.readAsString();
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return ContentBundle.fromJson(json);
  }

  /// Load content from local bundle (packaged with app)
  Future<ContentBundle> _loadLocalBundle() async {
    final jsonString =
        await rootBundle.loadString('assets/data/local_bundle.json');
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return ContentBundle.fromJson(json);
  }

  /// Clear the cache
  Future<void> clearCache() async {
    try {
      final file = await _getCacheFile();
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      // Silently fail
    }
  }

  /// Check if internet is available (optional utility)
  Future<bool> isConnected() async {
    try {
      final result = await http
          .head(Uri.parse('https://www.google.com'))
          .timeout(const Duration(seconds: 5));
      return result.statusCode < 500;
    } catch (_) {
      return false;
    }
  }
}
