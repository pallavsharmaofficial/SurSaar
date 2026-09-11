# ContentRepository Quick Reference

## How It Works

### Automatic Content Fetching
When the app starts, it automatically fetches lesson and song data:

```dart
// In App widget (lib/core/app.dart)
LessonBloc(...)..add(const FetchContentEvent())
```

### Three-Level Fallback Strategy

1. **GitHub (Primary)** → Fast, always latest
   - URL: `https://raw.githubusercontent.com/thepallavsharma/SurSaarContent/main/sursaar_content.json`
   - Cached locally on success

2. **Local Cache** → Previous fetch
   - File: `Documents/content_cache.json`
   - Expires when app is uninstalled

3. **Bundle Asset** → Always available
   - File: `assets/data/local_bundle.json`
   - Packaged with app

## Usage Examples

### Fetch Content
```dart
final repository = ContentRepository();
final bundle = await repository.fetchContent();

// Access lessons and songs
final lessons = bundle.lessons;
final songs = bundle.songs;
```

### Check Connection
```dart
final isOnline = await contentRepository.isConnected();
```

### Clear Cache
```dart
await contentRepository.clearCache();
```

## Integration Points

### In BLoCs
```dart
class LessonBloc extends Bloc<LessonEvent, LessonState> {
  LessonBloc({
    required ContentRepository contentRepository,
  }) {
    on<FetchContentEvent>(_onFetchContent);
  }
  
  Future<void> _onFetchContent(
    FetchContentEvent event,
    Emitter<LessonState> emit,
  ) async {
    final bundle = await _contentRepository.fetchContent();
    // Update UI with bundle.lessons
  }
}
```

### In Screens
```dart
// Trigger fetch via BLoC
context.read<LessonBloc>().add(const FetchContentEvent());

// Or fetch directly if needed
final repo = context.read<ContentRepository>();
final bundle = await repo.fetchContent();
```

## Data Models

### ContentBundle
```dart
ContentBundle {
  List<Lesson> lessons;    // Music lessons
  List<Song> songs;        // Practice songs
  String version;          // Content version
  String? lastUpdated;     // Timestamp
}
```

### Lesson
```dart
Lesson {
  String id;
  String title;
  String description;
  LessonDifficulty difficulty;
  int duration;            // minutes
  List<LessonStep> steps;  // Structured lessons
}
```

### Song
```dart
Song {
  String id;
  String title;
  String artist;
  List<String> originalChords;
  int bpm;
  int duration;            // seconds
  String lyrics;
}
```

## Network Resilience

### Timeout Handling
- **Internet Fetch:** 15 seconds timeout
- **Automatic Fallback:** No user intervention needed
- **Graceful Degradation:** Always serves content

### Offline Support
- ✅ App launches offline
- ✅ Previous session cached
- ✅ Local bundle available
- ✅ No error crashes

## Performance

| Operation | Time | Source |
|-----------|------|--------|
| First load (online) | ~2-3s | GitHub + cache |
| Cached load | <100ms | Local file |
| Bundle load | <50ms | Asset |
| App launch | Auto | FetchContentEvent |

## Debugging

### Enable Logging (for development)
```dart
// Add to ContentRepository._fetchFromInternet()
print('Fetching from: $_contentUrl');
print('Response: ${response.statusCode}');
```

### Check Cache Status
```dart
// List cached files
final dir = await getApplicationDocumentsDirectory();
final cacheFile = File('${dir.path}/content_cache.json');
print('Cache exists: ${await cacheFile.exists()}');
```

### Verify Bundle
```dart
final bundleJson = await rootBundle.loadString('assets/data/local_bundle.json');
print('Bundle size: ${bundleJson.length} bytes');
```

## Testing Scenarios

### 1. Online - Fresh Start
- Delete app, install fresh
- Launch with internet
- Should fetch from GitHub and cache

### 2. Offline - Cached Content
- Launch with internet once
- Enable Airplane Mode
- Launch again
- Should load from cache

### 3. No Cache - Fallback
- Clear app cache/data
- Enable Airplane Mode
- Launch
- Should load from bundled asset

### 4. Network Failure
- Enable Airplane Mode from start
- Launch
- Should load bundle instantly

## Configuration

### Change GitHub URL
```dart
// In ContentRepository class
static const String _contentUrl = 'your-new-url';
```

### Adjust Timeout
```dart
// In _fetchFromInternet()
.timeout(const Duration(seconds: 30)); // Change from 15
```

### Clear Cache on Launch
```dart
// In App.build()
await contentRepository.clearCache();
```

## Security Notes
- ✅ HTTPS GitHub URL (secure)
- ✅ JSON parsing with type safety
- ✅ No sensitive data cached
- ✅ Proper exception handling
- ✅ No debug prints in production

## Future Improvements
- [ ] Differential updates (only changed content)
- [ ] Database persistence
- [ ] Compression for cache files
- [ ] Content versioning
- [ ] Sync scheduling
- [ ] Analytics tracking
