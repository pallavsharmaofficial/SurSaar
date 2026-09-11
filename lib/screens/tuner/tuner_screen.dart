import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sursaar/l10n/app_localizations.dart';

import '../../core/theme/app_colors.dart';
import '../../teacher/analysis/tuner.dart';
import '../../teacher/models/audio_frame.dart';
import '../../teacher/services/audio_capture_service.dart';
import '../../teacher/services/sound_service.dart';
import '../../widgets/app_back_button.dart';

const Color _green = Color(0xFF22C55E);
const Color _amber = Color(0xFFF59E0B);
const Color _red = Color(0xFFEF4444);

/// Guitar tuner: listens through the microphone and shows how far each
/// string is from standard tuning.
class TunerScreen extends StatefulWidget {
  const TunerScreen({super.key, this.audioService, this.soundService});

  final AudioCaptureService? audioService;
  final TeacherSoundService? soundService;

  @override
  State<TunerScreen> createState() => _TunerScreenState();
}

class _TunerScreenState extends State<TunerScreen> {
  late final AudioCaptureService _audio =
      widget.audioService ?? createAudioCaptureService();
  late final TeacherSoundService _sound =
      widget.soundService ?? createTeacherSoundService();
  final PitchTracker _tracker = PitchTracker();
  StreamSubscription<AudioFrame>? _subscription;

  bool _listening = false;
  bool _starting = false;
  String? _error;
  GuitarString? _locked;
  TunerReading? _reading;
  int _lastUiMs = 0;
  int _ignoreUntilMs = 0;
  int _inTuneCount = 0;
  final Set<int> _tuned = <int>{};

  Future<void> _start() async {
    setState(() => _starting = true);
    final ok = await _audio.start();
    if (!mounted) return;
    setState(() {
      _starting = false;
      _listening = ok;
      _error = ok ? null : _audio.lastError;
    });
    if (ok) _subscription = _audio.frames.listen(_onAudio);
  }

  void _onAudio(AudioFrame frame) {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now < _ignoreUntilMs) return;
    final readings = _tracker.feed(frame, lockTo: _locked);
    if (readings.isNotEmpty) {
      final reading = readings.last;
      if (reading.inTune) {
        if (++_inTuneCount >= 6) _tuned.add(reading.string.index);
      } else {
        _inTuneCount = 0;
      }
      if (now - _lastUiMs >= 60 && mounted) {
        _lastUiMs = now;
        setState(() => _reading = reading);
      }
    } else if (_reading != null &&
        _tracker.lastReading == null &&
        now - _lastUiMs > 1200 &&
        mounted) {
      _lastUiMs = now;
      setState(() => _reading = null);
    }
  }

  void _playReference() {
    final string = _locked ?? _reading?.string ?? Tuner.standard.first;
    final duration = _sound.playNote(string.midi);
    _ignoreUntilMs =
        DateTime.now().millisecondsSinceEpoch + duration.inMilliseconds + 200;
    _tracker.reset();
  }

  void _lock(GuitarString? string) {
    setState(() {
      _locked = string;
      _reading = null;
      _inTuneCount = 0;
    });
    _tracker.reset();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _audio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        leading: const AppBackButton(),
        backgroundColor: AppColors.backgroundDark,
        title: Text(l10n.tunerTitle),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: <Widget>[
              Text(
                l10n.tunerHint,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textOnDark.withValues(alpha: 0.75),
                ),
              ),
              const SizedBox(height: 16),
              _TunerGauge(reading: _reading, listening: _listening),
              const SizedBox(height: 20),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  ChoiceChip(
                    label: Text(l10n.tunerAuto),
                    selected: _locked == null,
                    onSelected: (_) => _lock(null),
                  ),
                  for (final string in Tuner.standard)
                    ChoiceChip(
                      avatar: _tuned.contains(string.index)
                          ? const Icon(
                              Icons.check_circle,
                              color: _green,
                              size: 18,
                            )
                          : null,
                      label: Text(string.label),
                      selected:
                          _locked == string ||
                          (_locked == null &&
                              _reading?.string.index == string.index),
                      onSelected: (_) => _lock(string),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              if (!_listening)
                FilledButton.icon(
                  onPressed: _starting ? null : _start,
                  icon: const Icon(Icons.mic_rounded),
                  label: Text(l10n.tunerListen),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(52),
                  ),
                ).animate().fadeIn(duration: 300.ms),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(color: _amber),
                  ),
                ),
              if (_sound.canPlayChords)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: OutlinedButton.icon(
                    onPressed: _playReference,
                    icon: const Icon(Icons.volume_up_rounded),
                    label: Text(l10n.playReference),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white30),
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TunerGauge extends StatelessWidget {
  const _TunerGauge({required this.reading, required this.listening});

  final TunerReading? reading;
  final bool listening;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final r = reading;
    final cents = r?.centsFromString ?? 0;
    final color = r == null
        ? Colors.white38
        : r.inTune
        ? _green
        : cents.abs() <= 20
        ? _amber
        : _red;
    final status = r == null
        ? (listening ? l10n.tunerWaiting : '')
        : r.inTune
        ? l10n.inTune
        : r.isFlat
        ? l10n.tuneUp
        : l10n.tuneDown;
    final icon = r == null
        ? null
        : r.inTune
        ? Icons.check_rounded
        : r.isFlat
        ? Icons.arrow_upward_rounded
        : Icons.arrow_downward_rounded;
    return Column(
      children: <Widget>[
        AspectRatio(
          aspectRatio: 1.7,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(end: cents.clamp(-50, 50).toDouble()),
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            builder: (context, value, _) => CustomPaint(
              painter: _GaugePainter(
                cents: value,
                active: r != null,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            r == null ? '–' : '${r.noteName}${r.octave}',
            key: ValueKey<String>(r == null ? '-' : '${r.noteName}${r.octave}'),
            style: theme.textTheme.displayMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (r != null)
          Text(
            '${r.string.label} · ${r.frequency.toStringAsFixed(1)} Hz · '
            '${cents >= 0 ? '+' : ''}${cents.round()}¢',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.white60),
          ),
        const SizedBox(height: 12),
        AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: r == null ? 0.08 : 0.2),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: color.withValues(alpha: 0.7)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (icon != null) ...<Widget>[
                    Icon(icon, color: color),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    status.isEmpty ? ' ' : status,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: r == null ? Colors.white70 : color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )
            .animate(target: r?.inTune == true ? 1 : 0)
            .scaleXY(end: 1.1, duration: 250.ms, curve: Curves.easeOutBack),
      ],
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter({
    required this.cents,
    required this.active,
    required this.color,
  });

  final double cents;
  final bool active;
  final Color color;

  static const double _sweep = math.pi * 2 / 3;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.95);
    final radius = math.min(size.width / 2, size.height) * 0.88;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final start = -math.pi / 2 - _sweep / 2;

    canvas.drawArc(
      rect,
      start,
      _sweep,
      false,
      Paint()
        ..color = Colors.white12
        ..strokeWidth = 14
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
    final zone = _sweep * (10 / 100);
    canvas.drawArc(
      rect,
      -math.pi / 2 - zone / 2,
      zone,
      false,
      Paint()
        ..color = _green.withValues(alpha: 0.7)
        ..strokeWidth = 14
        ..style = PaintingStyle.stroke,
    );
    for (var c = -50; c <= 50; c += 10) {
      final angle = -math.pi / 2 + _sweep * c / 100;
      final direction = Offset(math.cos(angle), math.sin(angle));
      canvas.drawLine(
        center + direction * (radius - 20),
        center + direction * (radius - (c == 0 ? 38 : 28)),
        Paint()
          ..color = Colors.white38
          ..strokeWidth = c == 0 ? 3 : 1.5,
      );
    }
    if (!active) return;
    final angle = -math.pi / 2 + _sweep * cents.clamp(-50, 50) / 100;
    final tip =
        center + Offset(math.cos(angle), math.sin(angle)) * (radius - 6);
    canvas.drawLine(
      center,
      tip,
      Paint()
        ..color = color
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(center, 9, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _GaugePainter old) =>
      old.cents != cents || old.active != active || old.color != color;
}
