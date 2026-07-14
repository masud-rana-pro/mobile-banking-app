import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/api_exception.dart';
import '../../../core/network/api_providers.dart';
import '../../auth/providers/auth_providers.dart';
import '../../wallet/providers/wallet_providers.dart';

class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  static const routeName = 'account';
  static const routePath = '/account';

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  final _merchantBusinessController = TextEditingController();
  final _merchantNumberController = TextEditingController();
  final _merchantTypeController = TextEditingController(text: 'Retail');
  final _agentBusinessController = TextEditingController();
  final _agentNumberController = TextEditingController();
  final _agentLocationController = TextEditingController();

  bool _defaultsApplied = false;
  bool _merchantLoading = false;
  bool _agentLoading = false;
  String? _serviceMessage;
  bool _serviceMessageIsError = false;

  @override
  void dispose() {
    _merchantBusinessController.dispose();
    _merchantNumberController.dispose();
    _merchantTypeController.dispose();
    _agentBusinessController.dispose();
    _agentNumberController.dispose();
    _agentLocationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final walletAsync = ref.watch(walletSummaryProvider);
    final displayName = authState.fullName?.trim().isNotEmpty == true
        ? authState.fullName!.trim()
        : 'SmartKash User';
    final phoneNumber = authState.backendToken?.phoneNumber ?? '';
    final localPhoneNumber = _toLocalMobileNumber(phoneNumber);
    final avatarUrl = authState.avatarUrl?.trim() ?? '';
    final role = authState.role ?? authState.backendToken?.role ?? 'CUSTOMER';

    _applyDefaults(displayName, localPhoneNumber);

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
              value: role,
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
            if (_serviceMessage != null) ...[
              const SizedBox(height: 8),
              _StatusBanner(
                message: _serviceMessage!,
                isError: _serviceMessageIsError,
              ),
            ],
            const SizedBox(height: 18),
            _ServiceAccountCard(
              title: 'Open Merchant Account',
              subtitle: 'Use this account as a merchant receiver for Payment.',
              icon: Icons.storefront,
              fields: [
                _ServiceTextField(
                  controller: _merchantBusinessController,
                  label: 'Business name',
                ),
                _ServiceTextField(
                  controller: _merchantNumberController,
                  label: 'Merchant mobile number',
                  keyboardType: TextInputType.phone,
                ),
                _ServiceTextField(
                  controller: _merchantTypeController,
                  label: 'Business type',
                ),
              ],
              loading: _merchantLoading,
              buttonLabel: 'Create Merchant',
              onPressed: role == 'AGENT' ? null : _createMerchantAccount,
              disabledReason: role == 'AGENT'
                  ? 'Agent account cannot also become merchant. Use another mobile number.'
                  : null,
            ),
            const SizedBox(height: 14),
            _ServiceAccountCard(
              title: 'Open Agent Account',
              subtitle: 'Use this account as an agent receiver for Cash Out.',
              icon: Icons.support_agent,
              fields: [
                _ServiceTextField(
                  controller: _agentBusinessController,
                  label: 'Agent point name',
                ),
                _ServiceTextField(
                  controller: _agentNumberController,
                  label: 'Agent mobile number',
                  keyboardType: TextInputType.phone,
                ),
                _ServiceTextField(
                  controller: _agentLocationController,
                  label: 'Location (optional)',
                ),
              ],
              loading: _agentLoading,
              buttonLabel: 'Create Agent',
              onPressed: role == 'MERCHANT' ? null : _createAgentAccount,
              disabledReason: role == 'MERCHANT'
                  ? 'Merchant account cannot also become agent. Use another mobile number.'
                  : null,
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

  void _applyDefaults(String displayName, String localPhoneNumber) {
    if (_defaultsApplied) {
      return;
    }

    _merchantBusinessController.text = '$displayName Shop';
    _merchantNumberController.text = localPhoneNumber;
    _agentBusinessController.text = '$displayName Agent Point';
    _agentNumberController.text = localPhoneNumber;
    _agentLocationController.text = 'Local area';
    _defaultsApplied = true;
  }

  Future<void> _createMerchantAccount() async {
    await _submitServiceAccount(
      loadingSetter: (value) => _merchantLoading = value,
      path: '/api/merchants/me',
      data: {
        'businessName': _merchantBusinessController.text.trim(),
        'merchantNumber': _onlyDigits(_merchantNumberController.text),
        'businessType': _merchantTypeController.text.trim(),
      },
      successMessage:
          'Merchant account created. Use this merchant number for Payment from another customer account.',
    );
  }

  Future<void> _createAgentAccount() async {
    await _submitServiceAccount(
      loadingSetter: (value) => _agentLoading = value,
      path: '/api/agents/me',
      data: {
        'businessName': _agentBusinessController.text.trim(),
        'agentNumber': _agentNumberController.text.trim(),
        if (_agentLocationController.text.trim().isNotEmpty)
          'location': _agentLocationController.text.trim(),
      },
      successMessage:
          'Agent account created. Use this agent number for Cash Out from another customer account.',
    );
  }

  Future<void> _submitServiceAccount({
    required void Function(bool value) loadingSetter,
    required String path,
    required Map<String, dynamic> data,
    required String successMessage,
  }) async {
    setState(() {
      loadingSetter(true);
      _serviceMessage = null;
      _serviceMessageIsError = false;
    });

    try {
      await ref.read(apiClientProvider).post<Map<String, dynamic>>(
            path,
            data: data,
          );
      await ref.read(authControllerProvider.notifier).refreshCurrentUser();
      if (!mounted) {
        return;
      }
      setState(() {
        _serviceMessage = successMessage;
        _serviceMessageIsError = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _serviceMessage = _friendlyError(error);
        _serviceMessageIsError = true;
      });
    } finally {
      if (mounted) {
        setState(() {
          loadingSetter(false);
        });
      }
    }
  }

  String _friendlyError(Object error) {
    if (error is ApiException) {
      if (error.errors.isNotEmpty) {
        return error.errors.first;
      }
      return error.message;
    }
    return error.toString();
  }

  String _toLocalMobileNumber(String value) {
    final digits = _onlyDigits(value);
    if (digits.startsWith('8801') && digits.length == 13) {
      return '0${digits.substring(3)}';
    }
    if (digits.startsWith('1') && digits.length == 10) {
      return '0$digits';
    }
    return digits;
  }

  String _onlyDigits(String value) {
    return value.replaceAll(RegExp(r'[^0-9]'), '');
  }
}

class _ServiceAccountCard extends StatelessWidget {
  const _ServiceAccountCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.fields,
    required this.loading,
    required this.buttonLabel,
    required this.onPressed,
    this.disabledReason,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Widget> fields;
  final bool loading;
  final String buttonLabel;
  final VoidCallback? onPressed;
  final String? disabledReason;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE9EDF2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2F1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: const Color(0xFF008F7A)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF263238),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF607D8B),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...fields,
          if (disabledReason != null) ...[
            const SizedBox(height: 4),
            Text(
              disabledReason!,
              style: const TextStyle(
                color: Color(0xFFB71C1C),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: loading ? null : onPressed,
              icon: loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.arrow_forward),
              label: Text(buttonLabel),
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceTextField extends StatelessWidget {
  const _ServiceTextField({
    required this.controller,
    required this.label,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.message,
    required this.isError,
  });

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isError ? const Color(0xFFFFEBEE) : const Color(0xFFE0F2F1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: isError ? const Color(0xFFB71C1C) : const Color(0xFF00695C),
          fontWeight: FontWeight.w900,
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
