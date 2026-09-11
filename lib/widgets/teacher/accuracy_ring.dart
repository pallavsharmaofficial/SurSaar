import 'dart:math' as math;

import 'package:flutter/material.dart';

class AccuracyRing extends StatelessWidget {
  const AccuracyRing({
    super.key,
    required this.value,
    required this.label,
    this.size = 84,
    this.color,
    this.background,
  });

  /// 0..1
  final double value;
  final String label;
  final double size;
  final Color? color;

  /// Optional disc behind the ring (for use over the camera).
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ringColor =
        color ??
        (value >= 0.8
            ? const Color(0xFF22C55E)
            : value >= 0.5
            ? const Color(0xFFFACC15)
            : const Color(0xFFF87171));
    return Container(
      width: size,
      height: size,
      decoration: background == null
          ? null
          : BoxDecoration(color: background, shape: BoxShape.circle),
      child: CustomPaint(
        painter: _RingPainter(value: value, color: ringColor),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                '${(value * 100).round()}%',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.value, required this.color});

  final double value;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;
    final bg = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..strokeWidth = 7
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final fg = Paint()
      ..color = color
      ..strokeWidth = 7
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    const start = -math.pi * 0.75;
    const sweep = math.pi * 1.5;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      start,
      sweep,
      false,
      bg,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      start,
      sweep * value.clamp(0.0, 1.0),
      false,
      fg,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.value != value || old.color != color;
}
