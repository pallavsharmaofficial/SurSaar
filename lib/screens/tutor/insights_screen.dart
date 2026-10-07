import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sursaar/l10n/app_localizations.dart';

import '../../core/theme/app_colors.dart';
import '../../teacher/melody/melody_tab.dart';
import '../../tutor/skill_profile.dart';
import '../../tutor/tutor_repository.dart';
import '../../widgets/app_back_button.dart';
import '../../widgets/tutor/tutor_widgets.dart';
import '../teacher/teacher_screen.dart';

/// Everything the tutor has learned about how you play.
class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  late final TutorRepository _tutor = context.read<TutorRepository>();
  late Future<SkillProfile> _profile = _tutor.profile();

  Future<void> _reset() async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.resetTutorTitle),
        content: Text(l10n.resetTutorBody),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.restart),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _tutor.reset();
    if (mounted) setState(() => _profile = _tutor.profile());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Text(l10n.yourPlayingStyle),
        actions: <Widget>[
          IconButton(
            tooltip: l10n.resetTutorTitle,
            onPressed: _reset,
            icon: const Icon(Icons.restart_alt_rounded),
          ),
        ],
      ),
      body: FutureBuilder<SkillProfile>(
        future: _profile,
        builder: (context, snapshot) {
          final profile = snapshot.data;
          if (profile == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final notes = _tutor.brain.styleNotes(profile);
          final chords =
              profile.chords.values
                  .where((c) => !TabNote.isToken(c.name))
                  .toList()
                ..sort((a, b) => b.mastery.compareTo(a.mastery));
          final changes =
              profile.transitions.values
                  .where((t) => t.averageMs > 0 || t.fails > 0)
                  .toList()
                ..sort((a, b) => b.averageMs.compareTo(a.averageMs));
          return ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              _Card(
                title: '🧑‍🏫 ${l10n.tutorObservations}',
                child: notes.isEmpty
                    ? _Muted(l10n.styleEmpty)
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[for (final n in notes) _Line(n)],
                      ),
              ),
              _Card(
                title: '🎸 ${l10n.chordMastery}',
                child: chords.isEmpty
                    ? _Muted(l10n.styleEmpty)
                    : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: <Widget>[
                          for (final c in chords) _MasteryChip(skill: c),
                        ],
                      ),
              ),
              _Card(
                title: '🔁 ${l10n.chordChanges}',
                child: changes.isEmpty
                    ? _Muted(l10n.styleEmpty)
                    : Column(
                        children: <Widget>[
                          for (final t in changes.take(8)) _ChangeRow(skill: t),
                        ],
                      ),
              ),
              _Card(
                title: '🥁 ${l10n.timing}',
                child: profile.timing.samples == 0
                    ? _Muted(l10n.timingEmpty)
                    : _TimingGauge(timing: profile.timing),
              ),
              _Card(
                title: '📓 ${l10n.tutorDiary}',
                child: profile.diary.isEmpty
                    ? _Muted(l10n.styleEmpty)
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          for (final entry in profile.diary.take(12))
                            _DiaryRow(entry: entry),
                        ],
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: tutorSurface,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        child,
      ],
    ),
  );
}

class _Muted extends StatelessWidget {
  const _Muted(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: Colors.white60),
  );
}

class _Line extends StatelessWidget {
  const _Line(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      '• $text',
      style: Theme.of(
        context,
      ).textTheme.bodyMedium?.copyWith(color: AppColors.textOnDark),
    ),
  );
}

class _MasteryChip extends StatelessWidget {
  const _MasteryChip({required this.skill});

  final ChordSkill skill;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = skill.isMastered
        ? tutorGreen
        : skill.isKnown
        ? AppColors.successGold
        : AppColors.secondary;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => context.push(adhocPracticeLocation(<String>[skill.name])),
      child: Container(
        width: 74,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.6)),
        ),
        child: Column(
          children: <Widget>[
            Text(
              skill.name,
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${(skill.mastery * 100).round()}%',
              style: theme.textTheme.labelSmall?.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChangeRow extends StatelessWidget {
  const _ChangeRow({required this.skill});

  final TransitionSkill skill;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final seconds = skill.averageMs / 1000;
    final fraction = (seconds / 8).clamp(0.05, 1.0);
    final color = skill.isFluent
        ? tutorGreen
        : seconds < 4
        ? AppColors.successGold
        : AppColors.secondary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 92,
            child: Text(
              '${skill.from} → ${skill.to}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: fraction,
                minHeight: 8,
                backgroundColor: Colors.white10,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 48,
            child: Text(
              skill.averageMs == 0 ? '—' : '${seconds.toStringAsFixed(1)}s',
              textAlign: TextAlign.end,
              style: theme.textTheme.labelMedium?.copyWith(color: color),
            ),
          ),
          IconButton(
            tooltip: l10n.drill,
            visualDensity: VisualDensity.compact,
            onPressed: () => context.push(
              adhocPracticeLocation(<String>[
                skill.from,
                skill.to,
                skill.from,
                skill.to,
              ]),
            ),
            icon: const Icon(Icons.fitness_center_rounded, size: 18),
          ),
        ],
      ),
    );
  }
}

/// Where the player's strums land relative to the beat.
class _TimingGauge extends StatelessWidget {
  const _TimingGauge({required this.timing});

  final TimingSkill timing;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final offset = timing.offsetMs.clamp(-150.0, 150.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final x = w / 2 + offset / 150 * (w / 2 - 8);
            return SizedBox(
              height: 34,
              child: Stack(
                children: <Widget>[
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 14,
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: <Color>[
                            AppColors.secondary,
                            tutorGreen,
                            AppColors.secondary,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  Positioned(
                    left: w / 2 - 1,
                    top: 6,
                    child: Container(
                      width: 2,
                      height: 22,
                      color: Colors.white38,
                    ),
                  ),
                  Positioned(
                    left: x - 8,
                    top: 9,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(l10n.rushing, style: theme.textTheme.labelSmall),
            Text(l10n.onTheBeat, style: theme.textTheme.labelSmall),
            Text(l10n.dragging, style: theme.textTheme.labelSmall),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          l10n.timingSummary(
            timing.offsetMs.round(),
            timing.spreadMs.round(),
            (timing.accuracy * 100).round(),
          ),
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.textOnDark,
          ),
        ),
      ],
    );
  }
}

class _DiaryRow extends StatelessWidget {
  const _DiaryRow({required this.entry});

  final TutorDiaryEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final when = DateFormat.MMMd().add_jm().format(
      DateTime.fromMillisecondsSinceEpoch(entry.atMs),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 44,
            child: Text(
              '${entry.score.round()}%',
              style: theme.textTheme.titleSmall?.copyWith(
                color: entry.score >= 70 ? tutorGreen : AppColors.successGold,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  entry.headline,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                  ),
                ),
                Text(
                  '${entry.title} · $when',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
