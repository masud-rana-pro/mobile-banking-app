import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_assets.dart';
import '../../add_money/presentation/add_money_screen.dart';
import '../../auth/providers/auth_providers.dart';
import '../../cash_out/presentation/cash_out_screen.dart';
import '../../loan/presentation/loan_screen.dart';
import '../../notification/presentation/notification_inbox_screen.dart';
import '../../pay_bill/presentation/pay_bill_screen.dart';
import '../../payment/presentation/merchant_payment_screen.dart';
import '../../profile/presentation/account_screen.dart';
import '../../qr/presentation/qr_screen.dart';
import '../../recharge/presentation/mobile_recharge_screen.dart';
import '../../savings/presentation/savings_screen.dart';
import '../../send_money/presentation/send_money_screen.dart';
import '../../transaction/presentation/transaction_list_screen.dart';
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
    final accountLabel = authState.fullName?.trim().isNotEmpty == true
        ? authState.fullName!.trim()
        : backendToken == null || backendToken.phoneNumber.isEmpty
            ? 'SmartKash Account'
            : backendToken.phoneNumber;
    final avatarUrl = authState.avatarUrl?.trim() ?? '';

    return Scaffold(
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _HomeHeader(
                theme: theme,
                accountLabel: accountLabel,
                avatarUrl: avatarUrl,
                walletAsync: walletAsync,
                onSignOut: () =>
                    ref.read(authControllerProvider.notifier).signOut(),
              ),
            ),
            const SliverToBoxAdapter(
              child: _PrimaryActionPanel(),
            ),
            const SliverToBoxAdapter(
              child: _PromoSection(),
            ),
            const SliverToBoxAdapter(child: _QuickFeaturesSection()),
            const SliverToBoxAdapter(child: SizedBox(height: 96)),
          ],
        ),
      ),
    );
  }
}

class _HomeHeader extends StatefulWidget {
  const _HomeHeader({
    required this.theme,
    required this.accountLabel,
    required this.avatarUrl,
    required this.walletAsync,
    required this.onSignOut,
  });

  final ThemeData theme;
  final String accountLabel;
  final String avatarUrl;
  final AsyncValue<WalletSummary> walletAsync;
  final VoidCallback onSignOut;

  @override
  State<_HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<_HomeHeader> {
  bool _showBalance = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(22, 46, 22, 16),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF008F7A), Color(0xFF2446A6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              InkWell(
                onTap: () => context.pushNamed(AccountScreen.routeName),
                borderRadius: BorderRadius.circular(32),
                child: _ProfileAvatar(
                  avatarUrl: widget.avatarUrl,
                  fallbackText: widget.accountLabel,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.accountLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _BalanceTapChip(
                      walletAsync: widget.walletAsync,
                      showBalance: _showBalance,
                      onTap: () => setState(() => _showBalance = !_showBalance),
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
                onTap: widget.onSignOut,
              ),
            ],
          ),
        ),
        Container(
          height: 168,
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Color(0xFFDCF4F0),
          ),
          child: Image.asset(
            AppAssets.smartKashHeader,
            fit: BoxFit.cover,
          ),
        ),
      ],
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.avatarUrl,
    required this.fallbackText,
  });

  final String avatarUrl;
  final String fallbackText;

  @override
  Widget build(BuildContext context) {
    final initial = fallbackText.trim().isEmpty
        ? 'S'
        : fallbackText.trim().characters.first.toUpperCase();
    final safeAvatarUrl = avatarUrl.trim();
    return CircleAvatar(
      radius: 32,
      backgroundColor: Colors.white,
      child: CircleAvatar(
        radius: 29,
        backgroundColor: const Color(0xFFE9F8F4),
        child: safeAvatarUrl.isEmpty
            ? Text(
                initial,
                style: const TextStyle(
                  color: Color(0xFF008F7A),
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              )
            : ClipOval(
                child: Image.network(
                  safeAvatarUrl,
                  key: ValueKey(safeAvatarUrl),
                  width: 58,
                  height: 58,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Text(
                    initial,
                    style: const TextStyle(
                      color: Color(0xFF008F7A),
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

class _BalanceTapChip extends StatelessWidget {
  const _BalanceTapChip({
    required this.walletAsync,
    required this.showBalance,
    required this.onTap,
  });

  final AsyncValue<WalletSummary> walletAsync;
  final bool showBalance;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = walletAsync.when(
      data: (wallet) =>
          showBalance ? wallet.balanceFormatted : 'Tap for Balance',
      loading: () => 'Loading balance',
      error: (_, __) => 'Balance unavailable',
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 230),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(
              color: Color(0x24000000),
              blurRadius: 14,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 27,
              height: 27,
              decoration: BoxDecoration(
                color: const Color(0xFF008F7A),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Icon(
                showBalance
                    ? Icons.visibility_off_outlined
                    : Icons.account_balance_wallet,
                color: Colors.white,
                size: 17,
              ),
            ),
            const SizedBox(width: 9),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF263238),
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
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

class _PrimaryActionPanel extends StatelessWidget {
  const _PrimaryActionPanel();

  static const _actions = [
    _ActionItem(Icons.send_to_mobile, 'Send Money', Color(0xFF0E9F6E),
        routeName: SendMoneyScreen.routeName),
    _ActionItem(Icons.phone_android, 'Mobile Recharge', Color(0xFF1D7ED6),
        routeName: MobileRechargeScreen.routeName),
    _ActionItem(Icons.payments_outlined, 'Cash Out', Color(0xFF00A8A8),
        routeName: CashOutScreen.routeName),
    _ActionItem(Icons.shopping_bag_outlined, 'Payment', Color(0xFFE08B2D),
        routeName: MerchantPaymentScreen.routeName),
    _ActionItem(Icons.add_card_outlined, 'Add Money', Color(0xFF7A4CC2),
        routeName: AddMoneyScreen.routeName),
    _ActionItem(Icons.bolt_outlined, 'Pay Bill', Color(0xFF00695C),
        routeName: PayBillScreen.routeName),
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
              mainAxisExtent: 106,
            ),
            itemBuilder: (context, index) {
              final action = _actions[index];
              return _ActionTile(action: action);
            },
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => _showMvpFeatureNotice(
              context,
              title: 'More services',
              message:
                  'All currently available SmartKash services are listed on this screen.',
            ),
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
          return;
        }

        _showMvpFeatureNotice(
          context,
          title: action.label,
          message: switch (action.label) {
            _ => '${action.label} is not available yet.',
          },
        );
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
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF263238),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

void _showMvpFeatureNotice(
  BuildContext context, {
  required String title,
  required String message,
}) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE9F8F4),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.construction_outlined,
                      color: Color(0xFF008F7A),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF263238),
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                message,
                style: const TextStyle(
                  color: Color(0xFF607D8B),
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Got it'),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _PromoSection extends StatelessWidget {
  const _PromoSection();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(18, 18, 18, 0),
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
                  'Exclusive offers for SmartKash users',
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
                child: _QuickChip(
                  icon: Icons.receipt_long_outlined,
                  label: 'History',
                  routeName: TransactionListScreen.routeName,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _QuickChip(
                  icon: Icons.phone_android,
                  label: 'Teletalk',
                  routeName: MobileRechargeScreen.routeName,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _QuickChip(
                  icon: Icons.send,
                  label: 'Transfer',
                  routeName: SendMoneyScreen.routeName,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _FeatureCard(
                  icon: Icons.card_giftcard,
                  label: 'Rewards',
                  notice:
                      'Rewards need offer rules and campaign tracking. It is planned after the core wallet flows are stable.',
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _FeatureCard(
                  icon: Icons.percent,
                  label: 'Offers',
                  notice:
                      'Offers will appear here when available for your account.',
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _FeatureCard(
                  icon: Icons.emoji_events,
                  label: 'Goals',
                  routeName: SavingsScreen.routeName,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  const _QuickChip({
    required this.icon,
    required this.label,
    this.routeName,
  });

  final IconData icon;
  final String label;
  final String? routeName;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _handleQuickFeatureTap(context, label, routeName, null),
      borderRadius: BorderRadius.circular(8),
      child: Container(
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
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.label,
    this.routeName,
    this.notice,
  });

  final IconData icon;
  final String label;
  final String? routeName;
  final String? notice;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _handleQuickFeatureTap(context, label, routeName, notice),
      borderRadius: BorderRadius.circular(8),
      child: Container(
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
      ),
    );
  }
}

void _handleQuickFeatureTap(
  BuildContext context,
  String label,
  String? routeName,
  String? notice,
) {
  if (routeName != null) {
    context.pushNamed(routeName);
    return;
  }

  _showMvpFeatureNotice(
    context,
    title: label,
    message: notice ?? '$label is not available yet.',
  );
}
