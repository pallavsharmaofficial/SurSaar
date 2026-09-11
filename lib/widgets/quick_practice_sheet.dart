import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sursaar/l10n/app_localizations.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_colors.dart';
import '../models/strumming_pattern.dart';
import 'teacher/strumming_timeline.dart';

/// Bottom sheet for ad-hoc practice: pick chords, a pattern and a tempo.
class QuickPracticeSheet extends StatefulWidget {
  const QuickPracticeSheet({super.key, this.initialChords = const <String>[]});

  final List<String> initialChords;

  static Future<void> show(
    BuildContext context, {
    List<String> initialChords = const <String>[],
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => QuickPracticeSheet(initialChords: initialChords),
    );
  }

  @override
  State<QuickPracticeSheet> createState() => _QuickPracticeSheetState();
}

class _QuickPracticeSheetState extends State<QuickPracticeSheet> {
  late final List<String> _chords = <String>[...widget.initialChords];
  String _pattern = AppConstants.strummingPresets.first;
  int _bpm = 80;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              l10n.quickPractice,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(l10n.quickPracticeHint, style: theme.textTheme.bodySmall),
            const SizedBox(height: 16),
            Text(l10n.pickChords, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: AppConstants.chords
                  .map((chord) {
                    final selected = _chords.contains(chord);
                    return FilterChip(
                      label: Text(chord),
                      selected: selected,
                      onSelected: (_) => setState(() {
                        selected ? _chords.remove(chord) : _chords.add(chord);
                      }),
                    );
                  })
                  .toList(growable: false),
            ),
            if (_chords.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _chords.join('  →  '),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Text(l10n.strummingPatternLabel, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _pattern,
              items: AppConstants.strummingPresets
                  .map(
                    (p) => DropdownMenuItem<String>(value: p, child: Text(p)),
                  )
                  .toList(growable: false),
              onChanged: (v) => setState(() => _pattern = v ?? _pattern),
            ),
            const SizedBox(height: 8),
            StrummingTimeline(
              pattern: StrummingPattern.parse(_pattern),
              compact: true,
            ),
            const SizedBox(height: 16),
            Text('${l10n.tempo}: $_bpm BPM', style: theme.textTheme.titleSmall),
            Slider(
              value: _bpm.toDouble(),
              min: 40,
              max: 160,
              divisions: 120,
              label: '$_bpm',
              onChanged: (v) => setState(() => _bpm = v.round()),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _chords.isEmpty
                  ? null
                  : () {
                      Navigator.of(context).pop();
                      context.pushNamed(
                        'practiceAdhoc',
                        queryParameters: <String, String>{
                          'chords': _chords.join(','),
                          'pattern': _pattern,
                          'bpm': '$_bpm',
                        },
                      );
                    },
              icon: const Icon(Icons.play_arrow),
              label: Text(l10n.startPractice),
            ),
          ],
        ),
      ),
    );
  }
}
