import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/api_exception.dart';
import '../../transaction/providers/transaction_providers.dart';
import '../../wallet/providers/wallet_providers.dart';
import '../domain/merchant_payment_result.dart';
import '../domain/merchant_payment_target.dart';
import '../providers/payment_providers.dart';

class MerchantPaymentScreen extends ConsumerStatefulWidget {
  const MerchantPaymentScreen({super.key});

  static const routeName = 'merchant-payment';
  static const routePath = '/merchant-payment';

  @override
  ConsumerState<MerchantPaymentScreen> createState() =>
      _MerchantPaymentScreenState();
}

enum _PaymentStep { merchant, amount, pin, result }

class _MerchantPaymentScreenState extends ConsumerState<MerchantPaymentScreen> {
  final _merchantNumberController = TextEditingController();
  final _amountController = TextEditingController();
  final _pinController = TextEditingController();
  final _noteController = TextEditingController();

  _PaymentStep _currentStep = _PaymentStep.merchant;
  MerchantPaymentTarget? _merchantTarget;
  MerchantPaymentResult? _paymentResult;
  String? _idempotencyKey;
  bool _isLoading = false;

  @override
  void dispose() {
    _merchantNumberController.dispose();
    _amountController.dispose();
    _pinController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _resolveMerchant() async {
    final merchantNumber = _merchantNumberController.text.trim();
    if (merchantNumber.length < 3) {
      _showMessage('Enter a valid merchant number or merchant ID.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final target = await ref
          .read(paymentRepositoryProvider)
          .resolveMerchant(merchantNumber: merchantNumber);
      setState(() {
        _merchantTarget = target;
        _idempotencyKey = null;
        _currentStep = _PaymentStep.amount;
        _isLoading = false;
      });
    } catch (error) {
      setState(() => _isLoading = false);
      _showMessage(_friendlyError(error, fallback: 'Merchant lookup failed.'));
    }
  }

  Future<void> _payMerchant() async {
    final target = _merchantTarget;
    if (target == null) {
      _showMessage('Resolve a valid merchant first.');
      return;
    }

    final amountText = _amountController.text.trim();
    final amount = double.tryParse(amountText);
    if (amount == null || amount < 1) {
      _showMessage('Enter a valid amount (minimum 1.00).');
      return;
    }

    final pin = _pinController.text.trim();
    if (pin.length != 5) {
      _showMessage('Enter your 5-digit PIN.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repository = ref.read(paymentRepositoryProvider);
      final result = await repository.payMerchant(
        merchantNumber: target.merchantNumber,
        amount: amount,
        pin: pin,
        idempotencyKey: _idempotencyKey ??= repository.createIdempotencyKey(),
        note: _noteController.text.trim(),
      );
      ref.read(walletRefreshProvider)();
      ref.read(transactionRefreshProvider)();
      setState(() {
        _paymentResult = result;
        _currentStep = _PaymentStep.result;
        _isLoading = false;
      });
    } catch (error) {
      setState(() => _isLoading = false);
      _showMessage(_friendlyError(error, fallback: 'Payment failed.'));
    }
  }

  void _reset() {
    setState(() {
      _currentStep = _PaymentStep.merchant;
      _merchantTarget = null;
      _paymentResult = null;
      _idempotencyKey = null;
      _merchantNumberController.clear();
      _amountController.clear();
      _pinController.clear();
      _noteController.clear();
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
        title: const Text('Merchant Payment'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentStep) {
      case _PaymentStep.merchant:
        return _buildMerchantStep();
      case _PaymentStep.amount:
        return _buildAmountStep();
      case _PaymentStep.pin:
        return _buildPinStep();
      case _PaymentStep.result:
        return _buildResultStep();
    }
  }

  Widget _buildMerchantStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Merchant Number',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF263238),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Enter a registered active merchant number before payment.',
          style: TextStyle(color: Color(0xFF607D8B)),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _merchantNumberController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Merchant Number',
            hintText: 'MERCH-001 / 01XXXXXXXXX',
            border: OutlineInputBorder(),
          ),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          onSubmitted: (_) {
            if (!_isLoading) {
              _resolveMerchant();
            }
          },
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _resolveMerchant,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF008F7A),
              foregroundColor: Colors.white,
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : const Text(
                    'Next: Enter Amount',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildAmountStep() {
    final target = _merchantTarget;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _merchantCard(target),
        const SizedBox(height: 24),
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
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(_amountController.text.trim());
              if (amount == null || amount < 1) {
                _showMessage('Enter a valid amount.');
                return;
              }
              setState(() {
                _idempotencyKey ??=
                    ref.read(paymentRepositoryProvider).createIdempotencyKey();
                _currentStep = _PaymentStep.pin;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF008F7A),
              foregroundColor: Colors.white,
            ),
            child: const Text(
              'Next: Enter PIN',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ),
        ),
        TextButton(
          onPressed: () => setState(() {
            _merchantTarget = null;
            _idempotencyKey = null;
            _currentStep = _PaymentStep.merchant;
          }),
          child: const Text('Change Merchant'),
        ),
      ],
    );
  }

  Widget _buildPinStep() {
    final target = _merchantTarget;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Confirm with PIN',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF263238),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Paying BDT ${double.tryParse(_amountController.text.trim())?.toStringAsFixed(2) ?? '0.00'} to ${target?.businessName ?? target?.merchantNumber ?? 'merchant'}',
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
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _payMerchant,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF008F7A),
              foregroundColor: Colors.white,
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : const Text(
                    'Pay Merchant',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
          ),
        ),
        TextButton(
          onPressed: () => setState(() => _currentStep = _PaymentStep.amount),
          child: const Text('Change Amount'),
        ),
      ],
    );
  }

  Widget _buildResultStep() {
    final result = _paymentResult!;
    final isSuccess = result.success;

    return Column(
      children: [
        const SizedBox(height: 20),
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
          isSuccess ? 'Payment Successful!' : 'Payment Failed',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color:
                isSuccess ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          result.message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF607D8B), fontSize: 14),
        ),
        const SizedBox(height: 24),
        Container(
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
              if (result.amount != null)
                _detailRow(
                  'Amount',
                  'BDT ${result.amount!.toStringAsFixed(2)}',
                ),
              if (result.merchantNumber != null)
                _detailRow(
                  'To Merchant',
                  result.businessName ?? result.merchantNumber!,
                ),
              if (result.transactionReference != null)
                _detailRow('Reference', result.transactionReference!),
              if (result.customerBalanceAfter != null)
                _detailRow(
                  'New Balance',
                  'BDT ${result.customerBalanceAfter!.toStringAsFixed(2)}',
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _reset,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF008F7A),
              foregroundColor: Colors.white,
            ),
            child: const Text(
              'Make Another Payment',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ],
    );
  }

  Widget _merchantCard(MerchantPaymentTarget? target) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Color(0xFF0E9F6E),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.store, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  target?.businessName ?? 'N/A',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                Text(
                  target == null
                      ? 'N/A'
                      : '${target.merchantNumber} - ${target.businessType}',
                  style: const TextStyle(
                    color: Color(0xFF607D8B),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              target?.status ?? 'Active',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2E7D32),
              ),
            ),
          ),
        ],
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
              style: const TextStyle(
                color: Color(0xFF263238),
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
