import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../repositories/course_repository.dart';
import 'difficulty_badge.dart';

class CourseCard extends StatelessWidget {
  const CourseCard({super.key, required this.progress, required this.onTap});

  final CourseProgress progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final course = progress.course;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Text(course.emoji, style: const TextStyle(fontSize: 26)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      course.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textOnLight,
                      ),
                    ),
                  ),
                  if (progress.isCompleted)
                    const Icon(Icons.verified, color: AppColors.primary),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Text(
                  course.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textOnLight,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress.fraction,
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              ),
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  DifficultyBadge(difficulty: course.difficulty),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${progress.completedCount}/${progress.lessons.length} · ${course.estimatedMinutes} min',
                      textAlign: TextAlign.end,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textOnLight.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
