import 'package:flutter/material.dart';

import 'smartkash_bottom_nav.dart';

class SmartKashShell extends StatelessWidget {
  const SmartKashShell({
    required this.child,
    required this.currentPath,
    super.key,
  });

  final Widget child;
  final String currentPath;

  @override
  Widget build(BuildContext context) {
    final hideBottomNav = _hideBottomNavForPath(currentPath);
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: child,
      bottomNavigationBar:
          hideBottomNav ? null : SmartKashBottomNav(currentPath: currentPath),
    );
  }

  bool _hideBottomNavForPath(String path) {
    const fullScreenFlowPaths = {
      '/add-money',
      '/send-money',
      '/cash-out',
      '/merchant-payment',
      '/pay-bill',
      '/mobile-recharge',
      '/savings',
      '/loan',
    };

    return fullScreenFlowPaths.contains(path);
  }
}
