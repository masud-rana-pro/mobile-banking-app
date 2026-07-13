import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/home/presentation/home_screen.dart';
import '../../features/notification/presentation/notification_inbox_screen.dart';
import '../../features/profile/presentation/account_screen.dart';
import '../../features/qr/presentation/qr_screen.dart';
import '../../features/transaction/presentation/transaction_list_screen.dart';

class SmartKashBottomNav extends StatelessWidget {
  const SmartKashBottomNav({
    required this.currentPath,
    super.key,
  });

  final String currentPath;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: _selectedIndexForPath(currentPath),
      onDestinationSelected: (index) {
        switch (index) {
          case 0:
            context.goNamed(HomeScreen.routeName);
            break;
          case 1:
            context.goNamed(AccountScreen.routeName);
            break;
          case 2:
            context.goNamed(QrScreen.routeName);
            break;
          case 3:
            context.goNamed(NotificationInboxScreen.routeName);
            break;
        }
      },
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home_rounded), label: 'Home'),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          label: 'Account',
        ),
        NavigationDestination(
          icon: Icon(Icons.qr_code_scanner),
          label: 'Scan QR',
        ),
        NavigationDestination(icon: Icon(Icons.mail_outline), label: 'Inbox'),
      ],
    );
  }

  int _selectedIndexForPath(String path) {
    if (path == AccountScreen.routePath) {
      return 1;
    }
    if (path == QrScreen.routePath) {
      return 2;
    }
    if (path == NotificationInboxScreen.routePath ||
        path == TransactionListScreen.routePath ||
        path.startsWith('${TransactionListScreen.routePath}/')) {
      return 3;
    }
    return 0;
  }
}
