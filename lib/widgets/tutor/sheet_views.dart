import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../teacher/engine/practice_plan.dart';
import '../../teacher/melody/melody_tab.dart';
import 'tutor_widgets.dart';

/// Which plan target each learn-mode step stands for, or empty when the
/// steps are a drill that doesn't follow the timeline.
List<int> stepTargets(PracticePlan plan) {
  final steps = plan.learnSteps;
  if (plan.targets.length == steps.length) {
    return List<int>.generate(steps.length, (i) => i);
  }
  final merged = <int>[];
  String? last;
  for (var i = 0; i < plan.targets.length; i++) {
    if (plan.targets[i].chord != last) {
      merged.add(i);
      last = plan.targets[i].chord;
    }
  }
  return merged.length == steps.length ? merged : const <int>[];
}

/// The song's chord chart, bar by bar, following along with the tutor.
class SongSheetView extends StatefulWidget {
  const SongSheetView({
    super.key,
    required this.plan,
    required this.currentTarget,
    this.maxHeight = 260,
  });

  final PracticePlan plan;

  /// Index into [PracticePlan.targets], or -1 before the start.
  final int currentTarget;
  final double maxHeight;

  @override
  State<SongSheetView> createState() => _SongSheetViewState();
}

class _SongSheetViewState extends State<SongSheetView> {
  final ScrollController _scroll = ScrollController();
  final GlobalKey _currentKey = GlobalKey();

  @override
  void didUpdateWidget(SongSheetView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentTarget != widget.currentTarget) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _follow());
    }
  }

  void _follow() {
    final box = _currentKey.currentContext?.findRenderObject();
    if (box == null || !_scroll.hasClients) return;
    _scroll.position.ensureVisible(
      box,
      alignment: 0.3,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final targets = widget.plan.targets;
    // Contiguous runs of the same section become one row group.
    final groups = <(String, List<int>)>[];
    for (var i = 0; i < targets.length; i++) {
      final name = targets[i].section;
      if (groups.isEmpty || groups.last.$1 != name) {
        groups.add((name, <int>[]));
      }
      groups.last.$2.add(i);
    }
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: widget.maxHeight),
      child: SingleChildScrollView(
        controller: _scroll,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            for (final (name, indices) in groups) ...<Widget>[
              Padding(
                padding: const EdgeInsets.only(top: 6, bottom: 4),
                child: Text(
                  name.isEmpty ? '' : name.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white54,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: <Widget>[
                  for (final i in indices)
                    _Bar(
                      key: i == widget.currentTarget ? _currentKey : null,
                      label: TabNote.display(targets[i].chord),
                      beats: targets[i].beats,
                      state: widget.currentTarget < 0
                          ? _BarState.upcoming
                          : i < widget.currentTarget
                          ? _BarState.done
                          : i == widget.currentTarget
                          ? _BarState.now
                          : _BarState.upcoming,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

enum _BarState { done, now, upcoming }

class _Bar extends StatelessWidget {
  const _Bar({
    super.key,
    required this.label,
    required this.beats,
    required this.state,
  });

  final String label;
  final double beats;
  final _BarState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = state == _BarState.now;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: 44 + math.min(beats, 8) * 4,
      padding: const EdgeInsets.symmetric(vertical: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: now
            ? AppColors.primary
            : state == _BarState.done
            ? tutorGreen.withValues(alpha: 0.14)
            : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: now
              ? Colors.white
              : state == _BarState.done
              ? tutorGreen.withValues(alpha: 0.6)
              : Colors.white12,
        ),
      ),
      child: Text(
        label,
        style: theme.textTheme.titleSmall?.copyWith(
          color: state == _BarState.done ? Colors.white60 : Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Six-line tablature for a melody plan, scrolling with the current note.
class TabStaffView extends StatefulWidget {
  const TabStaffView({
    super.key,
    required this.plan,
    required this.currentTarget,
    this.heardMidi,
  });

  final PracticePlan plan;
  final int currentTarget;

  /// The note being heard right now, to show a "you are here" ghost.
  final int? heardMidi;

  @override
  State<TabStaffView> createState() => _TabStaffViewState();
}

class _TabStaffViewState extends State<TabStaffView> {
  static const double pxPerBeat = 46;
  static const double lead = 28;
  final ScrollController _scroll = ScrollController();

  @override
  void didUpdateWidget(TabStaffView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentTarget != widget.currentTarget) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _follow());
    }
  }

  void _follow() {
    if (!_scroll.hasClients || widget.currentTarget < 0) return;
    final targets = widget.plan.targets;
    if (widget.currentTarget >= targets.length) return;
    final x = lead + targets[widget.currentTarget].startBeat * pxPerBeat;
    final viewport = _scroll.position.viewportDimension;
    final to = (x - viewport * 0.3).clamp(
      0.0,
      _scroll.position.maxScrollExtent,
    );
    _scroll.animateTo(
      to,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = lead * 2 + widget.plan.totalBeats * pxPerBeat;
    return SizedBox(
      height: 150,
      child: SingleChildScrollView(
        controller: _scroll,
        scrollDirection: Axis.horizontal,
        child: CustomPaint(
          size: Size(math.max(width, 200), 150),
          painter: _TabPainter(
            targets: widget.plan.targets,
            current: widget.currentTarget,
            heardMidi: widget.heardMidi,
            textStyle: Theme.of(context).textTheme.labelLarge!,
          ),
        ),
      ),
    );
  }
}

class _TabPainter extends CustomPainter {
  _TabPainter({
    required this.targets,
    required this.current,
    required this.heardMidi,
    required this.textStyle,
  });

  final List<ChordTarget> targets;
  final int current;
  final int? heardMidi;
  final TextStyle textStyle;

  static const double top = 26;
  static const double gap = 20;

  double _y(int string) => top + (5 - string) * gap;

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = Colors.white24
      ..strokeWidth = 1;
    for (var s = 0; s < 6; s++) {
      canvas.drawLine(Offset(0, _y(s)), Offset(size.width, _y(s)), line);
      _text(
        canvas,
        TabNote.stringNames[s],
        Offset(8, _y(s)),
        Colors.white38,
        10,
      );
    }
    String? lastSection;
    for (var i = 0; i < targets.length; i++) {
      final target = targets[i];
      final note = TabNote.fromToken(target.chord);
      if (note == null) continue;
      final x =
          _TabStaffViewState.lead +
          target.startBeat * _TabStaffViewState.pxPerBeat +
          14;
      if (target.section != lastSection) {
        lastSection = target.section;
        canvas.drawLine(
          Offset(x - 12, top - 4),
          Offset(x - 12, _y(0) + 4),
          Paint()
            ..color = Colors.white30
            ..strokeWidth = 1.5,
        );
        _text(
          canvas,
          target.section,
          Offset(x - 8, 10),
          Colors.white54,
          10,
          center: false,
        );
      }
      final isNow = i == current;
      final done = current >= 0 && i < current;
      final center = Offset(x, _y(note.string));
      canvas.drawCircle(
        center,
        isNow ? 12 : 9,
        Paint()
          ..color = isNow
              ? AppColors.primary
              : done
              ? tutorGreen.withValues(alpha: 0.25)
              : const Color(0xFF0F172A),
      );
      if (isNow) {
        canvas.drawCircle(
          center,
          13,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = Colors.white,
        );
      }
      _text(
        canvas,
        '${note.fret}',
        center,
        done ? tutorGreen : Colors.white,
        isNow ? 13 : 12,
      );
    }
    // Where the heard pitch would sit relative to the current target.
    final heard = heardMidi;
    if (heard != null && current >= 0 && current < targets.length) {
      final target = TabNote.fromToken(targets[current].chord);
      if (target != null && heard != target.midi) {
        final x =
            _TabStaffViewState.lead +
            targets[current].startBeat * _TabStaffViewState.pxPerBeat +
            14;
        final diff = heard - target.midi;
        _text(
          canvas,
          diff > 0 ? '▲ ${diff.abs()}' : '▼ ${diff.abs()}',
          Offset(x, _y(0) + 22),
          AppColors.secondary,
          11,
        );
      }
    }
  }

  void _text(
    Canvas canvas,
    String text,
    Offset at,
    Color color,
    double size, {
    bool center = true,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: textStyle.copyWith(
          color: color,
          fontSize: size,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      center
          ? at - Offset(painter.width / 2, painter.height / 2)
          : at - Offset(0, painter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _TabPainter old) =>
      old.current != current ||
      old.heardMidi != heardMidi ||
      !identical(old.targets, targets);
}
