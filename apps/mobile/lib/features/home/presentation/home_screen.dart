import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_assets.dart';
import '../../add_money/presentation/add_money_screen.dart';
import '../../auth/presentation/login_screen.dart';
import '../../auth/providers/auth_providers.dart';
import '../../loan/presentation/loan_screen.dart';
import '../../payment/presentation/merchant_payment_screen.dart';
import '../../recharge/presentation/mobile_recharge_screen.dart';
import '../../savings/presentation/savings_screen.dart';
import '../../send_money/presentation/send_money_screen.dart';
import '../../wallet/domain/wallet_summary.dart';
import '../../wallet/providers/wallet_providers.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  static const routeName = 'home';
  static const routePath = '/';

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(walletRefreshProvider)(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authControllerProvider);
    final walletAsync = ref.watch(walletSummaryProvider);
    final backendToken = authState.backendToken;
    final accountLabel =
        backendToken == null || backendToken.phoneNumber.isEmpty
            ? 'SmartKash Account'
            : backendToken.phoneNumber;
    final roleLabel = backendToken?.role ?? 'CUSTOMER';

    return Scaffold(
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _HomeHeader(
                theme: theme,
                accountLabel: accountLabel,
                roleLabel: roleLabel,
                walletAsync: walletAsync,
                onSignOut: () =>
                    ref.read(authControllerProvider.notifier).signOut(),
              ),
            ),
            SliverToBoxAdapter(
              child: Transform.translate(
                offset: const Offset(0, -24),
                child: const _PrimaryActionPanel(),
              ),
            ),
            SliverToBoxAdapter(
              child: Transform.translate(
                offset: const Offset(0, -10),
                child: const _PromoSection(),
              ),
            ),
            const SliverToBoxAdapter(child: _QuickFeaturesSection()),
            const SliverToBoxAdapter(child: SizedBox(height: 96)),
          ],
        ),
      ),
      bottomNavigationBar: const _SmartKashBottomNav(),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.theme,
    required this.accountLabel,
    required this.roleLabel,
    required this.walletAsync,
    required this.onSignOut,
  });

  final ThemeData theme;
  final String accountLabel;
  final String roleLabel;
  final AsyncValue<WalletSummary> walletAsync;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF00796B), Color(0xFF2446A6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              AppAssets.smartKashHeader,
              fit: BoxFit.cover,
              opacity: const AlwaysStoppedAnimation(0.72),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF00695C).withValues(alpha: 0.84),
                    const Color(0xFF2446A6).withValues(alpha: 0.56),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
          ),
          Positioned(
            left: -48,
            right: -32,
            top: 88,
            child: Container(
              height: 92,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white24, width: 2),
                borderRadius: BorderRadius.circular(120),
              ),
            ),
          ),
          Positioned(
            right: 26,
            bottom: 80,
            child: _HeaderBadge(color: Colors.white.withValues(alpha: 0.9)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: Image.asset(
                        AppAssets.smartKashLogoMark,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            accountLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x24000000),
                                  blurRadius: 16,
                                  offset: Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.account_balance_wallet,
                                  color: Color(0xFF00796B),
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Logged in - $roleLabel',
                                  style: const TextStyle(
                                    color: Color(0xFF263238),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    _HeaderIconButton(
                      icon: Icons.search,
                      onTap: () {},
                    ),
                    const SizedBox(width: 10),
                    _HeaderIconButton(
                      icon: Icons.logout,
                      onTap: onSignOut,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _BalancePanel(walletAsync: walletAsync),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BalancePanel extends StatelessWidget {
  const _BalancePanel({required this.walletAsync});

  final AsyncValue<WalletSummary> walletAsync;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(18),
      ),
      child: walletAsync.when(
        data: (wallet) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Available Balance',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              wallet.balanceFormatted,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        loading: () => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Available Balance',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            const SizedBox(
              width: 160,
              height: 24,
              child: LinearProgressIndicator(
                backgroundColor: Colors.white24,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white54),
              ),
            ),
          ],
        ),
        error: (error, stack) => const Text(
          'Balance unavailable',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Container(
        width: 52,
        height: 52,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 14,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Icon(icon, color: const Color(0xFF263238), size: 26),
      ),
    );
  }
}

class _HeaderBadge extends StatelessWidget {
  const _HeaderBadge({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 86,
      height: 86,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            bottom: 4,
            child: Icon(Icons.shield, color: color, size: 58),
          ),
          Positioned(
            top: 12,
            right: 2,
            child: Icon(
              Icons.check_circle,
              color: Colors.amber.shade300,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryActionPanel extends StatelessWidget {
  const _PrimaryActionPanel();

  static const _actions = [
    _ActionItem(Icons.send_to_mobile, 'Send Money', Color(0xFF0E9F6E),
        routeName: SendMoneyScreen.routeName),
    _ActionItem(Icons.phone_android, 'Recharge', Color(0xFF1D7ED6),
        routeName: MobileRechargeScreen.routeName),
    _ActionItem(Icons.payments_outlined, 'Cash Out', Color(0xFF00A8A8)),
    _ActionItem(Icons.shopping_bag_outlined, 'Payment', Color(0xFFE08B2D),
        routeName: MerchantPaymentScreen.routeName),
    _ActionItem(Icons.add_card_outlined, 'Add Money', Color(0xFF7A4CC2),
        routeName: AddMoneyScreen.routeName),
    _ActionItem(Icons.bolt_outlined, 'Pay Bill', Color(0xFF00695C)),
    _ActionItem(Icons.savings_outlined, 'Savings', Color(0xFF9C3A8D),
        routeName: SavingsScreen.routeName),
    _ActionItem(Icons.account_balance, 'Loan', Color(0xFF795548),
        routeName: LoanScreen.routeName),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.fromLTRB(10, 24, 10, 18),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(26),
          topRight: Radius.circular(26),
          bottomLeft: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _actions.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisExtent: 96,
            ),
            itemBuilder: (context, index) {
              final action = _actions[index];
              return _ActionTile(action: action);
            },
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () {},
            iconAlignment: IconAlignment.end,
            icon: const Icon(Icons.keyboard_arrow_down),
            label: const Text('See More'),
          ),
        ],
      ),
    );
  }
}

class _ActionItem {
  const _ActionItem(this.icon, this.label, this.color, {this.routeName});

  final IconData icon;
  final String label;
  final Color color;
  final String? routeName;
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.action});

  final _ActionItem action;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        if (action.routeName != null) {
          context.pushNamed(action.routeName!);
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: action.color.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(action.icon, color: action.color, size: 30),
          ),
          const SizedBox(height: 9),
          Text(
            action.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF263238),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _PromoSection extends StatelessWidget {
  const _PromoSection();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        children: [
          _PromoBanner(),
        ],
      ),
    );
  }
}

class _PromoBanner extends StatelessWidget {
  const _PromoBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 118,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(AppAssets.smartKashPromo, fit: BoxFit.cover),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF003B46).withValues(alpha: 0.84),
                  const Color(0xFF003B46).withValues(alpha: 0.32),
                  Colors.transparent,
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(18, 20, 118, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Recharge faster with SmartKash',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Demo offers for your learning MVP',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                5,
                (index) => Container(
                  width: index == 1 ? 18 : 7,
                  height: 7,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: index == 1 ? Colors.white : Colors.white54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickFeaturesSection extends StatelessWidget {
  const _QuickFeaturesSection();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(18, 22, 18, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Features',
            style: TextStyle(
              color: Color(0xFF263238),
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                  child: _QuickChip(icon: Icons.lightbulb, label: 'DESCO')),
              SizedBox(width: 10),
              Expanded(
                  child:
                      _QuickChip(icon: Icons.phone_android, label: 'Teletalk')),
              SizedBox(width: 10),
              Expanded(child: _QuickChip(icon: Icons.send, label: 'Transfer')),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                  child: _FeatureCard(
                      icon: Icons.card_giftcard, label: 'Rewards')),
              SizedBox(width: 12),
              Expanded(
                  child: _FeatureCard(icon: Icons.percent, label: 'Offers')),
              SizedBox(width: 12),
              Expanded(
                  child:
                      _FeatureCard(icon: Icons.emoji_events, label: 'Goals')),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  const _QuickChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE6EAEE)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF008F7A), size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 92,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE9EDF2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: const Color(0xFFFFB020), size: 30),
          const SizedBox(height: 8),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _SmartKashBottomNav extends StatelessWidget {
  const _SmartKashBottomNav();

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: 0,
      onDestinationSelected: (index) {
        if (index == 1) {
          context.pushNamed(LoginScreen.routeName);
        }
      },
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home_rounded), label: 'Home'),
        NavigationDestination(
            icon: Icon(Icons.person_outline), label: 'Account'),
        NavigationDestination(
            icon: Icon(Icons.qr_code_scanner), label: 'Scan QR'),
        NavigationDestination(icon: Icon(Icons.mail_outline), label: 'Inbox'),
      ],
    );
  }
}
