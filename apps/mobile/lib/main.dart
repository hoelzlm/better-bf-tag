import 'package:bftag_core/bftag_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'alarm/alarm_navigation_listener.dart';
import 'announcements/announcement_snackbar_listener.dart';
import 'push/push_registrar.dart';
import 'router.dart';
import 'secure_token_store.dart';

void main() {
  runApp(
    ProviderScope(
      overrides: [
        tokenStoreProvider.overrideWithValue(SecureTokenStore()),
        authSessionBindingProvider.overrideWith(
          (ref) => ref.watch(pairedSessionAuthBindingProvider),
        ),
      ],
      child: const BftagMobileApp(),
    ),
  );
}

class BftagMobileApp extends ConsumerStatefulWidget {
  const BftagMobileApp({super.key});

  @override
  ConsumerState<BftagMobileApp> createState() => _BftagMobileAppState();
}

class _BftagMobileAppState extends ConsumerState<BftagMobileApp> {
  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(pairedSessionControllerProvider.notifier).restore(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(mobileGoRouterProvider);
    return PushRegistrar(
      router: router,
      child: AlarmNavigationListener(
        router: router,
        child: AnnouncementSnackbarListener(
          messengerKey: _scaffoldMessengerKey,
          router: router,
          child: MaterialApp.router(
            title: 'BF-Tag',
            scaffoldMessengerKey: _scaffoldMessengerKey,
            theme: bftagLightTheme(),
            darkTheme: bftagDarkTheme(),
            themeMode: ThemeMode.system,
            routerConfig: router,
          ),
        ),
      ),
    );
  }
}
