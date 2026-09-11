import 'package:flutter/material.dart';

import '../../teacher/engine/practice_plan.dart';

/// Upcoming chord targets, the current one enlarged with a progress bar.
class ChordRibbon extends StatelessWidget {
  const ChordRibbon({
    super.key,
    required this.plan,
    required this.currentIndex,
    required this.targetProgress,
  });

  final PracticePlan plan;
  final int currentIndex;
  final double targetProgress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final targets = plan.targets;
    if (targets.isEmpty) return const SizedBox.shrink();
    final start = (currentIndex - 1).clamp(0, targets.length - 1);
    final end = (currentIndex + 5).clamp(0, targets.length);
    final visible = <int>[for (var i = start; i < end; i++) i];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: visible
            .map((i) {
              final target = targets[i];
              final isCurrent = i == currentIndex;
              final isPast = i < currentIndex;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: EdgeInsets.symmetric(
                        horizontal: isCurrent ? 18 : 12,
                        vertical: isCurrent ? 10 : 8,
                      ),
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? theme.colorScheme.primary
                            : theme.colorScheme.surfaceContainerHighest
                                  .withValues(alpha: isPast ? 0.35 : 0.7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        target.chord,
                        style:
                            (isCurrent
                                    ? theme.textTheme.headlineSmall
                                    : theme.textTheme.titleMedium)
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isCurrent
                                      ? theme.colorScheme.onPrimary
                                      : theme.colorScheme.onSurface.withValues(
                                          alpha: isPast ? 0.5 : 1,
                                        ),
                                ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: isCurrent ? 64 : 40,
                      child: LinearProgressIndicator(
                        value: isCurrent ? targetProgress : (isPast ? 1 : 0),
                        minHeight: 3,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      target.section,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            })
            .toList(growable: false),
      ),
    );
  }
}
