import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/api_exception.dart';
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

enum _PayBillStep { details, pin, confirm, result }

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

  _PayBillStep _step = _PayBillStep.details;
  String _selectedBiller = _billers.first.code;
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

  void _continueToPin() {
    final account = _accountController.text.trim();
    final amount = double.tryParse(_amountController.text.trim());
    if (account.length < 3) {
      _showMessage('Enter a valid bill account number.');
      return;
    }
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
      _step = _PayBillStep.details;
      _selectedBiller = _billers.first.code;
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
    final isConfirmStep = _step == _PayBillStep.confirm;
    return Scaffold(
      appBar: AppBar(title: const Text('Pay Bill'), centerTitle: true),
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
      _PayBillStep.details => _detailsStep(),
      _PayBillStep.pin => _pinStep(),
      _PayBillStep.confirm => _confirmStep(),
      _PayBillStep.result => _resultStep(),
    };
  }

  Widget _detailsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Biller',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        const Text(
          'Demo Pay Bill debits your wallet and creates transaction history. No real biller API is used.',
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
        TextField(
          controller: _accountController,
          decoration: const InputDecoration(
            labelText: 'Bill Account Number',
            hintText: 'Meter/customer/account ID',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Amount (BDT)',
            prefixText: 'BDT ',
            border: OutlineInputBorder(),
          ),
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
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
        const SizedBox(height: 20),
        _primaryButton(label: 'Next: Enter PIN', onPressed: _continueToPin),
      ],
    );
  }

  Widget _pinStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Confirm Bill Payment',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        Text(
          'Pay BDT ${double.tryParse(_amountController.text.trim())?.toStringAsFixed(2) ?? '0.00'} to $_selectedBiller for ${_accountController.text.trim()}',
          style: const TextStyle(color: Color(0xFF607D8B)),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _pinController,
          obscureText: true,
          maxLength: 5,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: '5-digit PIN',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 18),
        _primaryButton(
          label: 'Review Pay Bill',
          onPressed: _isLoading ? null : _continueToConfirm,
          loading: _isLoading,
        ),
        TextButton(
          onPressed: () => setState(() => _step = _PayBillStep.details),
          child: const Text('Change Details'),
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

    return HoldToConfirmScreen(
      actionName: 'Pay Bill',
      accountName: biller,
      accountNumber: account,
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
    return Column(
      children: [
        const SizedBox(height: 16),
        Icon(
          result.success ? Icons.check_circle : Icons.cancel,
          color: result.success
              ? const Color(0xFF2E7D32)
              : const Color(0xFFC62828),
          size: 78,
        ),
        const SizedBox(height: 14),
        Text(
          result.success ? 'Bill Paid Successfully!' : 'Bill Payment Failed',
          style: TextStyle(
            color: result.success
                ? const Color(0xFF2E7D32)
                : const Color(0xFFC62828),
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(result.message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF607D8B))),
        const SizedBox(height: 22),
        _receiptCard(result),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => context.pushNamed(
                  NotificationInboxScreen.routeName,
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF008F7A),
                  side: const BorderSide(color: Color(0xFF008F7A)),
                  minimumSize: const Size.fromHeight(52),
                ),
                child: const Text(
                  'View Inbox',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _primaryButton(label: 'Pay Another', onPressed: _reset),
            ),
          ],
        ),
      ],
    );
  }

  Widget _receiptCard(PayBillResult result) {
    final rows = [
      ('Biller', result.billerCode),
      ('Account', result.billAccountNumber),
      ('Amount', 'BDT ${result.amount.toStringAsFixed(2)}'),
      if (result.transactionReference != null)
        ('TrxID', result.transactionReference!),
      if (result.balanceAfter != null)
        ('New Balance', 'BDT ${result.balanceAfter!.toStringAsFixed(2)}'),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE9EDF2)),
      ),
      child: Column(
        children: [
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(row.$1,
                      style: const TextStyle(
                          color: Color(0xFF607D8B),
                          fontWeight: FontWeight.w700)),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      row.$2,
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                          color: Color(0xFF263238),
                          fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _primaryButton({
    required String label,
    required VoidCallback? onPressed,
    bool loading = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF008F7A),
          foregroundColor: Colors.white,
        ),
        child: loading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5),
              )
            : Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
      ),
    );
  }
}
