import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/api_exception.dart';
import '../../transaction/providers/transaction_providers.dart';
import '../../wallet/providers/wallet_providers.dart';
import '../domain/mobile_recharge_record.dart';
import '../providers/recharge_providers.dart';

class MobileRechargeScreen extends ConsumerStatefulWidget {
  const MobileRechargeScreen({super.key});

  static const routeName = 'mobile-recharge';
  static const routePath = '/mobile-recharge';

  @override
  ConsumerState<MobileRechargeScreen> createState() =>
      _MobileRechargeScreenState();
}

enum _RechargeStep { details, pin, result }

class _OperatorOption {
  const _OperatorOption(this.value, this.label, this.color);

  final String value;
  final String label;
  final Color color;
}

class _MobileRechargeScreenState extends ConsumerState<MobileRechargeScreen> {
  static const _operators = [
    _OperatorOption('GP', 'Grameenphone', Color(0xFF1D7ED6)),
    _OperatorOption('ROBI', 'Robi', Color(0xFFE53935)),
    _OperatorOption('BANGLALINK', 'Banglalink', Color(0xFFF57C00)),
    _OperatorOption('TELETALK', 'Teletalk', Color(0xFF008F7A)),
    _OperatorOption('AIRTEL', 'Airtel', Color(0xFFD81B60)),
  ];

  final _mobileController = TextEditingController();
  final _amountController = TextEditingController();
  final _pinController = TextEditingController();
  final _noteController = TextEditingController();

  _RechargeStep _currentStep = _RechargeStep.details;
  String _selectedOperator = _operators.first.value;
  MobileRechargeRecord? _rechargeResult;
  String? _idempotencyKey;
  bool _isLoading = false;

  @override
  void dispose() {
    _mobileController.dispose();
    _amountController.dispose();
    _pinController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _continueToPin() {
    final mobile = _mobileController.text.trim();
    final amount = double.tryParse(_amountController.text.trim());

    if (!RegExp(r'^[0-9]{10,15}$').hasMatch(mobile)) {
      _showMessage('Enter a valid mobile number with 10 to 15 digits.');
      return;
    }

    if (amount == null || amount < 1) {
      _showMessage('Enter a valid amount (minimum BDT 1.00).');
      return;
    }

    setState(() {
      _idempotencyKey ??=
          ref.read(rechargeRepositoryProvider).createIdempotencyKey();
      _currentStep = _RechargeStep.pin;
    });
  }

  Future<void> _submitRecharge() async {
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
      final repository = ref.read(rechargeRepositoryProvider);
      final result = await repository.createRecharge(
        operator: _selectedOperator,
        mobileNumber: _mobileController.text.trim(),
        amount: amount,
        pin: pin,
        idempotencyKey: _idempotencyKey ??= repository.createIdempotencyKey(),
        note: _noteController.text.trim(),
      );
      ref.read(walletRefreshProvider)();
      ref.read(mobileRechargeRefreshProvider)();
      ref.read(transactionRefreshProvider)();
      setState(() {
        _rechargeResult = result;
        _currentStep = _RechargeStep.result;
        _isLoading = false;
      });
    } catch (error) {
      setState(() => _isLoading = false);
      _showMessage(_friendlyError(error, fallback: 'Recharge failed.'));
    }
  }

  void _reset() {
    setState(() {
      _currentStep = _RechargeStep.details;
      _rechargeResult = null;
      _idempotencyKey = null;
      _mobileController.clear();
      _amountController.clear();
      _pinController.clear();
      _noteController.clear();
      _selectedOperator = _operators.first.value;
    });
  }

  String _friendlyError(Object error, {required String fallback}) {
    if (error is ApiException) {
      final details = error.errors.isEmpty ? '' : ' ${error.errors.join(' ')}';
      return '${error.message}$details';
    }
    return fallback;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mobile Recharge'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBody(),
            const SizedBox(height: 18),
            const _InboxHistoryHint(),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentStep) {
      case _RechargeStep.details:
        return _buildDetailsStep();
      case _RechargeStep.pin:
        return _buildPinStep();
      case _RechargeStep.result:
        return _buildResultStep();
    }
  }

  Widget _buildDetailsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recharge Details',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF263238),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Demo recharge debits your SmartKash wallet. No real operator API is used.',
          style: TextStyle(color: Color(0xFF607D8B)),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final operator in _operators)
              ChoiceChip(
                label: Text(operator.label),
                selected: _selectedOperator == operator.value,
                selectedColor: operator.color.withValues(alpha: 0.18),
                onSelected: (_) {
                  setState(() => _selectedOperator = operator.value);
                },
              ),
          ],
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _mobileController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Mobile Number',
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
            labelText: 'Note (optional)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 20),
        _primaryButton(
          label: 'Next: Enter PIN',
          onPressed: _continueToPin,
        ),
      ],
    );
  }

  Widget _buildPinStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Confirm Recharge',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF263238),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Recharge BDT ${double.tryParse(_amountController.text.trim())?.toStringAsFixed(2) ?? '0.00'} to ${_mobileController.text.trim()} ($_selectedOperator)',
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
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 20),
        _primaryButton(
          label: 'Recharge Now',
          onPressed: _isLoading ? null : _submitRecharge,
          loading: _isLoading,
        ),
        TextButton(
          onPressed: () => setState(() => _currentStep = _RechargeStep.details),
          child: const Text('Change Details'),
        ),
      ],
    );
  }

  Widget _buildResultStep() {
    final result = _rechargeResult!;
    final isSuccess = result.status == 'SUCCESS';

    return Column(
      children: [
        const SizedBox(height: 8),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color:
                isSuccess ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isSuccess ? Icons.check_circle : Icons.cancel,
            color:
                isSuccess ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
            size: 48,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          isSuccess ? 'Recharge Successful!' : 'Recharge Failed',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color:
                isSuccess ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
          ),
        ),
        const SizedBox(height: 24),
        _resultCard(result),
        const SizedBox(height: 24),
        _primaryButton(
          label: 'Make Another Recharge',
          onPressed: _reset,
        ),
      ],
    );
  }

  Widget _resultCard(MobileRechargeRecord result) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _detailRow('Operator', result.operator),
          _detailRow('Mobile Number', result.mobileNumber),
          _detailRow('Amount', 'BDT ${result.amount.toStringAsFixed(2)}'),
          _detailRow('Status', result.status),
          if (result.transactionReference != null)
            _detailRow('Reference', result.transactionReference!),
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
      height: 50,
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
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF607D8B),
              fontWeight: FontWeight.w600,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: Color(0xFF263238),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InboxHistoryHint extends StatelessWidget {
  const _InboxHistoryHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Row(
        children: [
          Icon(Icons.mail_outline, color: Color(0xFF008F7A)),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'All recharge history is saved in Inbox > Transactions. Open any item there to see receipt details.',
              style: TextStyle(
                color: Color(0xFF607D8B),
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
