import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/config/app_config.dart';
import '../../auth/presentation/login_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const routeName = 'home';
  static const routePath = '/';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _HomeHeader(theme: theme)),
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
  const _HomeHeader({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 238,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF00796B), Color(0xFF2446A6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
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
            bottom: 32,
            child: _HeaderMascot(color: Colors.white.withOpacity(0.9)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: Color(0xFFFFC857),
                  child: Text(
                    'S',
                    style: TextStyle(
                      color: Color(0xFF0B2447),
                      fontWeight: FontWeight.w800,
                      fontSize: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Md. Masud Rana',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
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
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.account_balance_wallet,
                              color: Color(0xFF00796B),
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Tap for Balance',
                              style: TextStyle(
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
                  icon: Icons.notifications_none,
                  onTap: () => context.pushNamed(LoginScreen.routeName),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderMascot extends StatelessWidget {
  const _HeaderMascot({required this.color});

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
            child: Icon(Icons.savings_outlined, color: color, size: 58),
          ),
          Positioned(
            top: 12,
            right: 2,
            child: Icon(Icons.flag, color: Colors.amber.shade300, size: 28),
          ),
        ],
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
    _ActionItem(Icons.send_to_mobile, 'Send Money', Color(0xFF0E9F6E)),
    _ActionItem(Icons.phone_android, 'Recharge', Color(0xFF1D7ED6)),
    _ActionItem(Icons.payments_outlined, 'Cash Out', Color(0xFF00A8A8)),
    _ActionItem(Icons.shopping_bag_outlined, 'Payment', Color(0xFFE08B2D)),
    _ActionItem(Icons.add_card_outlined, 'Add Money', Color(0xFF7A4CC2)),
    _ActionItem(Icons.bolt_outlined, 'Pay Bill', Color(0xFF00695C)),
    _ActionItem(Icons.savings_outlined, 'Savings', Color(0xFF9C3A8D)),
    _ActionItem(Icons.account_balance, 'Loan', Color(0xFF795548)),
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
  const _ActionItem(this.icon, this.label, this.color);

  final IconData icon;
  final String label;
  final Color color;
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.action});

  final _ActionItem action;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: action.color.withOpacity(0.08),
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
    );
  }
}

class _PromoSection extends StatelessWidget {
  const _PromoSection();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        children: [
          Container(
            height: 118,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: const LinearGradient(
                colors: [Color(0xFF123C69), Color(0xFF00A896)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x18000000),
                  blurRadius: 16,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  left: -18,
                  bottom: -30,
                  child: Icon(
                    Icons.card_giftcard,
                    color: Colors.white.withOpacity(0.16),
                    size: 124,
                  ),
                ),
                Positioned(
                  right: 16,
                  top: 16,
                  bottom: 16,
                  child: Container(
                    width: 74,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.phone_iphone,
                      color: Colors.white,
                      size: 44,
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(22, 20, 104, 18),
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
                          fontSize: 18,
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Features',
            style: TextStyle(
              color: Color(0xFF263238),
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: const [
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
          const SizedBox(height: 16),
          Row(
            children: const [
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
