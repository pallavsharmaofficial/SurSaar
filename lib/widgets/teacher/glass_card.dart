import 'package:flutter/material.dart';

/// Dark translucent card used over the camera preview.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    this.color = const Color(0xCC0F172A),
    this.borderColor = Colors.white12,
    this.radius = 14,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final Color borderColor;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor),
      ),
      child: child,
    );
  }
}
