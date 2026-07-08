import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router/app_router.dart';
import 'theme/app_theme.dart';
import '../features/auth/providers/auth_providers.dart';

class SmartKashApp extends ConsumerStatefulWidget {
  const SmartKashApp({super.key});

  @override
  ConsumerState<SmartKashApp> createState() => _SmartKashAppState();
}

class _SmartKashAppState extends ConsumerState<SmartKashApp> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(authControllerProvider.notifier).restoreSession(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'SmartKash',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}
