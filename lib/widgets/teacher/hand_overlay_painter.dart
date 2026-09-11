import 'package:flutter/material.dart';

import '../../teacher/analysis/chord_shape_coach.dart';
import '../../teacher/models/hand_frame.dart';

/// Paints hand skeletons and finger guides over the camera preview.
class HandOverlayPainter extends CustomPainter {
  HandOverlayPainter({
    required this.frame,
    required this.shape,
    required this.leftHanded,
    this.frettingColor = const Color(0xFF7CF29A),
    this.strummingColor = const Color(0xFF7CC4FF),
    this.guideColor = const Color(0xFFFACC15),
  });

  final HandFrame frame;
  final ShapeFeedback shape;
  final bool leftHanded;
  final Color frettingColor;
  final Color strummingColor;
  final Color guideColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (!frame.hasHands || frame.imageWidth == 0 || frame.imageHeight == 0) {
      return;
    }
    // The preview uses BoxFit.cover; map normalised coords the same way.
    final scale = _coverScale(size);
    final drawW = frame.imageWidth * scale;
    final drawH = frame.imageHeight * scale;
    final dx = (size.width - drawW) / 2;
    final dy = (size.height - drawH) / 2;

    Offset map(HandLandmark l) {
      final x = frame.mirrored ? 1 - l.x : l.x;
      return Offset(dx + x * drawW, dy + l.y * drawH);
    }

    final fretting = leftHanded ? Handedness.right : Handedness.left;
    for (final hand in frame.hands) {
      final isFretting =
          hand.handedness == fretting ||
          (hand.handedness == Handedness.unknown && frame.hands.length == 1);
      final color = isFretting ? frettingColor : strummingColor;
      final bone = Paint()
        ..color = color.withValues(alpha: 0.75)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      for (final (a, b) in HandLandmarkIndex.connections) {
        canvas.drawLine(map(hand[a]), map(hand[b]), bone);
      }
      final joint = Paint()..color = color;
      for (final l in hand.landmarks) {
        canvas.drawCircle(map(l), 3.5, joint);
      }
    }

    // finger guides on the fretting hand
    for (final guide in shape.guides) {
      final at = map(guide.landmark);
      canvas.drawCircle(
        at,
        14,
        Paint()..color = guideColor.withValues(alpha: 0.25),
      );
      canvas.drawCircle(at, 9, Paint()..color = guideColor);
      _label(
        canvas,
        '${guide.finger}',
        at - const Offset(4.5, 8),
        const Color(0xFF0F172A),
        13,
        bold: true,
      );
      _pill(canvas, guide.label, at + const Offset(14, -10));
    }
  }

  double _coverScale(Size size) {
    final sx = size.width / frame.imageWidth;
    final sy = size.height / frame.imageHeight;
    return sx > sy ? sx : sy;
  }

  void _pill(Canvas canvas, String text, Offset at) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final rect = Rect.fromLTWH(
      at.dx,
      at.dy,
      painter.width + 12,
      painter.height + 6,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      Paint()..color = const Color(0xCC0F172A),
    );
    painter.paint(canvas, at + const Offset(6, 3));
  }

  void _label(
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
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, at);
  }

  @override
  bool shouldRepaint(covariant HandOverlayPainter old) =>
      old.frame != frame || old.shape != shape || old.leftHanded != leftHanded;
}
