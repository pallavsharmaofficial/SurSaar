import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sursaar/l10n/app_localizations.dart';

/// Leaves the current screen: pops when there is somewhere to go back to,
/// otherwise (a deep link opened directly, e.g. from the website) goes home.
void popOrGoHome(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go('/home');
  }
}

/// App bar leading button for screens outside the navigation shell.
class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    final canPop = context.canPop();
    return IconButton(
      tooltip: canPop
          ? MaterialLocalizations.of(context).backButtonTooltip
          : AppLocalizations.of(context)!.home,
      icon: Icon(canPop ? Icons.arrow_back : Icons.home_outlined),
      onPressed: () => popOrGoHome(context),
    );
  }
}
