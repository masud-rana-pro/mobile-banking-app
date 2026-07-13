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
import '../domain/merchant_payment_result.dart';
import '../domain/merchant_payment_target.dart';
import '../providers/payment_providers.dart';

class MerchantPaymentScreen extends ConsumerStatefulWidget {
  const MerchantPaymentScreen({
    this.initialMerchantNumber,
    super.key,
  });

  static const routeName = 'merchant-payment';
  static const routePath = '/merchant-payment';

  final String? initialMerchantNumber;

  @override
  ConsumerState<MerchantPaymentScreen> createState() =>
      _MerchantPaymentScreenState();
}

enum _PaymentStep { merchant, amount, pin, confirm, result }

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
  void initState() {
    super.initState();
    final merchantNumber = widget.initialMerchantNumber?.trim();
    if (merchantNumber != null && merchantNumber.isNotEmpty) {
      _merchantNumberController.text = merchantNumber;
      Future.microtask(_resolveMerchant);
    }
  }

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

  void _continueToConfirm() {
    if (_pinController.text.trim().length != 5) {
      _showMessage('Enter your 5-digit PIN.');
      return;
    }
    setState(() => _currentStep = _PaymentStep.confirm);
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
    final isConfirmStep = _currentStep == _PaymentStep.confirm;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Merchant Payment'),
        centerTitle: true,
      ),
      body: isConfirmStep
          ? _buildBody()
          : SingleChildScrollView(
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
      case _PaymentStep.confirm:
        return _buildConfirmStep();
      case _PaymentStep.result:
        return _buildResultStep();
    }
  }

  Widget _buildMerchantStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FeatureIntroCard(
          icon: Icons.shopping_bag_outlined,
          title: 'Merchant Payment',
          subtitle:
              'Pay an active SmartKash merchant from your wallet. PIN confirmation is required.',
        ),
        const SizedBox(height: 22),
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
          label: const Text('Scan merchant QR'),
        ),
        const SizedBox(height: 18),
        PrimaryActionButton(
          label: 'Next: Enter Amount',
          loading: _isLoading,
          onPressed: _resolveMerchant,
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
        PrimaryActionButton(
          label: 'Next: Enter PIN',
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
        PrimaryActionButton(
          label: 'Review Payment',
          loading: _isLoading,
          onPressed: _continueToConfirm,
        ),
        TextButton(
          onPressed: () => setState(() => _currentStep = _PaymentStep.amount),
          child: const Text('Change Amount'),
        ),
      ],
    );
  }

  Widget _buildConfirmStep() {
    final target = _merchantTarget!;
    final amount =
        double.tryParse(_amountController.text.trim())?.toStringAsFixed(2) ??
            '0.00';

    return HoldToConfirmScreen(
      actionName: 'Payment',
      accountName: target.businessName,
      accountNumber: target.merchantNumber,
      avatarUrl: target.avatarUrl,
      avatarIcon: Icons.storefront_outlined,
      isLoading: _isLoading,
      onCancel: () => setState(() => _currentStep = _PaymentStep.pin),
      onConfirmed: _payMerchant,
      details: [
        HoldToConfirmDetail(
            label: 'Total', value: 'Tk $amount', mutedValue: '+ No charge'),
        HoldToConfirmDetail(label: 'Merchant Type', value: target.businessType),
        HoldToConfirmDetail(label: 'Merchant', value: target.merchantNumber),
        const HoldToConfirmDetail(label: 'Reference', value: 'SmartKash'),
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
        ReceiptSummaryCard(
          rows: [
            if (result.amount != null)
              ReceiptSummaryRow(
                'Amount',
                'Tk ${result.amount!.toStringAsFixed(2)}',
              ),
            if (result.merchantNumber != null)
              ReceiptSummaryRow(
                'To Merchant',
                result.businessName ?? result.merchantNumber!,
              ),
            if (result.transactionReference != null)
              ReceiptSummaryRow('TrxID', result.transactionReference!),
            if (result.customerBalanceAfter != null)
              ReceiptSummaryRow(
                'New Balance',
                'Tk ${result.customerBalanceAfter!.toStringAsFixed(2)}',
              ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () =>
                    context.pushNamed(NotificationInboxScreen.routeName),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF008F7A),
                  side: const BorderSide(color: Color(0xFF008F7A)),
                  minimumSize: const Size.fromHeight(54),
                ),
                child: const Text(
                  'View Inbox',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: PrimaryActionButton(
                label: 'Pay Again',
                icon: Icons.refresh,
                onPressed: _reset,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _merchantCard(MerchantPaymentTarget? target) {
    return FeatureSectionCard(
      child: Row(
        children: [
          ProfileImageAvatar(
            imageUrl: target?.avatarUrl,
            fallbackIcon: Icons.store,
            radius: 24,
            backgroundColor: const Color(0xFFE9F8F4),
            iconColor: const Color(0xFF008F7A),
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
          StatusPill(
            label: target?.status ?? 'Active',
            color: const Color(0xFF2E7D32),
          ),
        ],
      ),
    );
  }
}
