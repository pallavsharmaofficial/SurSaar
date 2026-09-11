import 'package:flutter/material.dart';

import '../../models/chord_voicing.dart';

/// Draws a chord box: 6 strings × 5 frets with finger dots, open/muted
/// markers, barres and the base-fret label.
class ChordDiagram extends StatelessWidget {
  const ChordDiagram({
    super.key,
    required this.voicing,
    this.size = 120,
    this.showName = true,
    this.color,
    this.accent,
    this.highlightFingers = const <int>{},
  });

  final ChordVoicing voicing;
  final double size;
  final bool showName;
  final Color? color;
  final Color? accent;

  /// Fingers drawn in the accent colour (e.g. the one the coach is talking about).
  final Set<int> highlightFingers;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fg = color ?? theme.colorScheme.onSurface;
    final ac = accent ?? theme.colorScheme.primary;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (showName)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              voicing.name,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: fg,
              ),
            ),
          ),
        SizedBox(
          width: size,
          height: size * 1.15,
          child: CustomPaint(
            painter: _ChordDiagramPainter(
              voicing: voicing,
              color: fg,
              accent: ac,
              highlightFingers: highlightFingers,
            ),
          ),
        ),
        if (voicing.label != null && voicing.label != 'open')
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              voicing.label!,
              style: theme.textTheme.labelSmall?.copyWith(
                color: fg.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }
}

class _ChordDiagramPainter extends CustomPainter {
  _ChordDiagramPainter({
    required this.voicing,
    required this.color,
    required this.accent,
    required this.highlightFingers,
  });

  final ChordVoicing voicing;
  final Color color;
  final Color accent;
  final Set<int> highlightFingers;

  static const int fretsShown = 5;

  @override
  void paint(Canvas canvas, Size size) {
    final topPad = size.height * 0.16; // room for X / O markers
    final leftPad = size.width * 0.16; // room for the base-fret label
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

    // strings
    for (var s = 0; s < 6; s++) {
      final x = leftPad + s * stringGap;
      canvas.drawLine(Offset(x, topPad), Offset(x, topPad + gridH), line);
    }
    // frets (nut is thick when at the top of the neck)
    for (var f = 0; f <= fretsShown; f++) {
      final y = topPad + f * fretGap;
      final isNut = f == 0 && base == 1;
      canvas.drawLine(
        Offset(leftPad, y),
        Offset(leftPad + gridW, y),
        isNut
            ? (Paint()
                ..color = color
                ..strokeWidth = 4)
            : line,
      );
    }
    // base fret label
    if (base > 1) {
      _text(
        canvas,
        '${base}fr',
        Offset(leftPad * 0.05, topPad + fretGap * 0.2),
        color.withValues(alpha: 0.8),
        size.width * 0.11,
      );
    }

    // barres
    for (final barre in voicing.barres) {
      final row = barre.fret - base;
      if (row < 0 || row >= fretsShown) continue;
      final y = topPad + (row + 0.5) * fretGap;
      final x1 = leftPad + barre.startString * stringGap;
      final x2 = leftPad + barre.endString * stringGap;
      final r = stringGap * 0.32;
      final paint = Paint()
        ..color = (highlightFingers.contains(barre.finger) ? accent : color)
            .withValues(alpha: 0.9);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(x1 - r, y - r, x2 + r, y + r),
          Radius.circular(r),
        ),
        paint,
      );
    }

    // dots + markers
    for (var s = 0; s < 6; s++) {
      final x = leftPad + s * stringGap;
      final fret = voicing.frets[s];
      final finger = voicing.fingers[s];
      if (fret < 0) {
        _text(
          canvas,
          '×',
          Offset(x - size.width * 0.045, topPad * 0.05),
          color.withValues(alpha: 0.8),
          size.width * 0.12,
        );
        continue;
      }
      if (fret == 0) {
        canvas.drawCircle(
          Offset(x, topPad * 0.45),
          stringGap * 0.2,
          Paint()
            ..color = color.withValues(alpha: 0.8)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4,
        );
        continue;
      }
      final row = fret - base;
      if (row < 0 || row >= fretsShown) continue;
      final y = topPad + (row + 0.5) * fretGap;
      final inBarre = voicing.barres.any(
        (b) => b.fret == fret && s >= b.startString && s <= b.endString,
      );
      final dotColor = highlightFingers.contains(finger) ? accent : color;
      if (!inBarre) {
        canvas.drawCircle(
          Offset(x, y),
          stringGap * 0.34,
          Paint()..color = dotColor,
        );
      }
      if (finger > 0) {
        _text(
          canvas,
          finger == 5 ? 'T' : '$finger',
          Offset(x - size.width * 0.04, y - size.width * 0.065),
          inBarre ? color : _contrast(dotColor),
          size.width * 0.1,
          bold: true,
        );
      }
    }
  }

  Color _contrast(Color c) =>
      c.computeLuminance() > 0.5 ? const Color(0xFF0F172A) : Colors.white;

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
