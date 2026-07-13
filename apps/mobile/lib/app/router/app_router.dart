import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/add_money/presentation/add_money_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/pin_setup_screen.dart';
import '../../features/cash_out/presentation/cash_out_screen.dart';
import '../../features/auth/providers/auth_providers.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/loan/presentation/loan_screen.dart';
import '../../features/notification/presentation/notification_inbox_screen.dart';
import '../../features/pay_bill/presentation/pay_bill_screen.dart';
import '../../features/profile/presentation/account_screen.dart';
import '../../features/profile/presentation/profile_completion_screen.dart';
import '../../features/qr/presentation/qr_screen.dart';
import '../../features/payment/presentation/merchant_payment_screen.dart';
import '../../features/recharge/presentation/mobile_recharge_screen.dart';
import '../../features/savings/presentation/savings_screen.dart';
import '../../features/send_money/presentation/send_money_screen.dart';
import '../../features/transaction/presentation/transaction_detail_screen.dart';
import '../../features/transaction/presentation/transaction_list_screen.dart';
import '../../shared/widgets/smartkash_shell.dart';

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
        final isProfileCompletionRoute =
            state.matchedLocation == ProfileCompletionScreen.routePath;

        if (authState.isAuthenticated) {
          if (authState.needsPinSetup) {
            return isPinSetupRoute ? null : PinSetupScreen.routePath;
          }

          if (isPinSetupRoute) {
            return authState.needsProfileCompletion
                ? ProfileCompletionScreen.routePath
                : HomeScreen.routePath;
          }

          if (authState.needsProfileCompletion) {
            return isProfileCompletionRoute
                ? null
                : ProfileCompletionScreen.routePath;
          }

          if (isProfileCompletionRoute) {
            return HomeScreen.routePath;
          }

          return isLoginRoute ? HomeScreen.routePath : null;
        }

        return isLoginRoute ? null : LoginScreen.routePath;
      },
      routes: [
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
          path: ProfileCompletionScreen.routePath,
          name: ProfileCompletionScreen.routeName,
          builder: (context, state) => const ProfileCompletionScreen(),
        ),
        ShellRoute(
          builder: (context, state, child) => SmartKashShell(
            currentPath: state.uri.path,
            child: child,
          ),
          routes: [
            GoRoute(
              path: HomeScreen.routePath,
              name: HomeScreen.routeName,
              builder: (context, state) => const HomeScreen(),
            ),
            GoRoute(
              path: AccountScreen.routePath,
              name: AccountScreen.routeName,
              builder: (context, state) => const AccountScreen(),
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
            GoRoute(
              path: SendMoneyScreen.routePath,
              name: SendMoneyScreen.routeName,
              builder: (context, state) => const SendMoneyScreen(),
            ),
            GoRoute(
              path: QrScreen.routePath,
              name: QrScreen.routeName,
              builder: (context, state) => const QrScreen(),
            ),
            GoRoute(
              path: MerchantPaymentScreen.routePath,
              name: MerchantPaymentScreen.routeName,
              builder: (context, state) => const MerchantPaymentScreen(),
            ),
            GoRoute(
              path: CashOutScreen.routePath,
              name: CashOutScreen.routeName,
              builder: (context, state) => const CashOutScreen(),
            ),
            GoRoute(
              path: PayBillScreen.routePath,
              name: PayBillScreen.routeName,
              builder: (context, state) => const PayBillScreen(),
            ),
            GoRoute(
              path: MobileRechargeScreen.routePath,
              name: MobileRechargeScreen.routeName,
              builder: (context, state) => const MobileRechargeScreen(),
            ),
            GoRoute(
              path: SavingsScreen.routePath,
              name: SavingsScreen.routeName,
              builder: (context, state) => const SavingsScreen(),
            ),
            GoRoute(
              path: LoanScreen.routePath,
              name: LoanScreen.routeName,
              builder: (context, state) => const LoanScreen(),
            ),
            GoRoute(
              path: NotificationInboxScreen.routePath,
              name: NotificationInboxScreen.routeName,
              builder: (context, state) => const NotificationInboxScreen(),
            ),
          ],
        ),
      ],
    );
  },
);
