import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../data/content/chord_library.dart';

/// Notes and ripples that rise out of the guitar while it is being played.
///
/// The anchor is the body of the guitar, worked out from the learner's hands,
/// so the music really does appear to come out of the instrument. Motion is
/// driven by the microphone level and by each strum.
class SoundFieldOverlay extends StatefulWidget {
  const SoundFieldOverlay({
    super.key,
    required this.anchor,
    required this.imageWidth,
    required this.imageHeight,
    this.mirrored = true,
    this.intensity = 0,
    this.strumId = 0,
    this.chord,
    this.angle = 0,
    this.active = true,
  });

  /// Guitar body in normalised image coordinates.
  final Offset anchor;
  final int imageWidth;
  final int imageHeight;
  final bool mirrored;

  /// Microphone level, 0..1.
  final double intensity;

  /// Increases on every strum.
  final int strumId;
  final String? chord;

  /// Neck angle in radians; notes drift away from the neck.
  final double angle;
  final bool active;

  @override
  State<SoundFieldOverlay> createState() => _SoundFieldOverlayState();
}

class _SoundFieldOverlayState extends State<SoundFieldOverlay>
    with SingleTickerProviderStateMixin {
  final _Field _field = _Field();
  late final Ticker _ticker = createTicker(_tick);
  Duration _last = Duration.zero;

  @override
  void initState() {
    super.initState();
    if (widget.active) _ticker.start();
  }

  @override
  void didUpdateWidget(covariant SoundFieldOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_ticker.isActive) {
      _last = Duration.zero;
      _ticker.start();
    } else if (!widget.active && _ticker.isActive) {
      _ticker.stop();
      _field.clear();
    }
    if (widget.strumId != oldWidget.strumId && widget.active) {
      _field.strum(_color, _seed);
    }
  }

  Color get _color {
    final chord = widget.chord;
    if (chord == null || chord.isEmpty) return const Color(0xFF7CC4FF);
    final root = ChordLibrary.rootIndex(ChordLibrary.normalizeName(chord));
    final hue = ((root < 0 ? 0 : root) * 30).toDouble();
    return HSLColor.fromAHSL(1, hue, 0.75, 0.62).toColor();
  }

  int get _seed => widget.strumId * 7919 + widget.anchor.dx.hashCode;

  void _tick(Duration elapsed) {
    final dt = _last == Duration.zero
        ? 0.016
        : ((elapsed - _last).inMicroseconds / 1e6).clamp(0.001, 0.05);
    _last = elapsed;
    _field.update(
      dt: dt,
      intensity: widget.intensity,
      color: _color,
      angle: widget.angle,
      seed: _seed,
    );
  }

  @override
  void dispose() {
    _ticker.dispose();
    _field.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) return const SizedBox.shrink();
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _SoundFieldPainter(
            field: _field,
            anchor: widget.anchor,
            imageWidth: widget.imageWidth,
            imageHeight: widget.imageHeight,
            mirrored: widget.mirrored,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _Note {
  _Note({
    required this.offset,
    required this.velocity,
    required this.color,
    required this.size,
    required this.spin,
    required this.life,
  });

  Offset offset; // relative to the anchor, in screen fractions
  Offset velocity;
  final Color color;
  final double size;
  final double spin;
  double life;
  double age = 0;

  double get t => (age / life).clamp(0.0, 1.0);
}

class _Ripple {
  _Ripple(this.color);

  final Color color;
  double age = 0;
}

/// Holds the live particles; repaints without rebuilding the widget tree.
class _Field extends ChangeNotifier {
  final List<_Note> notes = <_Note>[];
  final List<_Ripple> ripples = <_Ripple>[];
  double _spawnCarry = 0;
  math.Random _random = math.Random(1);

  void clear() {
    notes.clear();
    ripples.clear();
    notifyListeners();
  }

  void strum(Color color, int seed) {
    _random = math.Random(seed);
    ripples.add(_Ripple(color));
    for (var i = 0; i < 10; i++) {
      _spawn(color, 1.4);
    }
    notifyListeners();
  }

  void _spawn(Color color, double push) {
    if (notes.length > 70) return;
    final spread = (_random.nextDouble() - 0.5) * 1.5;
    final speed = (0.16 + _random.nextDouble() * 0.22) * push;
    notes.add(
      _Note(
        offset: Offset(
          (_random.nextDouble() - 0.5) * 0.04,
          (_random.nextDouble() - 0.5) * 0.04,
        ),
        // upwards, fanned out to the sides
        velocity: Offset(math.sin(spread) * speed * 0.8, -speed),
        color: color,
        size: 10 + _random.nextDouble() * 14,
        spin: (_random.nextDouble() - 0.5) * 2.4,
        life: 1.1 + _random.nextDouble() * 0.9,
      ),
    );
  }

  void update({
    required double dt,
    required double intensity,
    required Color color,
    required double angle,
    required int seed,
  }) {
    // a steady trickle while the guitar is ringing
    if (intensity > 0.12) {
      _spawnCarry += dt * (2 + intensity * 14);
      while (_spawnCarry >= 1) {
        _spawnCarry -= 1;
        _spawn(color, 0.7 + intensity * 0.8);
      }
    }
    for (final note in notes) {
      note.age += dt;
      note.velocity = Offset(
        note.velocity.dx + math.cos(angle) * dt * 0.02,
        note.velocity.dy + dt * 0.05, // gentle gravity
      );
      note.offset += note.velocity * dt;
    }
    notes.removeWhere((note) => note.age >= note.life);
    for (final ripple in ripples) {
      ripple.age += dt;
    }
    ripples.removeWhere((ripple) => ripple.age > 1.1);
    notifyListeners();
  }
}

class _SoundFieldPainter extends CustomPainter {
  _SoundFieldPainter({
    required this.field,
    required this.anchor,
    required this.imageWidth,
    required this.imageHeight,
    required this.mirrored,
  }) : super(repaint: field);

  final _Field field;
  final Offset anchor;
  final int imageWidth;
  final int imageHeight;
  final bool mirrored;

  Offset _map(Size size) {
    if (imageWidth == 0 || imageHeight == 0) {
      return Offset(size.width * anchor.dx, size.height * anchor.dy);
    }
    final scale = math.max(size.width / imageWidth, size.height / imageHeight);
    final drawWidth = imageWidth * scale;
    final drawHeight = imageHeight * scale;
    final dx = (size.width - drawWidth) / 2;
    final dy = (size.height - drawHeight) / 2;
    final x = mirrored ? 1 - anchor.dx : anchor.dx;
    return Offset(dx + x * drawWidth, dy + anchor.dy * drawHeight);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final origin = _map(size);

    for (final ripple in field.ripples) {
      final t = (ripple.age / 1.1).clamp(0.0, 1.0);
      final radius =
          size.shortestSide * (0.06 + 0.35 * Curves.easeOut.transform(t));
      canvas.drawCircle(
        origin,
        radius,
        Paint()
          ..color = ripple.color.withValues(alpha: 0.35 * (1 - t))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8 * (1 - t) + 1,
      );
    }

    for (final note in field.notes) {
      final t = note.t;
      // grows as it "comes towards" the viewer, then fades
      final depth = 0.65 + t * 0.9;
      final alpha = t < 0.15 ? t / 0.15 : (1 - (t - 0.15) / 0.85);
      final position =
          origin +
          Offset(note.offset.dx * size.width, note.offset.dy * size.height);
      final paint = Paint()
        ..color = note.color.withValues(alpha: alpha.clamp(0.0, 1.0) * 0.9);
      final radius = note.size * depth * 0.35;
      canvas.save();
      canvas.translate(position.dx, position.dy);
      canvas.rotate(note.spin * t);
      // note head
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: radius * 2.2,
          height: radius * 1.7,
        ),
        paint,
      );
      // stem and flag
      canvas.drawRect(
        Rect.fromLTWH(radius * 0.7, -radius * 3.2, radius * 0.34, radius * 3.2),
        paint,
      );
      final flag = Path()
        ..moveTo(radius * 1.04, -radius * 3.2)
        ..quadraticBezierTo(
          radius * 2.2,
          -radius * 2.6,
          radius * 1.04,
          -radius * 1.7,
        );
      canvas.drawPath(flag, paint);
      canvas.restore();
    }

    // soft glow at the sound hole
    if (field.notes.isNotEmpty) {
      canvas.drawCircle(
        origin,
        size.shortestSide * 0.07,
        Paint()
          ..color = field.notes.last.color.withValues(alpha: 0.18)
          ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 18),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SoundFieldPainter old) =>
      old.anchor != anchor || old.mirrored != mirrored;
}
