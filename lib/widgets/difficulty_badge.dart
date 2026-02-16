import 'package:flutter/material.dart';
import '../models/lesson.dart';
import '../models/song.dart';

class DifficultyBadge extends StatelessWidget {
  const DifficultyBadge({
    super.key,
    required this.difficulty,
  });

  final dynamic difficulty;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (color, label) = _getDifficultyData();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  (Color, String) _getDifficultyData() {
    if (difficulty is SongDifficulty) {
      switch (difficulty as SongDifficulty) {
        case SongDifficulty.beginner:
          return (const Color(0xFF4CAF50), 'Beginner');
        case SongDifficulty.intermediate:
          return (const Color(0xFFFF9800), 'Intermediate');
        case SongDifficulty.advanced:
          return (const Color(0xFFF44336), 'Advanced');
      }
    } else if (difficulty is LessonDifficulty) {
      switch (difficulty as LessonDifficulty) {
        case LessonDifficulty.beginner:
          return (const Color(0xFF4CAF50), 'Beginner');
        case LessonDifficulty.intermediate:
          return (const Color(0xFFFF9800), 'Intermediate');
        case LessonDifficulty.advanced:
          return (const Color(0xFFF44336), 'Advanced');
      }
    }
    return (const Color(0xFF4CAF50), 'Beginner');
  }
}
