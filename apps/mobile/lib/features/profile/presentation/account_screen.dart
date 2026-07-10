import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_providers.dart';
import '../../wallet/providers/wallet_providers.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  static const routeName = 'account';
  static const routePath = '/account';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final walletAsync = ref.watch(walletSummaryProvider);
    final displayName = authState.fullName?.trim().isNotEmpty == true
        ? authState.fullName!.trim()
        : 'SmartKash User';
    final phoneNumber = authState.backendToken?.phoneNumber ?? '';
    final avatarUrl = authState.avatarUrl?.trim() ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 52,
              backgroundColor: const Color(0xFFE0F2F1),
              foregroundColor: const Color(0xFF008F7A),
              backgroundImage:
                  avatarUrl.isEmpty ? null : NetworkImage(avatarUrl),
              onBackgroundImageError: avatarUrl.isEmpty ? null : (_, __) {},
              child: avatarUrl.isEmpty
                  ? Text(
                      displayName.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.w900,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              displayName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Color(0xFF263238),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              phoneNumber,
              style: const TextStyle(
                color: Color(0xFF607D8B),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 24),
            _AccountInfoTile(
              icon: Icons.verified_user,
              label: 'Role',
              value: authState.backendToken?.role ?? 'CUSTOMER',
            ),
            _AccountInfoTile(
              icon: Icons.email_outlined,
              label: 'Email',
              value: authState.email?.isNotEmpty == true
                  ? authState.email!
                  : 'Not added',
            ),
            _AccountInfoTile(
              icon: Icons.pin_outlined,
              label: 'PIN',
              value: authState.pinSet == true ? 'Configured' : 'Not set',
            ),
            walletAsync.when(
              data: (wallet) => _AccountInfoTile(
                icon: Icons.account_balance_wallet,
                label: 'Wallet',
                value: wallet.balanceFormatted,
              ),
              loading: () => const _AccountInfoTile(
                icon: Icons.account_balance_wallet,
                label: 'Wallet',
                value: 'Loading...',
              ),
              error: (error, stack) => const _AccountInfoTile(
                icon: Icons.account_balance_wallet,
                label: 'Wallet',
                value: 'Unavailable',
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () =>
                    ref.read(authControllerProvider.notifier).signOut(),
                icon: const Icon(Icons.logout),
                label: const Text('Sign Out'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountInfoTile extends StatelessWidget {
  const _AccountInfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE9EDF2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF008F7A)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF607D8B),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: Color(0xFF263238),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
