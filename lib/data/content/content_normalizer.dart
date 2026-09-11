/// Converts any known SurSaar content JSON layout into the v2 schema that
/// [ContentBundle.fromJson] understands.
///
/// Two layouts are in the wild:
///  * v1 (`lessons`/`songs` with app field names)
///  * the "content engine" layout (`metadata`, `chords`, `strumming`,
///    `base_key`, `content.steps`, `ai_config`, `exercises`)
/// Both are mapped to v2 here so the app never silently falls back to the
/// bundled asset because a remote file used different field names.
class ContentNormalizer {
  const ContentNormalizer._();

  static Map<String, dynamic> normalize(Map<String, dynamic> raw) {
    final lessons = <Map<String, dynamic>>[];
    final songs = <Map<String, dynamic>>[];
    final courses = <Map<String, dynamic>>[];
    final chords = <Map<String, dynamic>>[];

    for (final item in _listOfMaps(raw['lessons'])) {
      lessons.add(_normalizeLesson(item));
    }
    for (final item in _listOfMaps(raw['exercises'])) {
      lessons.add(_normalizeExercise(item));
    }
    for (final item in _listOfMaps(raw['songs'])) {
      songs.add(_normalizeSong(item));
    }
    for (final item in _listOfMaps(raw['courses'])) {
      courses.add(_normalizeCourse(item));
    }
    for (final item in _listOfMaps(raw['chords'])) {
      chords.add(item);
    }

    final metadata = raw['metadata'];
    final version =
        raw['version'] ??
        (metadata is Map<String, dynamic> ? metadata['version'] : null) ??
        '1.0';

    return <String, dynamic>{
      'version': version.toString(),
      'schemaVersion': (raw['schemaVersion'] as num?)?.toInt() ?? 2,
      'lastUpdated':
          raw['lastUpdated'] ??
          (metadata is Map<String, dynamic> ? metadata['lastUpdated'] : null),
      'lessons': lessons,
      'songs': songs,
      'courses': courses,
      'chords': chords,
    };
  }

  // ---------------------------------------------------------------- helpers

  static List<Map<String, dynamic>> _listOfMaps(Object? value) {
    if (value is! List) return const <Map<String, dynamic>>[];
    return value.whereType<Map<String, dynamic>>().toList(growable: false);
  }

  static String normalizeDifficulty(Object? value) {
    final text = (value ?? '').toString().trim().toLowerCase();
    switch (text) {
      case 'beginner':
      case 'easy':
      case 'basic':
      case 'novice':
        return 'beginner';
      case 'advanced':
      case 'hard':
      case 'expert':
      case 'pro':
        return 'advanced';
      case 'intermediate':
      case 'medium':
      case 'moderate':
        return 'intermediate';
      default:
        return text.isEmpty ? 'intermediate' : text;
    }
  }

  static String _slug(Object? value, String fallbackPrefix) {
    final text = (value ?? '').toString().trim();
    if (text.isEmpty) {
      return '${fallbackPrefix}_${DateTime.now().millisecondsSinceEpoch}';
    }
    return text;
  }

  static List<String> _stringList(Object? value) {
    if (value is List) {
      return value
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList(growable: false);
    }
    if (value is String && value.trim().isNotEmpty) {
      return value
          .split(RegExp(r'[,\s]+'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(growable: false);
    }
    return const <String>[];
  }

  static Map<String, dynamic> _normalizeSong(Map<String, dynamic> song) {
    final out = Map<String, dynamic>.from(song);
    out['id'] = _slug(song['id'], 'song');
    out['title'] = (song['title'] ?? 'Untitled').toString();
    out['artist'] = (song['artist'] ?? 'Unknown').toString();
    out['difficulty'] = normalizeDifficulty(song['difficulty']);

    // v1/app names take precedence; fall back to content-engine names.
    final chords = _stringList(song['originalChords']).isNotEmpty
        ? _stringList(song['originalChords'])
        : _stringList(song['chords']);
    out['originalChords'] = chords;

    final strumming =
        song['strummingPattern'] ?? song['strumming'] ?? 'D DU UDU';
    out['strummingPattern'] = strumming.toString();

    out['tutorialUrl'] = (song['tutorialUrl'] ?? song['tutorial_url'] ?? '')
        .toString();
    out['key'] = song['key'] ?? _keyFromBaseKey(song['base_key']);
    out['capo'] = (song['capo'] as num?)?.toInt() ?? 0;
    out['album'] = song['album'] ?? song['movie'];
    out['tags'] = _stringList(song['tags']);
    out['sourceUrl'] = song['sourceUrl'] ?? song['source_url'];

    // Build sections from a bare progression when none are provided.
    final sections = song['sections'];
    if (sections is! List || sections.isEmpty) {
      final progression = _stringList(song['progression']);
      final seq = progression.isNotEmpty ? progression : chords;
      if (seq.isNotEmpty) {
        out['sections'] = <Map<String, dynamic>>[
          <String, dynamic>{
            'name': 'Progression',
            'repeat': 2,
            'lines': <Map<String, dynamic>>[
              <String, dynamic>{
                'lyric': '',
                'chords': seq
                    .map((c) => <String, dynamic>{'chord': c, 'position': 0})
                    .toList(growable: false),
              },
            ],
          },
        ];
      }
    }

    // Remove content-engine keys that would confuse strict parsing.
    out.remove('chords');
    out.remove('strumming');
    out.remove('base_key');
    out.remove('movie');
    out.remove('progression');
    out.remove('ai_ready');
    return out;
  }

  static String? _keyFromBaseKey(Object? value) {
    if (value == null) return null;
    final text = value.toString().trim();
    if (text.isEmpty) return null;
    // "G Major" -> "G", "Fm" -> "Fm", "A minor" -> "Am"
    final match = RegExp(
      r'^([A-G][#b]?)\s*(minor|major|min|maj|m)?',
      caseSensitive: false,
    ).firstMatch(text);
    if (match == null) return text;
    final root = match.group(1)!;
    final quality = (match.group(2) ?? '').toLowerCase();
    final isMinor = quality.startsWith('m') && !quality.startsWith('maj');
    return isMinor ? '${root}m' : root;
  }

  static Map<String, dynamic> _normalizeLesson(Map<String, dynamic> lesson) {
    final out = Map<String, dynamic>.from(lesson);
    out['id'] = _slug(lesson['id'], 'lesson');
    out['title'] = (lesson['title'] ?? 'Untitled lesson').toString();
    out['difficulty'] = normalizeDifficulty(lesson['difficulty']);
    out['instrument'] = (lesson['instrument'] ?? 'guitar')
        .toString()
        .toLowerCase();

    final content = lesson['content'];
    var description = (lesson['description'] ?? '').toString();
    var steps = _listOfMaps(lesson['steps']);
    if (content is Map<String, dynamic>) {
      if (description.isEmpty) {
        description = (content['description'] ?? '').toString();
      }
      if (steps.isEmpty && content['steps'] is List) {
        var index = 1;
        steps = (content['steps'] as List)
            .map(
              (step) => step is Map<String, dynamic>
                  ? step
                  : <String, dynamic>{
                      'title': 'Step ${index++}',
                      'description': step.toString(),
                      'durationMinutes': 5,
                    },
            )
            .toList(growable: false);
      }
      if (content['video_url'] != null) out['videoUrl'] = content['video_url'];
    }
    out['description'] = description;
    out['steps'] = steps;
    out['topicsCount'] =
        (lesson['topicsCount'] as num?)?.toInt() ?? steps.length;
    out['duration'] =
        (lesson['duration'] as num?)?.toInt() ??
        steps.fold<int>(
          0,
          (sum, s) => sum + ((s['durationMinutes'] as num?)?.toInt() ?? 5),
        );
    out['isCompleted'] = lesson['isCompleted'] == true;
    out['progress'] = (lesson['progress'] as num?)?.toDouble() ?? 0.0;

    // Map the content-engine ai_config onto teacher targets.
    final aiConfig = lesson['ai_config'];
    if (aiConfig is Map<String, dynamic>) {
      final mode = (aiConfig['mode'] ?? '').toString();
      if (mode == 'rhythm_tracking') {
        out['kind'] ??= 'strumming';
        out['targetStrumming'] ??= aiConfig['pattern'];
        out['targetBpm'] ??= (aiConfig['target_bpm'] as num?)?.toInt();
      } else if (mode == 'audio_analysis') {
        out['kind'] ??= 'chord';
      }
    }
    if (out['targetChords'] == null) {
      out['targetChords'] = _stringList(lesson['target_chords']);
    }
    if (out['kind'] == null) {
      final chords = _stringList(out['targetChords']);
      out['kind'] = chords.isNotEmpty ? 'chord' : 'exercise';
    }
    // Infer target chords from a chord-lesson title like
    // "G-Major and C-Major" when none are given.
    if (_stringList(out['targetChords']).isEmpty && out['kind'] == 'chord') {
      out['targetChords'] = _chordsFromText('${out['title']} $description');
    }

    out.remove('content');
    out.remove('ai_config');
    out.remove('target_chords');
    return out;
  }

  static Map<String, dynamic> _normalizeExercise(Map<String, dynamic> ex) {
    final bpmRange = ex['bpm_range'];
    final instruction = (ex['instruction'] ?? ex['description'] ?? '')
        .toString();
    return <String, dynamic>{
      'id': _slug(ex['id'], 'exercise'),
      'title': (ex['title'] ?? 'Exercise').toString(),
      'description': instruction,
      'difficulty': normalizeDifficulty(ex['difficulty'] ?? 'intermediate'),
      'duration': (ex['duration'] as num?)?.toInt() ?? 10,
      'topicsCount': 1,
      'isCompleted': false,
      'progress': 0.0,
      'kind': (ex['target'] ?? '').toString().toLowerCase() == 'theory'
          ? 'theory'
          : 'exercise',
      'category': ex['target'],
      'targetBpm': bpmRange is List && bpmRange.isNotEmpty
          ? (bpmRange.first as num).toInt()
          : null,
      'steps': <Map<String, dynamic>>[
        <String, dynamic>{
          'title': (ex['title'] ?? 'Exercise').toString(),
          'description': instruction,
          'durationMinutes': 10,
        },
      ],
    };
  }

  static Map<String, dynamic> _normalizeCourse(Map<String, dynamic> course) {
    final out = Map<String, dynamic>.from(course);
    out['id'] = _slug(course['id'], 'course');
    out['difficulty'] = normalizeDifficulty(course['difficulty']);
    out['lessonIds'] = _stringList(course['lessonIds'] ?? course['lessons']);
    out.remove('lessons');
    return out;
  }

  static final RegExp _chordToken = RegExp(
    r'\b([A-G][#b]?)(?:-)?(Major|Minor|major|minor|maj|min|m)?\b',
  );

  static List<String> _chordsFromText(String text) {
    final result = <String>[];
    for (final match in _chordToken.allMatches(text)) {
      final root = match.group(1)!;
      final quality = (match.group(2) ?? '').toLowerCase();
      final chord = quality.startsWith('min') || quality == 'm'
          ? '${root}m'
          : root;
      if (!result.contains(chord)) result.add(chord);
    }
    return result;
  }
}
