import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/add_money/presentation/add_money_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/pin_setup_screen.dart';
import '../../features/auth/providers/auth_providers.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/transaction/presentation/transaction_detail_screen.dart';
import '../../features/transaction/presentation/transaction_list_screen.dart';

final appRouterProvider = Provider<GoRouter>(
  (ref) {
    final refreshListenable = ValueNotifier<int>(0);
    ref.onDispose(refreshListenable.dispose);

    ref.listen(authControllerProvider, (previous, next) {
      refreshListenable.value++;
    });

    return GoRouter(
      initialLocation: HomeScreen.routePath,
      refreshListenable: refreshListenable,
      redirect: (context, state) {
        final authState = ref.read(authControllerProvider);
        final isLoginRoute = state.matchedLocation == LoginScreen.routePath;
        final isPinSetupRoute =
            state.matchedLocation == PinSetupScreen.routePath;

        if (authState.isAuthenticated) {
          if (authState.needsPinSetup) {
            return isPinSetupRoute ? null : PinSetupScreen.routePath;
          }

          if (isPinSetupRoute) {
            return HomeScreen.routePath;
          }

          return isLoginRoute ? HomeScreen.routePath : null;
        }

        return isLoginRoute ? null : LoginScreen.routePath;
      },
      routes: [
        GoRoute(
          path: HomeScreen.routePath,
          name: HomeScreen.routeName,
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: LoginScreen.routePath,
          name: LoginScreen.routeName,
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: PinSetupScreen.routePath,
          name: PinSetupScreen.routeName,
          builder: (context, state) => const PinSetupScreen(),
        ),
        GoRoute(
          path: TransactionListScreen.routePath,
          name: TransactionListScreen.routeName,
          builder: (context, state) => const TransactionListScreen(),
        ),
        GoRoute(
          path: TransactionDetailScreen.routePath,
          name: TransactionDetailScreen.routeName,
          builder: (context, state) {
            final id = int.parse(state.pathParameters['id'] ?? '0');
            return TransactionDetailScreen(transactionId: id);
          },
        ),
        GoRoute(
          path: AddMoneyScreen.routePath,
          name: AddMoneyScreen.routeName,
          builder: (context, state) => const AddMoneyScreen(),
        ),
      ],
    );
  },
);
