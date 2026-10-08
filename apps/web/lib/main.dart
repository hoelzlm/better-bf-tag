import 'package:bftag_core/bftag_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router.dart';
import 'url_strategy_stub.dart'
    if (dart.library.js_interop) 'url_strategy_web.dart'
    if (dart.library.html) 'url_strategy_web.dart' as url_strategy;

void main() {
  url_strategy.configureUrlStrategy();
  runApp(const ProviderScope(child: BftagWebApp()));
}

class BftagWebApp extends ConsumerStatefulWidget {
  const BftagWebApp({super.key});

  @override
  ConsumerState<BftagWebApp> createState() => _BftagWebAppState();
}

class _BftagWebAppState extends ConsumerState<BftagWebApp> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(sessionControllerProvider.notifier).restore(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(goRouterProvider);
    return MaterialApp.router(
      title: 'BF-Tag',
      theme: bftagTheme(),
      routerConfig: router,
    );
  }
}
