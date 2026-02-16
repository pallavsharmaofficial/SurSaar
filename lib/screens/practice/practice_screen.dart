import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:sursaar/l10n/app_localizations.dart';
import '../../blocs/practice/practice_bloc.dart';
import '../../blocs/practice/practice_event.dart';
import '../../blocs/practice/practice_state.dart';
import '../../core/theme/app_colors.dart';
import '../../repositories/practice_repository.dart';
import '../../repositories/progress_repository.dart';

class PracticeScreen extends StatefulWidget {
  const PracticeScreen({
    super.key,
    required this.songId,
  });

  final String songId;

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  bool _isRecording = false;
  double _accuracy = 0.0;
  int _chordsPlayed = 0;
  int _mistakes = 0;
  DateTime? _startTime;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return BlocProvider(
      create: (_) => PracticeBloc(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.practiceMode),
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () {
                _showInfoDialog(context);
              },
            ),
          ],
        ),
        body: Stack(
          children: <Widget>[
            Container(
              color: AppColors.backgroundDark,
              child: Center(
                child: Icon(
                  Icons.videocam,
                  size: 120,
                  color: AppColors.surfaceLight.withValues(alpha: 0.2),
                ),
              ),
            ),
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.4),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: <Widget>[
                    BlocBuilder<PracticeBloc, PracticeState>(
                      builder: (context, state) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.primary,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    l10n.chords,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: AppColors.textOnLight,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    state.activeChord,
                                    style: theme.textTheme.headlineSmall?.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              SvgPicture.asset(
                                'assets/images/ai_vision_scanner.svg',
                                width: 36,
                                height: 36,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    BlocBuilder<PracticeBloc, PracticeState>(
                      builder: (context, state) {
                        return SizedBox(
                          height: 180,
                          child: CustomPaint(
                            painter: _AccuracyMeterPainter(
                              accuracy: state.accuracy,
                            ),
                            child: Center(
                              child: Text(
                                '${state.accuracy.toStringAsFixed(0)}%',
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  color: AppColors.surfaceLight,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const Spacer(),
                    BlocBuilder<PracticeBloc, PracticeState>(
                      builder: (context, state) {
                        final isListening =
                            state.status == PracticeStatus.listening;
                        return Column(
                          children: <Widget>[
                            SvgPicture.asset(
                              'assets/images/mic_ai.svg',
                              width: 64,
                              height: 64,
                              colorFilter: ColorFilter.mode(
                                isListening
                                    ? AppColors.secondary
                                    : AppColors.surfaceLight,
                                BlendMode.srcIn,
                              ),
                            )
                                .animate(
                                  onPlay: (controller) {
                                    if (isListening) {
                                      controller.repeat();
                                    }
                                  },
                                )
                                .scale(
                                  duration: 1000.ms,
                                  begin: const Offset(1, 1),
                                  end: const Offset(1.08, 1.08),
                                ),
                            const SizedBox(height: 16),
                            Text(
                              isListening ? l10n.listening : l10n.tapToStart,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: AppColors.surfaceLight,
                              ),
                            ),
                            const SizedBox(height: 24),
                            FilledButton.icon(
                              onPressed: () {
                                setState(() {
                                  _isRecording = !_isRecording;
                                  if (_isRecording) {
                                    _startTime = DateTime.now();
                                    context
                                        .read<PracticeBloc>()
                                        .add(const PracticeStarted());
                                    _simulateAIPractice();
                                  } else {
                                    _startTime = _startTime ?? DateTime.now();
                                    context
                                        .read<PracticeBloc>()
                                        .add(const PracticeStopped());
                                  }
                                });
                              },
                              icon: Icon(
                                isListening ? Icons.stop : Icons.play_arrow,
                              ),
                              label: Text(
                                isListening
                                    ? l10n.stopPractice
                                    : l10n.startPractice,
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: AppColors.surfaceLight,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 16,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (!isListening && _chordsPlayed > 0)
                              TextButton(
                                onPressed: _savePracticeSession,
                                child: Text(
                                  l10n.savePractice,
                                  style: const TextStyle(
                                    color: AppColors.surfaceLight,
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _simulateAIPractice() {
    // Placeholder simulation - in real app this would use ML
    Future.delayed(const Duration(seconds: 2), () {
      if (_isRecording && mounted) {
        setState(() {
          _chordsPlayed++;
          _accuracy = (_accuracy * (_chordsPlayed - 1) + 85) / _chordsPlayed;
          if (_accuracy < 90) _mistakes++;
        });
        context
            .read<PracticeBloc>()
            .add(PracticeAccuracyUpdated(_accuracy));
        context.read<PracticeBloc>().add(
              PracticeChordDetected(
                _chordsPlayed % 2 == 0 ? 'G' : 'C',
              ),
            );
        _simulateAIPractice();
      }
    });
  }

  void _showInfoDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.comingSoon),
        content: Text(l10n.aiFeatureDescription),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
  }

  Future<void> _savePracticeSession() async {
    final startTime = _startTime ?? DateTime.now();
    final duration = DateTime.now().difference(startTime).inSeconds;
    final practiceRepository = context.read<PracticeRepository>();
    final progressRepository = context.read<ProgressRepository>();

    final session = practiceRepository.createSession(
      songId: widget.songId,
      startTime: startTime,
      duration: duration,
      accuracy: _accuracy,
      chordsPlayed: _chordsPlayed,
      mistakes: _mistakes,
    );

    await practiceRepository.saveSession(session);
    await progressRepository.recordPracticeSession(
      durationInSeconds: duration,
      accuracy: _accuracy,
    );

    if (mounted) {
      context.pop();
    }
  }
}

class _AccuracyMeterPainter extends CustomPainter {
  _AccuracyMeterPainter({
    required this.accuracy,
  });

  final double accuracy;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.35;

    final backgroundPaint = Paint()
      ..color = AppColors.surfaceLight.withValues(alpha: 0.2)
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = AppColors.secondary
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const startAngle = -3.14 * 0.75;
    const sweepAngle = 3.14 * 1.5;
    final progressAngle = sweepAngle * (accuracy.clamp(0, 100) / 100);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      backgroundPaint,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      progressAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _AccuracyMeterPainter oldDelegate) {
    return oldDelegate.accuracy != accuracy;
  }
}
