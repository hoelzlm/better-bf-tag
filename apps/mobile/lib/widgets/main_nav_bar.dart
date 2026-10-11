import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Bottom navigation shared by the app's three top-level screens: "Mein
/// Fahrzeug" (`/`), "Einsätze" (`/einsaetze`) and "Durchsagen"
/// (`/durchsagen`, ADR 0024). Settings stay reachable via the AppBar
/// action on each screen (unchanged).
class MainNavBar extends StatelessWidget {
  const MainNavBar({super.key, required this.currentIndex});

  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      key: const Key('main-nav-bar'),
      selectedIndex: currentIndex,
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
        }
      },
    );
  }
}
