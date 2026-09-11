import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sursaar/l10n/app_localizations.dart';

import '../core/theme/app_colors.dart';
import '../data/content/chord_library.dart';
import '../screens/teacher/teacher_screen.dart';
import '../teacher/analysis/chord_shape_coach.dart';
import '../teacher/services/sound_service.dart';
import 'teacher/chord_diagram.dart';
import 'teacher/finger_colors.dart';

/// Bottom sheet with a big animated chord diagram, finger-by-finger steps,
/// a "Hear it" button and a shortcut into learn mode for that chord.
class ChordSheet extends StatefulWidget {
  const ChordSheet({super.key, required this.chord});

  final String chord;

  static Future<void> show(BuildContext context, String chord) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.backgroundDark,
      builder: (_) => ChordSheet(chord: chord),
    );
  }

  @override
  State<ChordSheet> createState() => _ChordSheetState();
}

class _ChordSheetState extends State<ChordSheet> {
  final TeacherSoundService _sound = createTeacherSoundService();

  static Color _lineColor(String line) {
    switch (line.split(' ').first.toLowerCase()) {
      case 'index':
      case 'barre':
        return FingerColors.index;
      case 'middle':
        return FingerColors.middle;
      case 'ring':
        return FingerColors.ring;
      case 'pinky':
        return FingerColors.pinky;
      case 'thumb':
        return FingerColors.thumb;
      default:
        return Colors.white38;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final voicing = context.read<ChordLibrary>().voicingFor(widget.chord);
    final lines = voicing == null
        ? const <String>[]
        : ChordShapeCoach.placementText(voicing);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              voicing?.name ?? widget.chord,
              style: theme.textTheme.displaySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9)),
            const SizedBox(height: 12),
            if (voicing != null)
              ChordDiagram(
                voicing: voicing,
                size: 180,
                showName: false,
                color: Colors.white,
                accent: AppColors.successGold,
              ),
            const SizedBox(height: 16),
            for (var i = 0; i < lines.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      width: 12,
                      height: 12,
                      margin: const EdgeInsets.only(top: 4, right: 10),
                      decoration: BoxDecoration(
                        color: _lineColor(lines[i]),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        lines[i],
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textOnDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: (120 * i).ms).slideX(begin: 0.1),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                if (voicing != null && _sound.canPlayChords)
                  OutlinedButton.icon(
                    onPressed: () => _sound.playChord(voicing.midiNotes),
                    icon: const Icon(Icons.volume_up_rounded),
                    label: Text(l10n.hearIt),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.successGold,
                      side: const BorderSide(color: AppColors.successGold),
                    ),
                  ),
                FilledButton.icon(
                  onPressed: () {
                    final router = GoRouter.of(context);
                    Navigator.of(context).pop();
                    router.push(adhocPracticeLocation(<String>[widget.chord]));
                  },
                  icon: const Icon(Icons.school_rounded),
                  label: Text(l10n.practiceThisChord),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
