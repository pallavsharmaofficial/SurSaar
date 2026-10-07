import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sursaar/l10n/app_localizations.dart';

import '../../blocs/teacher/teacher_bloc.dart';
import '../../blocs/teacher/teacher_event.dart';
import '../../blocs/teacher/teacher_state.dart';
import '../../core/theme/app_colors.dart';
import '../../tutor/tutor_brain.dart';
import '../../widgets/tutor/tutor_widgets.dart';
import 'teacher_screen.dart';

/// The tutor's debrief after a session: what went well, what to work on,
/// habits it has noticed, and the next step.
class TutorFeedbackCard extends StatelessWidget {
  const TutorFeedbackCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return BlocBuilder<TeacherBloc, TeacherState>(
      buildWhen: (a, b) =>
          a.feedback != b.feedback || a.isFinished != b.isFinished,
      builder: (context, state) {
        final feedback = state.feedback;
        if (!state.isFinished || feedback == null) {
          return const SizedBox.shrink();
        }
        final songId = state.journeySongId;
        final next = feedback.nextStageIndex;
        final verdictColor = switch (feedback.verdict) {
          TutorVerdict.advance || TutorVerdict.finished => tutorGreen,
          TutorVerdict.repeat => AppColors.successGold,
          TutorVerdict.easier => AppColors.secondary,
        };
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: tutorSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: verdictColor.withValues(alpha: 0.6)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Text('🧑‍🏫', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.tutorDebrief,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ),
                  if (feedback.passScore != null)
                    _ScorePill(
                      score: feedback.score,
                      pass: feedback.passScore!,
                      color: verdictColor,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                feedback.headline,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (feedback.wentWell.isNotEmpty) ...<Widget>[
                const SizedBox(height: 14),
                _Heading('✅ ${l10n.whatWentWell}'),
                for (final line in feedback.wentWell) _Bullet(line, tutorGreen),
              ],
              if (feedback.improve.isNotEmpty) ...<Widget>[
                const SizedBox(height: 14),
                _Heading('🎯 ${l10n.whatToImprove}'),
                for (var i = 0; i < feedback.improve.length; i++)
                  _TipTile(tip: feedback.improve[i])
                      .animate()
                      .fadeIn(delay: (120 * i).ms, duration: 300.ms)
                      .slideX(begin: 0.06),
              ],
              if (feedback.style.isNotEmpty) ...<Widget>[
                const SizedBox(height: 14),
                _Heading('👀 ${l10n.yourPlayingStyle}'),
                for (final line in feedback.style.take(3))
                  _Bullet(line, Colors.white54),
              ],
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  if (songId != null && next != null)
                    FilledButton.icon(
                      onPressed: () => context.pushReplacement(
                        tutorStepLocation(songId, next),
                      ),
                      icon: Icon(
                        feedback.verdict == TutorVerdict.advance
                            ? Icons.arrow_forward_rounded
                            : Icons.replay_rounded,
                      ),
                      label: Text(feedback.nextLabel ?? l10n.continueLabel),
                    )
                  else if (songId == null)
                    FilledButton.icon(
                      onPressed: () => context.read<TeacherBloc>().add(
                        const TeacherStarted(),
                      ),
                      icon: const Icon(Icons.replay_rounded),
                      label: Text(l10n.playAgain),
                    ),
                  if (songId != null)
                    OutlinedButton.icon(
                      onPressed: () =>
                          context.pushReplacement('/tutor/song/$songId'),
                      icon: const Icon(Icons.route_rounded),
                      label: Text(l10n.songJourney),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white30),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.06);
      },
    );
  }
}

class _ScorePill extends StatelessWidget {
  const _ScorePill({
    required this.score,
    required this.pass,
    required this.color,
  });

  final double score;
  final double pass;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '${score.round()} / ${pass.round()}',
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text, this.color);

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.only(top: 7, right: 8),
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        Expanded(
          child: Text(
            text,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textOnDark),
          ),
        ),
      ],
    ),
  );
}

class _TipTile extends StatelessWidget {
  const _TipTile({required this.tip});

  final TutorTip tip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final drill = tip.drillChords;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            tip.title,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.successGold,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            tip.detail,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textOnDark,
            ),
          ),
          if (drill != null && drill.isNotEmpty)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => context.push(
                  adhocPracticeLocation(
                    drill.length == 2 ? <String>[...drill, ...drill] : drill,
                  ),
                ),
                icon: const Icon(Icons.fitness_center_rounded, size: 18),
                label: Text(tip.drillLabel ?? 'Drill'),
                style: TextButton.styleFrom(foregroundColor: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}
