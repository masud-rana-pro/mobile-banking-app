import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/api_exception.dart';
import '../../../shared/models/resolved_recipient_profile.dart';
import '../../../shared/providers/recipient_profile_providers.dart';
import '../../../shared/widgets/contact_number_input.dart';
import '../../../shared/widgets/feature_flow_widgets.dart';
import '../../../shared/widgets/hold_to_confirm_screen.dart';
import '../../notification/presentation/notification_inbox_screen.dart';
import '../../transaction/providers/transaction_providers.dart';
import '../../wallet/providers/wallet_providers.dart';
import '../domain/pay_bill_result.dart';
import '../providers/pay_bill_providers.dart';

class PayBillScreen extends ConsumerStatefulWidget {
  const PayBillScreen({super.key});

  static const routeName = 'pay-bill';
  static const routePath = '/pay-bill';

  @override
  ConsumerState<PayBillScreen> createState() => _PayBillScreenState();
}

enum _PayBillStep { biller, amount, pin, confirm, result }

class _BillerOption {
  const _BillerOption(this.code, this.label, this.icon, this.color);

  final String code;
  final String label;
  final IconData icon;
  final Color color;
}

class _PayBillScreenState extends ConsumerState<PayBillScreen> {
  static const _billers = [
    _BillerOption('DESCO', 'DESCO', Icons.bolt_outlined, Color(0xFF00695C)),
    _BillerOption('WASA', 'WASA', Icons.water_drop_outlined, Color(0xFF1D7ED6)),
    _BillerOption('TITAS', 'Titas Gas', Icons.local_fire_department_outlined,
        Color(0xFFE08B2D)),
    _BillerOption('INTERNET', 'Internet', Icons.wifi, Color(0xFF7A4CC2)),
  ];

  final _accountController = TextEditingController();
  final _amountController = TextEditingController();
  final _pinController = TextEditingController();
  final _noteController = TextEditingController();

  _PayBillStep _step = _PayBillStep.biller;
  String _selectedBiller = _billers.first.code;
  ResolvedRecipientProfile? _accountProfile;
  PayBillResult? _result;
  String? _idempotencyKey;
  bool _isLoading = false;

  @override
  void dispose() {
    _accountController.dispose();
    _amountController.dispose();
    _pinController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _continueToAmount() async {
    final account = _accountController.text.trim();
    if (account.length < 3) {
      _showMessage('Enter a valid bill account number.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final profile = _looksLikeBangladeshMobileNumber(account)
          ? await ref
              .read(recipientProfileRepositoryProvider)
              .tryResolveByMobileNumber(account)
          : null;
      setState(() {
        _accountProfile = profile;
        _step = _PayBillStep.amount;
        _isLoading = false;
      });
    } catch (error) {
      setState(() => _isLoading = false);
      _showMessage(_friendlyError(error));
    }
  }

  void _continueToPin() {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount < 1) {
      _showMessage('Enter a valid amount.');
      return;
    }
    setState(() {
      _idempotencyKey ??=
          ref.read(payBillRepositoryProvider).createIdempotencyKey();
      _step = _PayBillStep.pin;
    });
  }

  Future<void> _submit() async {
    final pin = _pinController.text.trim();
    final amount = double.tryParse(_amountController.text.trim());
    if (pin.length != 5) {
      _showMessage('Enter your 5-digit PIN.');
      return;
    }
    if (amount == null || amount < 1) {
      _showMessage('Enter a valid amount.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final repository = ref.read(payBillRepositoryProvider);
      final result = await repository.payBill(
        billerCode: _selectedBiller,
        billAccountNumber: _accountController.text.trim(),
        amount: amount,
        pin: pin,
        idempotencyKey: _idempotencyKey ??= repository.createIdempotencyKey(),
        note: _noteController.text.trim(),
      );
      ref.read(walletRefreshProvider)();
      ref.read(transactionRefreshProvider)();
      setState(() {
        _result = result;
        _step = _PayBillStep.result;
        _isLoading = false;
      });
    } catch (error) {
      setState(() => _isLoading = false);
      _showMessage(_friendlyError(error));
    }
  }

  void _continueToConfirm() {
    if (_pinController.text.trim().length != 5) {
      _showMessage('Enter your 5-digit PIN.');
      return;
    }
    setState(() => _step = _PayBillStep.confirm);
  }

  void _reset() {
    setState(() {
      _step = _PayBillStep.biller;
      _selectedBiller = _billers.first.code;
      _accountProfile = null;
      _result = null;
      _idempotencyKey = null;
      _accountController.clear();
      _amountController.clear();
      _pinController.clear();
      _noteController.clear();
    });
  }

  String _friendlyError(Object error) {
    if (error is ApiException) {
      final details = error.errors.isEmpty ? '' : ' ${error.errors.join(' ')}';
      return '${error.message}$details';
    }
    return 'Pay Bill failed.';
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final isPopupStep =
        _step == _PayBillStep.confirm || _step == _PayBillStep.result;
    return Scaffold(
      appBar: AppBar(title: const Text('Pay Bill'), centerTitle: true),
      body: isPopupStep
          ? _buildBody()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: _buildBody(),
            ),
    );
  }

  Widget _buildBody() {
    return switch (_step) {
      _PayBillStep.biller => _billerStep(),
      _PayBillStep.amount => _amountStep(),
      _PayBillStep.pin => _pinStep(),
      _PayBillStep.confirm => _confirmStep(),
      _PayBillStep.result => _resultStep(),
    };
  }

  Widget _billerStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Biller',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        const Text(
          'Choose the biller and enter the bill account first. Amount and PIN confirmation come next.',
          style: TextStyle(color: Color(0xFF607D8B), height: 1.35),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final biller in _billers)
              ChoiceChip(
                avatar: Icon(biller.icon, color: biller.color, size: 18),
                label: Text(biller.label),
                selected: _selectedBiller == biller.code,
                selectedColor: biller.color.withValues(alpha: 0.16),
                onSelected: (_) =>
                    setState(() => _selectedBiller = biller.code),
              ),
          ],
        ),
        const SizedBox(height: 20),
        ContactNumberInput(
          controller: _accountController,
          labelText: 'Bill Account Number',
          hintText: 'Meter/customer/account ID',
          contactButtonLabel: 'Contacts',
          qrButtonLabel: 'Scan QR',
          keyboardType: TextInputType.text,
          loading: _isLoading,
          proceedButtonLabel: 'Next: Enter Amount',
          onChanged: (_) => setState(() => _accountProfile = null),
          onProceed: () {
            _continueToAmount();
          },
        ),
      ],
    );
  }

  Widget _amountStep() {
    final balanceText = ref.watch(walletSummaryProvider).maybeWhen(
          data: (wallet) => '৳${wallet.balance.toStringAsFixed(2)}',
          orElse: () => null,
        );
    final biller =
        _billers.firstWhere((item) => item.code == _selectedBiller).label;
    final account = _accountController.text.trim();
    final profile = _accountProfile;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AmountRecipientCard(
          label: 'Biller',
          title: profile?.displayName ?? biller,
          subtitle: profile == null ? account : '$account - $biller',
          imageUrl: profile?.avatarUrl,
          fallbackIcon: Icons.receipt_long_outlined,
        ),
        const SizedBox(height: 18),
        AmountEntryPanel(
          controller: _amountController,
          tabs: const ['Amount', 'Biller', 'Coupon'],
          presets: const [500, 1000, 1500],
          availableBalanceText: balanceText,
          proceedLabel: 'Proceed',
          onProceed: _continueToPin,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _noteController,
          maxLength: 120,
          decoration: const InputDecoration(
            labelText: 'Reference (optional)',
            border: OutlineInputBorder(),
          ),
        ),
        TextButton.icon(
          onPressed: _isLoading
              ? null
              : () => setState(() => _step = _PayBillStep.biller),
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Change Biller'),
        ),
      ],
    );
  }

  Widget _pinStep() {
    final amount =
        double.tryParse(_amountController.text.trim())?.toStringAsFixed(2) ??
            '0.00';
    final biller =
        _billers.firstWhere((item) => item.code == _selectedBiller).label;
    final account = _accountController.text.trim();
    final profile = _accountProfile;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PinEntryPanel(
          pinController: _pinController,
          actionTitle: 'Pay Bill',
          amountText: '৳$amount',
          totalText: '৳$amount',
          typeLabel: 'Utility',
          secondaryTypeLabel: 'Saved',
          loading: _isLoading,
          onConfirm: _continueToConfirm,
          onBackToAmount: () => setState(() => _step = _PayBillStep.amount),
          recipient: AmountRecipientCard(
            label: 'Biller',
            title: profile?.displayName ?? biller,
            subtitle: profile == null ? account : '$account - $biller',
            imageUrl: profile?.avatarUrl,
            fallbackIcon: Icons.receipt_long_outlined,
          ),
        ),
      ],
    );
  }

  Widget _confirmStep() {
    final amount =
        double.tryParse(_amountController.text.trim())?.toStringAsFixed(2) ??
            '0.00';
    final biller =
        _billers.firstWhere((item) => item.code == _selectedBiller).label;
    final account = _accountController.text.trim();
    final profile = _accountProfile;

    return HoldToConfirmScreen(
      actionName: 'Pay Bill',
      accountName: profile?.displayName ?? biller,
      accountNumber: profile == null ? account : '$account - $biller',
      avatarUrl: profile?.avatarUrl,
      avatarIcon: Icons.receipt_long_outlined,
      isLoading: _isLoading,
      onCancel: () => setState(() => _step = _PayBillStep.pin),
      onConfirmed: _submit,
      details: [
        HoldToConfirmDetail(
            label: 'Total', value: 'Tk $amount', mutedValue: '+ No charge'),
        HoldToConfirmDetail(label: 'Biller', value: biller),
        HoldToConfirmDetail(label: 'Account', value: account),
        const HoldToConfirmDetail(label: 'Reference', value: 'SmartKash'),
      ],
    );
  }

  Widget _resultStep() {
    final result = _result!;
    final biller =
        _billers.firstWhere((item) => item.code == result.billerCode).label;
    final profile = _accountProfile;

    return TransactionConfirmationScreen(
      success: result.success,
      actionName: 'Pay Bill',
      message: result.message,
      accountName: profile?.displayName ?? biller,
      accountNumber: profile == null
          ? result.billAccountNumber
          : '${result.billAccountNumber} - $biller',
      avatarUrl: profile?.avatarUrl,
      avatarIcon: Icons.receipt_long_outlined,
      totalText: '৳${result.amount.toStringAsFixed(2)}',
      transactionId: result.transactionReference,
      newBalanceText: result.balanceAfter == null
          ? null
          : '৳${result.balanceAfter!.toStringAsFixed(2)}',
      typeText: 'Bill Payment',
      extraLabel: 'Biller',
      extraValue: result.billerCode,
      secondaryLabel: 'View Inbox',
      onSecondaryAction: () =>
          context.pushNamed(NotificationInboxScreen.routeName),
      primaryLabel: 'Pay Another',
      onPrimaryAction: _reset,
    );
  }

  bool _looksLikeBangladeshMobileNumber(String value) {
    final normalized = value.trim().replaceAll(' ', '').replaceAll('-', '');
    return RegExp(r'^(\+8801|8801|01|1)[0-9]{9}$').hasMatch(normalized);
  }
}
