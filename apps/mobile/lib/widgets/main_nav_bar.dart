import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Bottom navigation shared by the app's four top-level screens: "Mein
/// Fahrzeug" (`/`), "Einsätze" (`/einsaetze`), "Durchsagen"
/// (`/durchsagen`, ADR 0024) and "Ablauf" (`/tagesablauf`, ADR 0025).
/// Settings stay reachable via the AppBar action on each screen
/// (unchanged). Token-styled per `docs/design/screens/app-navigation.md`
/// §3: `surfaceVariant` surface (theme `navigationBarTheme`), 1px
/// `outline` divider on top, no shadow/elevation tint (ADR 0027), labels
/// always shown, no badge (ADR 0027 — no data source for unread state).
class MainNavBar extends StatelessWidget {
  const MainNavBar({super.key, required this.currentIndex});

  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    final outline = Theme.of(context).colorScheme.outline;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: outline, width: 1)),
      ),
      child: NavigationBar(
        key: const Key('main-nav-bar'),
        selectedIndex: currentIndex,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            key: Key('nav-my-vehicle'),
            icon: Icon(Icons.local_shipping_outlined),
            selectedIcon: Icon(Icons.local_shipping),
            label: 'Fahrzeug',
          ),
          NavigationDestination(
            key: Key('nav-incidents'),
            icon: Icon(Icons.campaign_outlined),
            selectedIcon: Icon(Icons.campaign),
            label: 'Einsätze',
          ),
          NavigationDestination(
            key: Key('nav-announcements'),
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Durchsagen',
          ),
          NavigationDestination(
            key: Key('nav-program'),
            icon: Icon(Icons.schedule_outlined),
            selectedIcon: Icon(Icons.schedule),
            label: 'Ablauf',
          ),
        ],
        onDestinationSelected: (index) {
          if (index == currentIndex) return;
          switch (index) {
            case 0:
              context.go('/');
            case 1:
              context.go('/einsaetze');
            case 2:
              context.go('/durchsagen');
            case 3:
              context.go('/tagesablauf');
          }
        },
      ),
    );
  }
}
