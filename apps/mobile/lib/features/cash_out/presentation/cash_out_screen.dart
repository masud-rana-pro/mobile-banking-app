import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/api_exception.dart';
import '../../../shared/widgets/feature_flow_widgets.dart';
import '../../../shared/widgets/hold_to_confirm_screen.dart';
import '../../notification/presentation/notification_inbox_screen.dart';
import '../../qr/presentation/qr_screen.dart';
import '../../transaction/providers/transaction_providers.dart';
import '../../wallet/providers/wallet_providers.dart';
import '../domain/cash_out_result.dart';
import '../providers/cash_out_providers.dart';

class CashOutScreen extends ConsumerStatefulWidget {
  const CashOutScreen({
    this.initialAgentNumber,
    super.key,
  });

  static const routeName = 'cash-out';
  static const routePath = '/cash-out';

  final String? initialAgentNumber;

  @override
  ConsumerState<CashOutScreen> createState() => _CashOutScreenState();
}

enum _CashOutStep { agent, amount, pin, confirm, result }

class _CashOutScreenState extends ConsumerState<CashOutScreen> {
  final _agentController = TextEditingController();
  final _amountController = TextEditingController();
  final _pinController = TextEditingController();
  final _noteController = TextEditingController();

  _CashOutStep _step = _CashOutStep.agent;
  CashOutResult? _result;
  String? _idempotencyKey;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final agentNumber = widget.initialAgentNumber?.trim();
    if (agentNumber != null && agentNumber.isNotEmpty) {
      _agentController.text = agentNumber;
      _step = _CashOutStep.amount;
    }
  }

  @override
  void dispose() {
    _agentController.dispose();
    _amountController.dispose();
    _pinController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _continueToAmount() {
    final agent = _agentController.text.trim();
    if (!_isValidBangladeshMobileNumber(agent)) {
      _showMessage('Enter a valid Bangladesh agent number.');
      return;
    }
    setState(() => _step = _CashOutStep.amount);
  }

  void _continueToPin() {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount < 1) {
      _showMessage('Enter a valid amount.');
      return;
    }
    setState(() {
      _idempotencyKey ??=
          ref.read(cashOutRepositoryProvider).createIdempotencyKey();
      _step = _CashOutStep.pin;
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
      final repository = ref.read(cashOutRepositoryProvider);
      final result = await repository.cashOut(
        agentNumber: _agentController.text.trim(),
        amount: amount,
        pin: pin,
        idempotencyKey: _idempotencyKey ??= repository.createIdempotencyKey(),
        note: _noteController.text.trim(),
      );
      ref.read(walletRefreshProvider)();
      ref.read(transactionRefreshProvider)();
      setState(() {
        _result = result;
        _step = _CashOutStep.result;
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
    setState(() => _step = _CashOutStep.confirm);
  }

  void _reset() {
    setState(() {
      _step = _CashOutStep.agent;
      _result = null;
      _idempotencyKey = null;
      _agentController.clear();
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
    return 'Cash Out failed.';
  }

  bool _isValidBangladeshMobileNumber(String value) {
    final normalized = value.trim().replaceAll(' ', '').replaceAll('-', '');
    return RegExp(r'^(\+8801|8801|01|1)[0-9]{9}$').hasMatch(normalized);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final isConfirmStep = _step == _CashOutStep.confirm;
    return Scaffold(
      appBar: AppBar(title: const Text('Cash Out'), centerTitle: true),
      body: isConfirmStep
          ? _buildBody()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: _buildBody(),
            ),
    );
  }

  Widget _buildBody() {
    return switch (_step) {
      _CashOutStep.agent => _agentStep(),
      _CashOutStep.amount => _amountStep(),
      _CashOutStep.pin => _pinStep(),
      _CashOutStep.confirm => _confirmStep(),
      _CashOutStep.result => _resultStep(),
    };
  }

  Widget _agentStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FeatureIntroCard(
          icon: Icons.payments_outlined,
          title: 'Agent Cash Out',
          subtitle:
              'Enter or scan a demo agent first. Amount and PIN confirmation come in the next steps.',
        ),
        const SizedBox(height: 22),
        TextField(
          controller: _agentController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Agent Number',
            hintText: '01XXXXXXXXX',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _isLoading
              ? null
              : () {
                  context.goNamed(
                    QrScreen.routeName,
                    queryParameters: {'tab': 'scan'},
                  );
                },
          icon: const Icon(Icons.qr_code_scanner),
          label: const Text('Scan agent QR'),
        ),
        const SizedBox(height: 22),
        PrimaryActionButton(
          label: 'Next: Enter Amount',
          loading: _isLoading,
          onPressed: _isLoading ? null : _continueToAmount,
        ),
      ],
    );
  }

  Widget _amountStep() {
    final balanceText = ref.watch(walletSummaryProvider).maybeWhen(
          data: (wallet) => '৳${wallet.balance.toStringAsFixed(2)}',
          orElse: () => null,
        );
    final agentNumber = _agentController.text.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AmountRecipientCard(
          label: 'Agent',
          title: 'SmartKash Agent',
          subtitle: agentNumber,
          fallbackIcon: Icons.payments_outlined,
        ),
        const SizedBox(height: 18),
        AmountEntryPanel(
          controller: _amountController,
          tabs: const ['Amount', 'Agent', 'Reference'],
          presets: const [500, 1000, 2000],
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
              : () => setState(() => _step = _CashOutStep.agent),
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Change Agent'),
        ),
      ],
    );
  }

  Widget _pinStep() {
    final amount =
        double.tryParse(_amountController.text.trim())?.toStringAsFixed(2) ??
            '0.00';
    final agentNumber = _agentController.text.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PinEntryPanel(
          pinController: _pinController,
          actionTitle: 'Cash Out',
          amountText: '৳$amount',
          totalText: '৳$amount',
          typeLabel: 'Agent',
          secondaryTypeLabel: 'QR',
          loading: _isLoading,
          onConfirm: _continueToConfirm,
          onBackToAmount: () => setState(() => _step = _CashOutStep.amount),
          recipient: AmountRecipientCard(
            label: 'Agent',
            title: 'SmartKash Agent',
            subtitle: agentNumber,
            fallbackIcon: Icons.payments_outlined,
          ),
        ),
      ],
    );
  }

  Widget _confirmStep() {
    final amount =
        double.tryParse(_amountController.text.trim())?.toStringAsFixed(2) ??
            '0.00';
    final agentNumber = _agentController.text.trim();

    return HoldToConfirmScreen(
      actionName: 'Cash Out',
      accountName: 'SmartKash Agent',
      accountNumber: agentNumber,
      avatarIcon: Icons.payments_outlined,
      isLoading: _isLoading,
      onCancel: () => setState(() => _step = _CashOutStep.pin),
      onConfirmed: _submit,
      details: [
        HoldToConfirmDetail(
            label: 'Total', value: 'Tk $amount', mutedValue: '+ No charge'),
        const HoldToConfirmDetail(label: 'Type', value: 'Agent Cash Out'),
        HoldToConfirmDetail(label: 'Agent', value: agentNumber),
        const HoldToConfirmDetail(label: 'Reference', value: 'SmartKash'),
      ],
    );
  }

  Widget _resultStep() {
    final result = _result!;
    return TransactionConfirmationScreen(
      success: result.success,
      actionName: 'Cash Out',
      message: result.message,
      accountName: 'SmartKash Agent',
      accountNumber: result.agentNumber,
      avatarIcon: Icons.payments_outlined,
      totalText: '৳${result.amount.toStringAsFixed(2)}',
      transactionId: result.transactionReference,
      newBalanceText: result.balanceAfter == null
          ? null
          : '৳${result.balanceAfter!.toStringAsFixed(2)}',
      typeText: 'Cash Out',
      extraLabel: 'Agent',
      extraValue: result.agentNumber,
      secondaryLabel: 'View Inbox',
      onSecondaryAction: () =>
          context.pushNamed(NotificationInboxScreen.routeName),
      primaryLabel: 'Cash Out Again',
      onPrimaryAction: _reset,
    );
  }
}
