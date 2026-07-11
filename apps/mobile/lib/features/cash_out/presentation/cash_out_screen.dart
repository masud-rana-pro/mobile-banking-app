import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/api_exception.dart';
import '../../transaction/providers/transaction_providers.dart';
import '../../wallet/providers/wallet_providers.dart';
import '../domain/cash_out_result.dart';
import '../providers/cash_out_providers.dart';

class CashOutScreen extends ConsumerStatefulWidget {
  const CashOutScreen({super.key});

  static const routeName = 'cash-out';
  static const routePath = '/cash-out';

  @override
  ConsumerState<CashOutScreen> createState() => _CashOutScreenState();
}

enum _CashOutStep { details, pin, result }

class _CashOutScreenState extends ConsumerState<CashOutScreen> {
  final _agentController = TextEditingController();
  final _amountController = TextEditingController();
  final _pinController = TextEditingController();
  final _noteController = TextEditingController();

  _CashOutStep _step = _CashOutStep.details;
  CashOutResult? _result;
  String? _idempotencyKey;
  bool _isLoading = false;

  @override
  void dispose() {
    _agentController.dispose();
    _amountController.dispose();
    _pinController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _continueToPin() {
    final agent = _agentController.text.trim();
    final amount = double.tryParse(_amountController.text.trim());
    if (!RegExp(r'^[0-9]{10,15}$').hasMatch(agent)) {
      _showMessage('Enter a valid agent number with 10 to 15 digits.');
      return;
    }
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

  void _reset() {
    setState(() {
      _step = _CashOutStep.details;
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

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cash Out'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: switch (_step) {
          _CashOutStep.details => _detailsStep(),
          _CashOutStep.pin => _pinStep(),
          _CashOutStep.result => _resultStep(),
        },
      ),
    );
  }

  Widget _detailsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _InfoHeader(
          icon: Icons.payments_outlined,
          title: 'Agent Cash Out',
          message:
              'Demo Cash Out debits your SmartKash wallet and creates receipt history. No real agent settlement is used.',
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
          'Confirm Cash Out',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        Text(
          'Cash out BDT ${double.tryParse(_amountController.text.trim())?.toStringAsFixed(2) ?? '0.00'} from agent ${_agentController.text.trim()}',
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
          label: 'Cash Out Now',
          onPressed: _isLoading ? null : _submit,
          loading: _isLoading,
        ),
        TextButton(
          onPressed: () => setState(() => _step = _CashOutStep.details),
          child: const Text('Change Details'),
        ),
      ],
    );
  }

  Widget _resultStep() {
    final result = _result!;
    return _ResultView(
      success: result.success,
      title: result.success ? 'Cash Out Successful!' : 'Cash Out Failed',
      message: result.message,
      rows: [
        _ReceiptRow('Agent', result.agentNumber),
        _ReceiptRow('Amount', 'BDT ${result.amount.toStringAsFixed(2)}'),
        if (result.transactionReference != null)
          _ReceiptRow('TrxID', result.transactionReference!),
        if (result.balanceAfter != null)
          _ReceiptRow(
              'New Balance', 'BDT ${result.balanceAfter!.toStringAsFixed(2)}'),
      ],
      buttonLabel: 'Cash Out Again',
      onPressed: _reset,
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

class _InfoHeader extends StatelessWidget {
  const _InfoHeader({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFE9F8F4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: const Color(0xFF008F7A),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                Text(message,
                    style: const TextStyle(
                        color: Color(0xFF607D8B), height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView({
    required this.success,
    required this.title,
    required this.message,
    required this.rows,
    required this.buttonLabel,
    required this.onPressed,
  });

  final bool success;
  final String title;
  final String message;
  final List<_ReceiptRow> rows;
  final String buttonLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final color = success ? const Color(0xFF2E7D32) : const Color(0xFFC62828);
    return Column(
      children: [
        const SizedBox(height: 16),
        Icon(success ? Icons.check_circle : Icons.cancel,
            color: color, size: 78),
        const SizedBox(height: 14),
        Text(title,
            style: TextStyle(
                color: color, fontSize: 24, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Text(message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF607D8B))),
        const SizedBox(height: 22),
        Container(
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
                      Text(row.label,
                          style: const TextStyle(
                              color: Color(0xFF607D8B),
                              fontWeight: FontWeight.w700)),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          row.value,
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
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF008F7A),
              foregroundColor: Colors.white,
            ),
            child: Text(buttonLabel,
                style: const TextStyle(fontWeight: FontWeight.w900)),
          ),
        ),
      ],
    );
  }
}

class _ReceiptRow {
  const _ReceiptRow(this.label, this.value);

  final String label;
  final String value;
}
