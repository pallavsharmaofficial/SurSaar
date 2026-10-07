import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sursaar/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../models/song.dart';
import '../../repositories/song_repository.dart';
import '../../teacher/engine/practice_plan.dart';
import '../../teacher/melody/tab_parser.dart';
import '../../tutor/journey.dart';
import '../../tutor/tutor_repository.dart';
import '../../widgets/app_back_button.dart';
import '../../widgets/difficulty_badge.dart';
import '../../widgets/tutor/sheet_views.dart';
import '../../widgets/tutor/tutor_widgets.dart';
import '../teacher/teacher_screen.dart';

/// The tutor's step-by-step plan for one song.
class JourneyScreen extends StatefulWidget {
  const JourneyScreen({super.key, required this.songId});

  final String songId;

  @override
  State<JourneyScreen> createState() => _JourneyScreenState();
}

class _JourneyScreenState extends State<JourneyScreen> {
  late final TutorRepository _tutor = context.read<TutorRepository>();
  late Future<(Song, SongJourney)?> _data = _load();

  Future<(Song, SongJourney)?> _load() async {
    final song = await _tutor.song(widget.songId);
    if (song == null) return null;
    return (song, await _tutor.journeyFor(song));
  }

  void _reload() {
    if (mounted) setState(() => _data = _load());
  }

  Future<void> _open(int index) async {
    await context.push(tutorStepLocation(widget.songId, index));
    _reload();
  }

  Future<void> _restart(Song song) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.restartJourneyTitle),
        content: Text(l10n.restartJourneyBody),
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
    await _tutor.restartJourney(song);
    _reload();
  }

  Future<void> _pasteTab(Song song) async {
    final pasted = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.backgroundDark,
      builder: (context) => _PasteTabSheet(initial: song.tabs ?? ''),
    );
    if (pasted == null || !mounted) return;
    final songs = context.read<SongRepository>();
    final updated = await songs.addUserSong(song.copyWith(tabs: pasted));
    await _tutor.restartJourney(updated);
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FutureBuilder<(Song, SongJourney)?>(
      future: _data,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Scaffold(
            appBar: AppBar(leading: const AppBackButton()),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        final data = snapshot.data;
        if (data == null) {
          return Scaffold(
            appBar: AppBar(leading: const AppBackButton()),
            body: Center(child: Text(l10n.noSongsFound)),
          );
        }
        final (song, journey) = data;
        return Scaffold(
          appBar: AppBar(
            leading: const AppBackButton(),
            title: Text(song.title, overflow: TextOverflow.ellipsis),
            actions: <Widget>[
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'restart') _restart(song);
                  if (value == 'tab') _pasteTab(song);
                  if (value == 'details') {
                    context.push('/song/${song.id}', extra: song);
                  }
                },
                itemBuilder: (context) => <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    value: 'restart',
                    child: Text(l10n.restartJourneyTitle),
                  ),
                  PopupMenuItem<String>(
                    value: 'tab',
                    child: Text(l10n.pasteTab),
                  ),
                  PopupMenuItem<String>(
                    value: 'details',
                    child: Text(l10n.songDetails),
                  ),
                ],
              ),
            ],
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 900;
              final steps = _Steps(journey: journey, onOpen: _open);
              final info = _SongInfo(
                song: song,
                onPasteTab: () => _pasteTab(song),
              );
              if (wide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: <Widget>[
                          _Header(song: song, journey: journey),
                          const SizedBox(height: 16),
                          steps,
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 400,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: <Widget>[info],
                      ),
                    ),
                  ],
                );
              }
              return ListView(
                padding: const EdgeInsets.all(16),
                children: <Widget>[
                  _Header(song: song, journey: journey),
                  const SizedBox(height: 16),
                  steps,
                  const SizedBox(height: 16),
                  info,
                ],
              );
            },
          ),
          bottomNavigationBar: journey.completed || journey.stages.isEmpty
              ? null
              : SafeArea(
                  minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: FilledButton.icon(
                    onPressed: () => _open(journey.current),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text(
                      l10n.startStep(
                        journey.current + 1,
                        journey.currentStage?.title ?? '',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.song, required this.journey});

  final Song song;
  final SongJourney journey;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final style = CollectionStyle.of(song.collection);
    final verified = song.tags.contains('verified');
    final facts = <String>[
      if (song.key != null) '${l10n.keyLabel} ${song.key}',
      if (song.capo > 0) l10n.capoLabel(song.capo),
      if (song.bpm != null) '${song.bpm} BPM',
      if (!song.hasMelody) song.strummingPattern,
    ];
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: style.colors,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(style.emoji, style: const TextStyle(fontSize: 30)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      song.title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      <String>[
                        song.artist,
                        if (song.album != null) song.album!,
                        if (song.year != null) '${song.year}',
                      ].join(' · '),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: <Widget>[
              DifficultyBadge(difficulty: song.difficulty),
              for (final fact in facts) _Chip(fact),
              _Chip(verified ? '✔ ${l10n.chartVerified}' : l10n.chartCommunity),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            journey.stages.isEmpty
                ? l10n.noTabYet
                : journey.completed
                ? l10n.journeyComplete
                : l10n.journeyIntro(journey.stages.length),
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: journey.progress,
              minHeight: 8,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      text,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class _Steps extends StatelessWidget {
  const _Steps({required this.journey, required this.onOpen});

  final SongJourney journey;
  final void Function(int index) onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          l10n.yourPath,
          style: theme.textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        if (journey.stages.isEmpty)
          Text(
            l10n.noTabYet,
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
        for (var i = 0; i < journey.stages.length; i++)
          _StepTile(
            index: i,
            stage: journey.stages[i],
            current: i == journey.current && !journey.completed,
            last: i == journey.stages.length - 1,
            onTap: () => onOpen(i),
          ).animate().fadeIn(delay: (50 * i).ms, duration: 250.ms),
      ],
    );
  }
}

class _StepTile extends StatelessWidget {
  const _StepTile({
    required this.index,
    required this.stage,
    required this.current,
    required this.last,
    required this.onTap,
  });

  final int index;
  final JourneyStage stage;
  final bool current;
  final bool last;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final passed = stage.passed;
    final color = passed
        ? tutorGreen
        : current
        ? AppColors.primary
        : Colors.white24;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SizedBox(
            width: 36,
            child: Column(
              children: <Widget>[
                Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: passed || current ? color : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 2),
                  ),
                  child: passed
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : Text(
                          '${index + 1}',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                if (!last)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: passed ? tutorGreen : Colors.white12,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Material(
                color: current
                    ? AppColors.primary.withValues(alpha: 0.18)
                    : tutorSurface,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: onTap,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Text(stage.kind.emoji),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                stage.title,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (stage.attempts > 0)
                              Text(
                                '${stage.bestScore.round()}%',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: passed
                                      ? tutorGreen
                                      : AppColors.successGold,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          stage.goal,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          <String>[
                            stage.isPlayAlong
                                ? l10n.modePlayAlong
                                : l10n.modeLearn,
                            if (stage.isPlayAlong)
                              l10n.tempoPercent((stage.tempo * 100).round()),
                            l10n.passMark(stage.passScore.round()),
                          ].join(' · '),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SongInfo extends StatelessWidget {
  const _SongInfo({required this.song, required this.onPasteTab});

  final Song song;
  final VoidCallback onPasteTab;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final heading = theme.textTheme.titleSmall?.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.bold,
    );
    final melody = song.hasMelody;
    final plan = melody
        ? PracticePlan.forMelody(
            TabParser.parse(song.tabs!).notes,
            title: song.title,
          )
        : PracticePlan.forSong(song);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: tutorSurface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(melody ? l10n.tabSheet : l10n.chordSheet, style: heading),
              const SizedBox(height: 8),
              if (plan.targets.isEmpty)
                Text(
                  l10n.noTabYet,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white60,
                  ),
                )
              else if (melody)
                TabStaffView(plan: plan, currentTarget: -1)
              else
                SongSheetView(plan: plan, currentTarget: -1, maxHeight: 320),
            ],
          ),
        ),
        if (song.collection == SongCollection.instrumental) ...<Widget>[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onPasteTab,
            icon: const Icon(Icons.content_paste_rounded),
            label: Text(l10n.pasteTab),
            style: OutlinedButton.styleFrom(foregroundColor: Colors.white),
          ),
        ],
        if (song.techniqueFocus.isNotEmpty) ...<Widget>[
          const SizedBox(height: 16),
          Text(l10n.whatYouWillLearn, style: heading),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: <Widget>[
              for (final t in song.techniqueFocus)
                Chip(label: Text(t), visualDensity: VisualDensity.compact),
            ],
          ),
        ],
        if ((song.notes ?? '').isNotEmpty) ...<Widget>[
          const SizedBox(height: 16),
          Text(l10n.tutorNotes, style: heading),
          const SizedBox(height: 6),
          Text(
            song.notes!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textOnDark,
            ),
          ),
        ],
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            if (song.tutorialUrl.isNotEmpty)
              OutlinedButton.icon(
                onPressed: () => launchUrl(
                  Uri.parse(song.tutorialUrl),
                  mode: LaunchMode.externalApplication,
                ),
                icon: const Icon(Icons.play_circle_outline),
                label: Text(l10n.openTutorialButton),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.white),
              ),
            if ((song.sourceUrl ?? '').isNotEmpty)
              TextButton.icon(
                onPressed: () => launchUrl(
                  Uri.parse(song.sourceUrl!),
                  mode: LaunchMode.externalApplication,
                ),
                icon: const Icon(Icons.link, size: 18),
                label: Text(l10n.chartSource),
              ),
          ],
        ),
      ],
    );
  }
}

/// Paste an ASCII tab (e.g. one found online); it stays on this device.
class _PasteTabSheet extends StatefulWidget {
  const _PasteTabSheet({required this.initial});

  final String initial;

  @override
  State<_PasteTabSheet> createState() => _PasteTabSheetState();
}

class _PasteTabSheetState extends State<_PasteTabSheet> {
  late final TextEditingController _text = TextEditingController(
    text: widget.initial,
  );

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final parsed = TabParser.parse(_text.text);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            l10n.pasteTab,
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.pasteTabHelp,
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _text,
            maxLines: 10,
            minLines: 6,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
            decoration: InputDecoration(
              hintText: 'e|-----0-------|\nB|--1-----3-1--|',
              filled: true,
              fillColor: tutorSurface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            parsed.isEmpty
                ? l10n.tabNotRecognised
                : l10n.tabRecognised(
                    parsed.notes.length,
                    parsed.sections.length,
                  ),
            style: theme.textTheme.labelMedium?.copyWith(
              color: parsed.isEmpty ? AppColors.secondary : tutorGreen,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: parsed.isEmpty
                ? null
                : () => Navigator.of(context).pop(_text.text),
            child: Text(l10n.useThisTab),
          ),
        ],
      ),
    );
  }
}
