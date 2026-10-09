import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Bottom navigation shared by the app's two top-level screens: "Mein
/// Fahrzeug" (`/`) and "Einsätze" (`/einsaetze`). Settings stay reachable
/// via the AppBar action on each screen (unchanged).
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
      ],
      onDestinationSelected: (index) {
        if (index == currentIndex) return;
        context.go(index == 0 ? '/' : '/einsaetze');
      },
    );
  }
}
