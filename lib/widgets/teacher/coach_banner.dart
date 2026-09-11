import 'package:flutter/material.dart';

import '../../teacher/engine/teacher_engine.dart';

class CoachBanner extends StatelessWidget {
  const CoachBanner({super.key, required this.message});

  final CoachMessage? message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final msg = message;
    final (Color bg, IconData icon) = switch (msg?.tone) {
      CoachTone.good => (const Color(0xFF16A34A), Icons.check_circle),
      CoachTone.warn => (const Color(0xFFD97706), Icons.tips_and_updates),
      _ => (const Color(0xFF2D31FA), Icons.record_voice_over),
    };
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: msg == null
          ? const SizedBox.shrink()
          : Container(
              key: ValueKey<String>('${msg.atMs}-${msg.text}'),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: bg.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(icon, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      msg.text,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
