import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sursaar/l10n/app_localizations.dart';

import '../../core/theme/app_colors.dart';
import '../../models/song.dart';
import '../../tutor/skill_profile.dart';
import '../../tutor/tutor_brain.dart';
import '../../tutor/tutor_repository.dart';
import '../../widgets/tutor/tutor_widgets.dart';

/// Location of the library, optionally opened on one shelf.
String libraryLocation([SongCollection? shelf]) =>
    shelf == null ? '/library' : '/library?shelf=${shelf.name}';

class _HubData {
  const _HubData(this.profile, this.picks, this.counts);

  final SkillProfile profile;
  final List<TutorPick> picks;
  final Map<SongCollection, int> counts;
}

/// The tutor's front desk on the Learn tab: today's lesson, songs in
/// progress, the library shelves and what it has noticed about your playing.
class TutorHub extends StatefulWidget {
  const TutorHub({super.key});

  @override
  State<TutorHub> createState() => _TutorHubState();
}

class _TutorHubState extends State<TutorHub> {
  late final TutorRepository _tutor = context.read<TutorRepository>();
  late Future<_HubData> _data = _load();

  @override
  void initState() {
    super.initState();
    _tutor.revision.addListener(_reload);
  }

  @override
  void dispose() {
    _tutor.revision.removeListener(_reload);
    super.dispose();
  }

  void _reload() {
    if (mounted) setState(() => _data = _load());
  }

  Future<_HubData> _load() async {
    final profile = await _tutor.profile();
    final picks = await _tutor.recommendations();
    final counts = <SongCollection, int>{};
    for (final pick in picks) {
      final shelf = pick.song.collection;
      if (shelf != null) counts[shelf] = (counts[shelf] ?? 0) + 1;
    }
    return _HubData(profile, picks, counts);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_HubData>(
      future: _data,
      builder: (context, snapshot) {
        final data = snapshot.data;
        if (data == null) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final inProgress = data.picks.where((p) => p.inProgress).toList();
        final today = data.picks.isEmpty ? null : data.picks.first;
        // The best new song from each shelf, so every taste gets a door in.
        final fresh = <TutorPick>[
          for (final shelf in SongCollection.values)
            ...data.picks
                .where(
                  (p) =>
                      p.journey == null &&
                      p != today &&
                      p.song.collection == shelf &&
                      p.score > -500,
                )
                .take(1),
        ]..sort((a, b) => b.score.compareTo(a.score));
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _Greeting(profile: data.profile),
              const SizedBox(height: 12),
              if (today != null) _TodayCard(pick: today),
              if (inProgress.length > 1) ...<Widget>[
                const SizedBox(height: 20),
                _Title(AppLocalizations.of(context)!.continueLearning),
                for (final pick in inProgress.skip(1).take(3))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: TutorSongTile(
                      pick: pick,
                      onTap: () => context.push('/tutor/song/${pick.song.id}'),
                    ),
                  ),
              ],
              const SizedBox(height: 20),
              _Title(AppLocalizations.of(context)!.tutorSuggests),
              for (final pick in fresh)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: TutorSongTile(
                    pick: pick,
                    onTap: () => context.push('/tutor/song/${pick.song.id}'),
                  ),
                ),
              const SizedBox(height: 20),
              _Title(AppLocalizations.of(context)!.songLibrary),
              _Shelves(counts: data.counts),
              const SizedBox(height: 20),
              _StyleCard(profile: data.profile, brain: _tutor.brain),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

class _Title extends StatelessWidget {
  const _Title(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      text,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.profile});

  final SkillProfile profile;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final hour = DateTime.now().hour;
    final hello = hour < 12
        ? l10n.goodMorning
        : hour < 17
        ? l10n.goodAfternoon
        : l10n.goodEvening;
    final known = profile.knownChords.length;
    final minutes = profile.totalMs ~/ 60000;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[AppColors.primary, Color(0xFF7C3AED)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Text('🧑‍🏫', style: TextStyle(fontSize: 26)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '$hello! ${profile.isNew ? l10n.tutorIntroNew : l10n.tutorIntroBack}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _Stat(icon: '🎚️', text: profile.level.label),
              _Stat(icon: '🎸', text: l10n.chordsKnown(known)),
              _Stat(icon: '⏱️', text: l10n.minutesPlayed(minutes)),
              _Stat(icon: '🔁', text: l10n.sessionsCount(profile.sessions)),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 350.ms);
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.text});

  final String icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      '$icon $text',
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

/// The one song the tutor wants you to play now.
class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.pick});

  final TutorPick pick;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final song = pick.song;
    final style = CollectionStyle.of(song.collection);
    final journey = pick.journey;
    final stage = journey?.currentStage;
    return Material(
      color: tutorSurface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.push('/tutor/song/${song.id}'),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: style.colors.first.withValues(alpha: 0.7),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                journey == null ? l10n.todaysLesson : l10n.pickUpWhereYouLeft,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: AppColors.successGold,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  Container(
                    width: 56,
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: style.colors),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      style.emoji,
                      style: const TextStyle(fontSize: 26),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          song.title,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          song.artist,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white60,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '“${pick.reason}”',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textOnDark,
                  fontStyle: FontStyle.italic,
                ),
              ),
              if (!song.hasMelody) ...<Widget>[
                const SizedBox(height: 8),
                ChordPills(known: pick.knownChords, fresh: pick.newChords),
              ],
              if (journey != null) ...<Widget>[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: journey.progress,
                    minHeight: 6,
                    backgroundColor: Colors.white12,
                    valueColor: const AlwaysStoppedAnimation<Color>(tutorGreen),
                  ),
                ),
              ],
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => context.push('/tutor/song/${song.id}'),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text(
                    stage == null
                        ? l10n.startLesson
                        : '${l10n.continueLabel}: ${stage.title}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: 100.ms, duration: 350.ms).slideY(begin: 0.05);
  }
}

class _Shelves extends StatelessWidget {
  const _Shelves({required this.counts});

  final Map<SongCollection, int> counts;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 640 ? 4 : 2;
        const spacing = 10.0;
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: <Widget>[
            for (final shelf in SongCollection.values)
              SizedBox(
                width: width,
                height: 92,
                child: Material(
                  borderRadius: BorderRadius.circular(16),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => context.push(libraryLocation(shelf)),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: CollectionStyle.of(shelf).colors,
                        ),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(
                            CollectionStyle.of(shelf).emoji,
                            style: const TextStyle(fontSize: 22),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                CollectionStyle.label(l10n, shelf),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${counts[shelf] ?? 0} ${l10n.songs}',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _StyleCard extends StatelessWidget {
  const _StyleCard({required this.profile, required this.brain});

  final SkillProfile profile;
  final TutorBrain brain;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final notes = brain.styleNotes(profile);
    return Material(
      color: tutorSurface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/tutor/insights'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      '👀 ${l10n.yourPlayingStyle}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.white54),
                ],
              ),
              const SizedBox(height: 8),
              if (notes.isEmpty)
                Text(
                  l10n.styleEmpty,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white60,
                  ),
                )
              else
                for (final note in notes.take(3))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '• $note',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textOnDark,
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
