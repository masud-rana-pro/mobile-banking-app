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
    return Scaffold(
      body: child,
      bottomNavigationBar: SmartKashBottomNav(currentPath: currentPath),
    );
  }
}
