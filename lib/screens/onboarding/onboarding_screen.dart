import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sursaar/l10n/app_localizations.dart';

import '../../core/theme/app_colors.dart';
import '../../repositories/settings_repository.dart';
import '../../widgets/app_back_button.dart';
import '../../widgets/teacher/finger_colors.dart';

/// Three friendly cards shown the first time the app opens.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _page = 0;

  Future<void> _finish() async {
    final repository = context.read<SettingsRepository>();
    final settings = await repository.getSettings();
    await repository.saveSettings(settings.copyWith(onboardingSeen: true));
    if (!mounted) return;
    popOrGoHome(context);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pages = <_PageData>[
      _PageData(
        icon: Icons.library_music_rounded,
        colors: const <Color>[AppColors.primary, Color(0xFF7C3AED)],
        title: l10n.onboardingTitle1,
        body: l10n.onboardingBody1,
      ),
      _PageData(
        icon: Icons.back_hand_rounded,
        colors: const <Color>[Color(0xFF16A34A), Color(0xFF0D9488)],
        title: l10n.onboardingTitle2,
        body: l10n.onboardingBody2,
        showFingers: true,
      ),
      _PageData(
        icon: Icons.self_improvement_rounded,
        colors: const <Color>[Color(0xFFF97316), Color(0xFFEC4899)],
        title: l10n.onboardingTitle3,
        body: l10n.onboardingBody3,
      ),
    ];
    final last = _page == pages.length - 1;
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _finish,
                child: Text(
                  l10n.skip,
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: pages.length,
                onPageChanged: (page) => setState(() => _page = page),
                itemBuilder: (context, index) =>
                    _OnboardingPage(data: pages[index]),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List<Widget>.generate(pages.length, (i) {
                final active = i == _page;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: active ? 24 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: active ? AppColors.primary : Colors.white24,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: FilledButton(
                onPressed: last
                    ? _finish
                    : () => _controller.nextPage(
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOutCubic,
                      ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    last ? l10n.getStarted : l10n.next,
                    key: ValueKey<bool>(last),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _PageData {
  const _PageData({
    required this.icon,
    required this.colors,
    required this.title,
    required this.body,
    this.showFingers = false,
  });

  final IconData icon;
  final List<Color> colors;
  final String title;
  final String body;
  final bool showFingers;
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.data});

  final _PageData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
                  width: 170,
                  height: 170,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: data.colors,
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: data.colors.first.withValues(alpha: 0.4),
                        blurRadius: 40,
                      ),
                    ],
                  ),
                  child: Icon(data.icon, size: 84, color: Colors.white),
                )
                .animate()
                .scale(
                  begin: const Offset(0.6, 0.6),
                  curve: Curves.elasticOut,
                  duration: 900.ms,
                )
                .fadeIn(duration: 250.ms),
            if (data.showFingers) ...<Widget>[
              const SizedBox(height: 18),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  for (var finger = 1; finger <= 4; finger++)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child:
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: FingerColors.of(finger),
                            child: Text(
                              '$finger',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ).animate().scale(
                            delay: (300 + finger * 120).ms,
                            curve: Curves.elasticOut,
                            duration: 700.ms,
                          ),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 32),
            Text(
              data.title,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.2),
            const SizedBox(height: 12),
            Text(
              data.body,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white70),
            ).animate().fadeIn(delay: 300.ms),
          ],
        ),
      ),
    );
  }
}
