import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/chord_voicing.dart';
import 'finger_colors.dart';

/// A chord box (6 strings × 5 frets) whose finger dots pop in one by one
/// whenever the chord changes. Dots use [FingerColors].
class ChordDiagram extends StatefulWidget {
  const ChordDiagram({
    super.key,
    required this.voicing,
    this.size = 120,
    this.showName = true,
    this.color,
    this.accent,
    this.highlightFingers = const <int>{},
    this.animate = true,
    this.onTap,
  });

  final ChordVoicing voicing;
  final double size;
  final bool showName;
  final Color? color;
  final Color? accent;

  /// Fingers drawn with a ring (e.g. the one a hint is about).
  final Set<int> highlightFingers;
  final bool animate;

  /// Makes the diagram tappable (e.g. to open the chord sheet).
  final VoidCallback? onTap;

  @override
  State<ChordDiagram> createState() => _ChordDiagramState();
}

class _ChordDiagramState extends State<ChordDiagram>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 750),
  );

  @override
  void initState() {
    super.initState();
    if (widget.animate) {
      _controller.forward();
    } else {
      _controller.value = 1;
    }
  }

  @override
  void didUpdateWidget(covariant ChordDiagram oldWidget) {
    super.didUpdateWidget(oldWidget);
    final changed =
        oldWidget.voicing.name != widget.voicing.name ||
        oldWidget.voicing.frets.join(',') != widget.voicing.frets.join(',');
    if (changed && widget.animate) _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fg = widget.color ?? theme.colorScheme.onSurface;
    final ac = widget.accent ?? theme.colorScheme.primary;
    final diagram = Semantics(
      button: widget.onTap != null,
      label: 'Chord diagram for ${widget.voicing.name}',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (widget.showName)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                widget.voicing.name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: fg,
                ),
              ),
            ),
          SizedBox(
            width: widget.size,
            height: widget.size * 1.15,
            child: CustomPaint(
              painter: _ChordDiagramPainter(
                voicing: widget.voicing,
                color: fg,
                accent: ac,
                highlightFingers: widget.highlightFingers,
                progress: _controller,
              ),
            ),
          ),
          if (widget.voicing.label != null && widget.voicing.label != 'open')
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                widget.voicing.label!,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: fg.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
    if (widget.onTap == null) return diagram;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(onTap: widget.onTap, child: diagram),
    );
  }
}

class _ChordDiagramPainter extends CustomPainter {
  _ChordDiagramPainter({
    required this.voicing,
    required this.color,
    required this.accent,
    required this.highlightFingers,
    required this.progress,
  }) : super(repaint: progress);

  final ChordVoicing voicing;
  final Color color;
  final Color accent;
  final Set<int> highlightFingers;
  final Animation<double> progress;

  static const int fretsShown = 5;

  /// Scale of the n-th of [count] elements at animation time [t].
  static double _pop(double t, int n, int count) {
    final start = count <= 1 ? 0.0 : 0.55 * n / (count - 1);
    final local = ((t - start) / 0.45).clamp(0.0, 1.0);
    return local == 0 ? 0 : Curves.elasticOut.transform(local);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress.value;
    final topPad = size.height * 0.16;
    final leftPad = size.width * 0.16;
    final rightPad = size.width * 0.06;
    final bottomPad = size.height * 0.04;
    final gridW = size.width - leftPad - rightPad;
    final gridH = size.height - topPad - bottomPad;
    final stringGap = gridW / 5;
    final fretGap = gridH / fretsShown;
    final base = voicing.isOpenPosition ? 1 : voicing.minFrettedFret;

    final line = Paint()
      ..color = color.withValues(alpha: 0.85)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    for (var s = 0; s < 6; s++) {
      final x = leftPad + s * stringGap;
      canvas.drawLine(Offset(x, topPad), Offset(x, topPad + gridH), line);
    }
    for (var f = 0; f <= fretsShown; f++) {
      final y = topPad + f * fretGap;
      final nut = f == 0 && base == 1;
      canvas.drawLine(
        Offset(leftPad, y),
        Offset(leftPad + gridW, y),
        nut
            ? (Paint()
                ..color = color
                ..strokeWidth = 4)
            : line,
      );
    }
    if (base > 1) {
      _text(
        canvas,
        '${base}fr',
        Offset(leftPad * 0.05, topPad + fretGap * 0.2),
        color.withValues(alpha: 0.8),
        size.width * 0.11,
      );
    }

    // markers above the nut fade in first
    final markerAlpha = (t / 0.3).clamp(0.0, 1.0);
    for (var s = 0; s < 6; s++) {
      final x = leftPad + s * stringGap;
      final fret = voicing.frets[s];
      if (fret < 0) {
        _text(
          canvas,
          '×',
          Offset(x - size.width * 0.045, topPad * 0.05),
          color.withValues(alpha: 0.8 * markerAlpha),
          size.width * 0.12,
        );
      } else if (fret == 0) {
        canvas.drawCircle(
          Offset(x, topPad * 0.45),
          stringGap * 0.2,
          Paint()
            ..color = color.withValues(alpha: 0.8 * markerAlpha)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4,
        );
      }
    }

    // barres grow from the first string they cover
    for (final barre in voicing.barres) {
      final row = barre.fret - base;
      if (row < 0 || row >= fretsShown) continue;
      final grow = _pop(t, 0, 2).clamp(0.0, 1.0);
      final y = topPad + (row + 0.5) * fretGap;
      final x1 = leftPad + barre.startString * stringGap;
      final x2 = x1 + (barre.endString - barre.startString) * stringGap * grow;
      final r = stringGap * 0.32;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(x1 - r, y - r, x2 + r, y + r),
          Radius.circular(r),
        ),
        Paint()..color = FingerColors.of(barre.finger).withValues(alpha: 0.9),
      );
    }

    // finger dots, one by one
    final dots = <int>[
      for (var s = 0; s < 6; s++)
        if (voicing.frets[s] > 0) s,
    ];
    for (var n = 0; n < dots.length; n++) {
      final s = dots[n];
      final fret = voicing.frets[s];
      final finger = voicing.fingers[s];
      final row = fret - base;
      if (row < 0 || row >= fretsShown) continue;
      final x = leftPad + s * stringGap;
      final y = topPad + (row + 0.5) * fretGap;
      final inBarre = voicing.barres.any(
        (b) => b.fret == fret && s >= b.startString && s <= b.endString,
      );
      final scale = _pop(t, n, dots.length);
      if (scale <= 0) continue;
      final radius = stringGap * 0.36 * scale;
      final fill = FingerColors.of(finger);
      if (!inBarre) {
        canvas.drawCircle(Offset(x, y), radius, Paint()..color = fill);
      }
      if (highlightFingers.contains(finger)) {
        canvas.drawCircle(
          Offset(x, y),
          radius + 3,
          Paint()
            ..color = accent
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }
      if (finger > 0 && scale > 0.6) {
        _text(
          canvas,
          FingerColors.label(finger),
          Offset(x - size.width * 0.035, y - size.width * 0.065),
          Colors.white,
          size.width * 0.1 * math.min(1, scale),
          bold: true,
        );
      }
    }
  }

  void _text(
    Canvas canvas,
    String text,
    Offset at,
    Color color,
    double fontSize, {
    bool bold = false,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: bold ? FontWeight.bold : FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, at);
  }

  @override
  bool shouldRepaint(covariant _ChordDiagramPainter old) =>
      old.voicing != voicing ||
      old.color != color ||
      old.accent != accent ||
      old.highlightFingers != highlightFingers;
}
