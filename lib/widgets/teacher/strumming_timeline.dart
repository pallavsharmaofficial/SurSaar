import 'package:flutter/material.dart';

import '../../models/strumming_pattern.dart';
import '../../teacher/models/strum_event.dart';

/// The strumming grid with a beat cursor and per-slot timing feedback.
class StrummingTimeline extends StatelessWidget {
  const StrummingTimeline({
    super.key,
    required this.pattern,
    this.currentSlot = -1,
    this.results = const <int, TimingResult>{},
    this.compact = false,
  });

  final StrummingPattern pattern;

  /// Slot index within the pattern (-1 when not running).
  final int currentSlot;

  /// Timing result per slot-in-pattern for the current cycle.
  final Map<int, TimingResult> results;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final slots = pattern.slots;
    return LayoutBuilder(
      builder: (context, constraints) {
        final cellW = (constraints.maxWidth / slots.length).clamp(18.0, 56.0);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List<Widget>.generate(slots.length, (i) {
                final stroke = slots[i];
                final isCurrent = i == currentSlot;
                final result = results[i];
                final onBeat = i.isEven;
                Color bg = theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: onBeat ? 0.55 : 0.3,
                );
                Color fg = theme.colorScheme.onSurface;
                if (result != null) {
                  switch (result) {
                    case TimingResult.hit:
                      bg = Colors.green.withValues(alpha: 0.75);
                    case TimingResult.early:
                    case TimingResult.late:
                      bg = Colors.amber.withValues(alpha: 0.75);
                      fg = const Color(0xFF0F172A);
                    case TimingResult.miss:
                      bg = Colors.red.withValues(alpha: 0.6);
                    case TimingResult.extra:
                      break;
                  }
                }
                return AnimatedScale(
                  scale: isCurrent ? 1.12 : 1,
                  duration: const Duration(milliseconds: 120),
                  curve: Curves.easeOutBack,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 90),
                    width: cellW - 4,
                    height: compact ? 34 : 46,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isCurrent
                            ? theme.colorScheme.secondary
                            : Colors.transparent,
                        width: 2.5,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      StrummingPattern.arrow(stroke),
                      style: TextStyle(
                        color: stroke == StrokeType.rest
                            ? fg.withValues(alpha: 0.35)
                            : fg,
                        fontSize: compact ? 16 : 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }),
            ),
            if (!compact) ...<Widget>[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List<Widget>.generate(slots.length, (i) {
                  final beat = (i ~/ 2) % pattern.beatsPerBar + 1;
                  return SizedBox(
                    width: cellW,
                    child: Text(
                      i.isEven ? '$beat' : '&',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ],
        );
      },
    );
  }
}
