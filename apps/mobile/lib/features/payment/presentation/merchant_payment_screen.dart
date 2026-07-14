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
    final isPopupStep = _currentStep == _PaymentStep.confirm ||
        _currentStep == _PaymentStep.result;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Merchant Payment'),
        centerTitle: true,
      ),
      body: isPopupStep
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
    final balanceText = ref.watch(walletSummaryProvider).maybeWhen(
          data: (wallet) => '৳${wallet.balance.toStringAsFixed(2)}',
          orElse: () => null,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AmountRecipientCard(
          label: 'Merchant',
          title: target?.businessName ?? 'Merchant',
          subtitle: target == null
              ? 'Merchant number'
              : '${target.merchantNumber} - ${target.businessType}',
          imageUrl: target?.avatarUrl,
          fallbackIcon: Icons.storefront_outlined,
          trailing: StatusPill(
            label: target?.status ?? 'Active',
            color: const Color(0xFF2E7D32),
          ),
        ),
        const SizedBox(height: 8),
        AmountEntryPanel(
          controller: _amountController,
          tabs: const ['Amount', 'Merchant', 'Coupon'],
          presets: const [100, 500, 1000],
          availableBalanceText: balanceText,
          proceedLabel: 'Proceed',
          onProceed: () {
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
        const SizedBox(height: 16),
        TextField(
          controller: _noteController,
          maxLength: 120,
          decoration: const InputDecoration(
            labelText: 'Note (optional)',
            border: OutlineInputBorder(),
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
    final target = _merchantTarget!;
    final amount =
        double.tryParse(_amountController.text.trim())?.toStringAsFixed(2) ??
            '0.00';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PinEntryPanel(
          pinController: _pinController,
          actionTitle: 'Payment',
          amountText: '৳$amount',
          totalText: '৳$amount',
          typeLabel: 'Merchant',
          secondaryTypeLabel: 'Offer',
          loading: _isLoading,
          onConfirm: _continueToConfirm,
          onBackToAmount: () =>
              setState(() => _currentStep = _PaymentStep.amount),
          recipient: AmountRecipientCard(
            label: 'Merchant',
            title: target.businessName,
            subtitle: '${target.merchantNumber} - ${target.businessType}',
            imageUrl: target.avatarUrl,
            fallbackIcon: Icons.storefront_outlined,
          ),
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
    final target = _merchantTarget;
    final amount = result.amount ?? double.tryParse(_amountController.text);

    return TransactionConfirmationScreen(
      success: result.success,
      actionName: 'Payment',
      message: result.message,
      accountName: result.businessName ??
          target?.businessName ??
          result.merchantNumber ??
          'Merchant',
      accountNumber: result.merchantNumber ?? target?.merchantNumber ?? '',
      avatarUrl: target?.avatarUrl,
      avatarIcon: Icons.storefront_outlined,
      totalText: '৳${(amount ?? 0).toStringAsFixed(2)}',
      transactionId: result.transactionReference,
      newBalanceText: result.customerBalanceAfter == null
          ? null
          : '৳${result.customerBalanceAfter!.toStringAsFixed(2)}',
      time: result.createdAt,
      typeText: 'Merchant Payment',
      extraLabel: 'Merchant',
      extraValue:
          result.merchantNumber ?? target?.merchantNumber ?? 'SmartKash',
      secondaryLabel: 'View Inbox',
      onSecondaryAction: () =>
          context.pushNamed(NotificationInboxScreen.routeName),
      primaryLabel: 'Pay Again',
      onPrimaryAction: _reset,
    );
  }
}
