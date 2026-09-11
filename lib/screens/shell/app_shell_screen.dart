import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sursaar/l10n/app_localizations.dart';

/// Bottom navigation on phones, a navigation rail on wide screens (web).
class AppShellScreen extends StatelessWidget {
  const AppShellScreen({super.key, required this.child});

  final Widget child;

  static const List<String> _paths = <String>[
    '/home',
    '/learn',
    '/progress',
    '/profile',
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final index = _selectedIndex(context);
    final labels = <String>[l10n.home, l10n.learn, l10n.progress, l10n.profile];
    const icons = <IconData>[
      Icons.home_outlined,
      Icons.school_outlined,
      Icons.trending_up_outlined,
      Icons.person_outline,
    ];
    const selectedIcons = <IconData>[
      Icons.home,
      Icons.school,
      Icons.trending_up,
      Icons.person,
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 800;
        if (wide) {
          return Scaffold(
            body: Row(
              children: <Widget>[
                NavigationRail(
                  selectedIndex: index,
                  extended: constraints.maxWidth >= 1200,
                  onDestinationSelected: (i) => context.go(_paths[i]),
                  leading: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Icon(
                      Icons.music_note,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  destinations: <NavigationRailDestination>[
                    for (var i = 0; i < labels.length; i++)
                      NavigationRailDestination(
                        icon: Icon(icons[i]),
                        selectedIcon: Icon(selectedIcons[i]),
                        label: Text(labels[i]),
                      ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1100),
                      child: child,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        return Scaffold(
          body: child,
          bottomNavigationBar: NavigationBar(
            selectedIndex: index,
            onDestinationSelected: (i) => context.go(_paths[i]),
            destinations: <NavigationDestination>[
              for (var i = 0; i < labels.length; i++)
                NavigationDestination(
                  icon: Icon(icons[i]),
                  selectedIcon: Icon(selectedIcons[i]),
                  label: labels[i],
                ),
            ],
          ),
        );
      },
    );
  }

  int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    for (var i = 0; i < _paths.length; i++) {
      if (location.startsWith(_paths[i])) return i;
    }
    return 0;
  }
}
