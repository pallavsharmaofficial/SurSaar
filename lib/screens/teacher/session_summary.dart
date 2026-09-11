import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sursaar/l10n/app_localizations.dart';

import '../../blocs/teacher/teacher_bloc.dart';
import '../../blocs/teacher/teacher_event.dart';
import '../../blocs/teacher/teacher_state.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/teacher/accuracy_ring.dart';
import '../../widgets/teacher/effects.dart';

/// Celebration + results card shown when a session ends.
class SessionSummary extends StatelessWidget {
  const SessionSummary({
    super.key,
    required this.onPracticeTricky,
    required this.onDone,
  });

  final void Function(List<String> chords) onPracticeTricky;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return BlocBuilder<TeacherBloc, TeacherState>(
      buildWhen: (a, b) =>
          a.isFinished != b.isFinished ||
          a.saved != b.saved ||
          a.snapshot?.cue?.id != b.snapshot?.cue?.id,
      builder: (context, state) {
        final snapshot = state.snapshot;
        if (!state.isFinished || snapshot == null) {
          return const SizedBox.shrink();
        }
        final bloc = context.read<TeacherBloc>();
        final tricky = snapshot.trickyChords
            .map((s) => s.chord)
            .toList(growable: false);
        final learn = snapshot.isLearn;
        final white = theme.textTheme.bodyMedium?.copyWith(color: Colors.white);
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[AppColors.primary, Color(0xFF7C3AED)],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: CelebrationBurst(
                  trigger: snapshot.stars >= 2 ? (snapshot.cue?.id ?? 0) : 0,
                  particles: 60,
                  spread: 2.2,
                  duration: const Duration(milliseconds: 1400),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: <Widget>[
                    Text(
                      l10n.sessionComplete,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    StarRating(stars: snapshot.stars),
                    const SizedBox(height: 10),
                    Text(
                      learn
                          ? l10n.youPlayed(
                              snapshot.successes,
                              snapshot.targetCount,
                            )
                          : '${snapshot.score.round()}%',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (snapshot.bestCombo >= 2)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '🔥 ${l10n.bestStreak(snapshot.bestCombo)}',
                          style: white,
                        ),
                      ),
                    if (!learn) ...<Widget>[
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          AccuracyRing(
                            value: snapshot.chordAccuracy,
                            label: l10n.chordsShort,
                          ),
                          const SizedBox(width: 16),
                          AccuracyRing(
                            value: snapshot.timingAccuracy,
                            label: l10n.timing,
                            color: snapshot.strums == 0 ? Colors.white24 : null,
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 14),
                    if (tricky.isEmpty)
                      Text(
                        '✨ ${l10n.allClean}',
                        style: white?.copyWith(fontWeight: FontWeight.w600),
                      )
                    else ...<Widget>[
                      Text(
                        l10n.trickyChords,
                        style: white?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        alignment: WrapAlignment.center,
                        children: <Widget>[
                          for (var i = 0; i < tricky.length; i++)
                            Chip(
                              label: Text(
                                tricky[i],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textOnLight,
                                ),
                              ),
                            ).animate().scale(
                              delay: (120 * i).ms,
                              curve: Curves.easeOutBack,
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      FilledButton.tonalIcon(
                        onPressed: () => onPracticeTricky(tricky),
                        icon: const Icon(Icons.fitness_center_rounded),
                        label: Text(l10n.practiceTricky),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () => bloc.add(const TeacherStarted()),
                            icon: const Icon(Icons.replay_rounded),
                            label: Text(l10n.playAgain),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: onDone,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white54),
                          ),
                          child: Text(l10n.done),
                        ),
                      ],
                    ),
                    AnimatedOpacity(
                      opacity: state.saved ? 1 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            const Icon(
                              Icons.check_circle_rounded,
                              size: 16,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              l10n.savedToProgress,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.08);
      },
    );
  }
}
