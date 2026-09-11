import 'dart:math' as math;

import 'package:flutter/material.dart';

const List<Color> _burstColors = <Color>[
  Color(0xFF22C55E),
  Color(0xFFFACC15),
  Color(0xFF3B82F6),
  Color(0xFFEC4899),
  Color(0xFFF97316),
  Color(0xFFFFFFFF),
];

/// A burst of particles and an expanding ring, fired whenever [trigger]
/// changes to a new positive value.
class CelebrationBurst extends StatefulWidget {
  const CelebrationBurst({
    super.key,
    required this.trigger,
    this.particles = 28,
    this.spread = 1,
    this.duration = const Duration(milliseconds: 950),
  });

  final int trigger;
  final int particles;

  /// Multiplies how far particles fly (1 = card sized).
  final double spread;
  final Duration duration;

  @override
  State<CelebrationBurst> createState() => _CelebrationBurstState();
}

class _CelebrationBurstState extends State<CelebrationBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  List<_Particle> _particles = const <_Particle>[];

  @override
  void initState() {
    super.initState();
    if (widget.trigger > 0) _fire();
  }

  @override
  void didUpdateWidget(covariant CelebrationBurst oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger != oldWidget.trigger && widget.trigger > 0) _fire();
  }

  void _fire() {
    final random = math.Random(widget.trigger);
    _particles = List<_Particle>.generate(widget.particles, (i) {
      final angle = random.nextDouble() * math.pi * 2;
      return _Particle(
        angle: angle,
        speed: (0.35 + random.nextDouble() * 0.65) * widget.spread,
        size: 3 + random.nextDouble() * 5,
        color: _burstColors[i % _burstColors.length],
        spin: random.nextDouble() * 6 - 3,
        square: random.nextBool(),
      );
    });
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _BurstPainter(_controller, _particles),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _Particle {
  const _Particle({
    required this.angle,
    required this.speed,
    required this.size,
    required this.color,
    required this.spin,
    required this.square,
  });

  final double angle;
  final double speed;
  final double size;
  final Color color;
  final double spin;
  final bool square;
}

class _BurstPainter extends CustomPainter {
  _BurstPainter(this.animation, this.particles) : super(repaint: animation);

  final Animation<double> animation;
  final List<_Particle> particles;

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value;
    if (t <= 0 || t >= 1 || particles.isEmpty) return;
    final center = size.center(Offset.zero);
    final reach = size.shortestSide * 0.6;
    final eased = Curves.easeOutCubic.transform(t);
    final fade = 1 - Curves.easeIn.transform(t);

    canvas.drawCircle(
      center,
      reach * 0.2 + reach * 0.5 * eased,
      Paint()
        ..color = const Color(0xFF22C55E).withValues(alpha: 0.35 * fade)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6 * fade + 1,
    );

    for (final p in particles) {
      final distance = reach * p.speed * eased;
      final position =
          center +
          Offset(math.cos(p.angle), math.sin(p.angle)) * distance +
          Offset(0, 40 * t * t);
      final paint = Paint()..color = p.color.withValues(alpha: fade);
      if (p.square) {
        canvas.save();
        canvas.translate(position.dx, position.dy);
        canvas.rotate(p.spin * t);
        canvas.drawRect(
          Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size),
          paint,
        );
        canvas.restore();
      } else {
        canvas.drawCircle(position, p.size / 2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BurstPainter old) => old.particles != particles;
}

/// Shakes its child sideways whenever [trigger] changes to a new value.
class ShakeOnTrigger extends StatefulWidget {
  const ShakeOnTrigger({super.key, required this.trigger, required this.child});

  final int trigger;
  final Widget child;

  @override
  State<ShakeOnTrigger> createState() => _ShakeOnTriggerState();
}

class _ShakeOnTriggerState extends State<ShakeOnTrigger>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  @override
  void didUpdateWidget(covariant ShakeOnTrigger oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger != oldWidget.trigger && widget.trigger > 0) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final t = _controller.value;
        final dx = math.sin(t * math.pi * 6) * 10 * (1 - t);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
    );
  }
}

/// A circular progress ring that animates to [value].
class HoldRing extends StatelessWidget {
  const HoldRing({
    super.key,
    required this.value,
    required this.child,
    this.color = const Color(0xFF22C55E),
    this.strokeWidth = 5,
    this.padding = 6,
  });

  final double value;
  final Widget child;
  final Color color;
  final double strokeWidth;
  final double padding;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: value.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 180),
      builder: (context, animated, child) => CustomPaint(
        foregroundPainter: _RingPainter(animated, color, strokeWidth),
        child: Padding(padding: EdgeInsets.all(padding), child: child),
      ),
      child: child,
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.value, this.color, this.strokeWidth);

  final double value;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    if (value <= 0) return;
    final rect = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(strokeWidth / 2),
      const Radius.circular(16),
    );
    final path = Path()..addRRect(rect);
    final metric = path.computeMetrics().first;
    canvas.drawPath(
      metric.extractPath(0, metric.length * value),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.value != value || old.color != color;
}

/// Five bars that light up with the microphone level.
class LevelMeter extends StatelessWidget {
  const LevelMeter({
    super.key,
    required this.level,
    this.bars = 5,
    this.height = 18,
    this.color = const Color(0xFF22C55E),
  });

  final double level;
  final int bars;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List<Widget>.generate(bars, (i) {
        final threshold = (i + 1) / (bars + 1);
        final on = level >= threshold;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: 4,
          height: height * (0.35 + 0.65 * (i + 1) / bars),
          margin: const EdgeInsets.only(right: 2),
          decoration: BoxDecoration(
            color: on ? color : Colors.white24,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }
}

/// Up to three stars that pop in one after another.
class StarRating extends StatelessWidget {
  const StarRating({super.key, required this.stars, this.size = 40});

  final int stars;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List<Widget>.generate(3, (i) {
        final filled = i < stars;
        return TweenAnimationBuilder<double>(
          key: ValueKey<String>('star-$i-$stars'),
          tween: Tween<double>(begin: 0, end: 1),
          duration: Duration(milliseconds: 500 + i * 250),
          curve: Interval(i * 0.3, 1, curve: Curves.elasticOut),
          builder: (context, value, child) =>
              Transform.scale(scale: filled ? value : 1, child: child),
          child: Icon(
            filled ? Icons.star_rounded : Icons.star_outline_rounded,
            size: i == 1 ? size * 1.25 : size,
            color: filled ? const Color(0xFFFACC15) : Colors.white38,
          ),
        );
      }),
    );
  }
}
