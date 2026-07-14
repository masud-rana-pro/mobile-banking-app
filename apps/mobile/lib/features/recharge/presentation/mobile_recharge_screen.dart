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

enum _RechargeStep { recipient, amount, pin, confirm, result }

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

  _RechargeStep _currentStep = _RechargeStep.recipient;
  String _selectedOperator = _operators.first.value;
  ResolvedRecipientProfile? _recipientProfile;
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

  Future<void> _continueToAmount() async {
    final mobile = _mobileController.text.trim();

    if (!RegExp(r'^[0-9]{10,15}$').hasMatch(mobile)) {
      _showMessage('Enter a valid mobile number with 10 to 15 digits.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final profile = await ref
          .read(recipientProfileRepositoryProvider)
          .tryResolveByMobileNumber(mobile);
      setState(() {
        _recipientProfile = profile;
        _currentStep = _RechargeStep.amount;
        _isLoading = false;
      });
    } catch (error) {
      setState(() => _isLoading = false);
      _showMessage(
          _friendlyError(error, fallback: 'Could not resolve number.'));
    }
  }

  void _continueToPin() {
    final amount = double.tryParse(_amountController.text.trim());

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
      double? latestBalance = result.balanceAfter;
      ref.read(walletRefreshProvider)();
      try {
        latestBalance = (await ref.read(walletSummaryProvider.future)).balance;
      } catch (_) {
        latestBalance = result.balanceAfter;
      }
      ref.read(mobileRechargeRefreshProvider)();
      ref.read(transactionRefreshProvider)();
      if (!mounted) {
        return;
      }
      setState(() {
        _rechargeResult = result.copyWith(balanceAfter: latestBalance);
        _currentStep = _RechargeStep.result;
        _isLoading = false;
      });
    } catch (error) {
      setState(() => _isLoading = false);
      _showMessage(_friendlyError(error, fallback: 'Recharge failed.'));
    }
  }

  void _continueToConfirm() {
    if (_pinController.text.trim().length != 5) {
      _showMessage('Enter your 5-digit PIN.');
      return;
    }
    setState(() => _currentStep = _RechargeStep.confirm);
  }

  void _reset() {
    setState(() {
      _currentStep = _RechargeStep.recipient;
      _recipientProfile = null;
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
    final isPopupStep = _currentStep == _RechargeStep.confirm ||
        _currentStep == _RechargeStep.result;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mobile Recharge'),
        centerTitle: true,
      ),
      bottomNavigationBar: isPopupStep ? null : _bottomKeypad(),
      body: isPopupStep
          ? _buildBody()
          : SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
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
                  ),
                ],
              ),
            ),
    );
  }

  Widget? _bottomKeypad() {
    if (_currentStep == _RechargeStep.recipient) {
      return SafeArea(
        top: false,
        child: NumberProceedKeypadBar(
          controller: _mobileController,
          label: 'Next: Enter Amount',
          loading: _isLoading,
          enabled: _mobileController.text.trim().isNotEmpty && !_isLoading,
          onChanged: (_) => setState(() => _recipientProfile = null),
          onProceed: () {
            _continueToAmount();
          },
        ),
      );
    }

    if (_currentStep == _RechargeStep.pin) {
      return SafeArea(
        top: false,
        child: PinConfirmKeypadBar(
          pinController: _pinController,
          loading: _isLoading,
          canConfirm: !_isLoading,
          onConfirm: _continueToConfirm,
        ),
      );
    }

    return null;
  }

  Widget _buildBody() {
    switch (_currentStep) {
      case _RechargeStep.recipient:
        return _buildRecipientStep();
      case _RechargeStep.amount:
        return _buildAmountStep();
      case _RechargeStep.pin:
        return _buildPinStep();
      case _RechargeStep.confirm:
        return _buildConfirmStep();
      case _RechargeStep.result:
        return _buildResultStep();
    }
  }

  Widget _buildRecipientStep() {
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
          'Recharge amount will be debited from your SmartKash wallet.',
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
        ContactNumberInput(
          controller: _mobileController,
          labelText: 'Mobile Number',
          hintText: '01XXXXXXXXX',
          contactButtonLabel: 'Contacts',
          qrButtonLabel: 'Scan QR',
          onChanged: (_) => setState(() => _recipientProfile = null),
          loading: _isLoading,
          proceedButtonLabel: 'Next: Enter Amount',
          showInlineKeypad: false,
          onProceed: () {
            _continueToAmount();
          },
        ),
      ],
    );
  }

  Widget _buildAmountStep() {
    final balanceText = ref.watch(walletSummaryProvider).maybeWhen(
          data: (wallet) => '৳${wallet.balance.toStringAsFixed(2)}',
          orElse: () => null,
        );
    final mobileNumber = _mobileController.text.trim();
    final recipient = _recipientProfile;
    final operator =
        _operators.firstWhere((item) => item.value == _selectedOperator).label;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AmountRecipientCard(
          label: 'Recipient',
          title: recipient?.displayName ?? mobileNumber,
          subtitle: recipient == null ? operator : '$mobileNumber - $operator',
          imageUrl: recipient?.avatarUrl,
          fallbackIcon: Icons.phone_android,
          trailing: CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFFE9F8F4),
            child: Text(
              _selectedOperator.substring(0, 1),
              style: const TextStyle(
                color: Color(0xFF008F7A),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        AmountEntryPanel(
          controller: _amountController,
          tabs: const ['Amount', 'Internet', 'Voice', 'Bundle', 'Rate Cutter'],
          presets: const [19, 100, 239],
          availableBalanceText: balanceText,
          proceedLabel: 'Proceed',
          onProceed: _continueToPin,
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
        TextButton.icon(
          onPressed: _isLoading
              ? null
              : () => setState(() => _currentStep = _RechargeStep.recipient),
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Change Number'),
        ),
      ],
    );
  }

  Widget _buildPinStep() {
    final amount =
        double.tryParse(_amountController.text.trim())?.toStringAsFixed(2) ??
            '0.00';
    final mobile = _mobileController.text.trim();
    final recipient = _recipientProfile;
    final operator =
        _operators.firstWhere((item) => item.value == _selectedOperator).label;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PinEntryPanel(
          pinController: _pinController,
          actionTitle: 'Mobile Recharge',
          amountText: '৳$amount',
          totalText: '৳$amount',
          typeLabel: 'Prepaid',
          secondaryTypeLabel: 'Postpaid',
          loading: _isLoading,
          onConfirm: _continueToConfirm,
          onBackToAmount: () =>
              setState(() => _currentStep = _RechargeStep.amount),
          showInlineKeypad: false,
          recipient: AmountRecipientCard(
            label: 'Recipient',
            title: recipient?.displayName ?? mobile,
            subtitle: recipient == null ? operator : '$mobile - $operator',
            imageUrl: recipient?.avatarUrl,
            fallbackIcon: Icons.phone_android,
            trailing: CircleAvatar(
              radius: 24,
              backgroundColor: const Color(0xFFE9F8F4),
              child: Text(
                operator.substring(0, 1),
                style: const TextStyle(
                  color: Color(0xFF008F7A),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmStep() {
    final amount =
        double.tryParse(_amountController.text.trim())?.toStringAsFixed(2) ??
            '0.00';
    final mobile = _mobileController.text.trim();
    final recipient = _recipientProfile;
    final operator =
        _operators.firstWhere((item) => item.value == _selectedOperator).label;

    return HoldToConfirmScreen(
      actionName: 'Mobile Recharge',
      accountName: recipient?.displayName ?? mobile,
      accountNumber: recipient == null ? operator : '$mobile - $operator',
      avatarUrl: recipient?.avatarUrl,
      avatarIcon: Icons.phone_android_outlined,
      isLoading: _isLoading,
      onCancel: () => setState(() => _currentStep = _RechargeStep.pin),
      onConfirmed: _submitRecharge,
      details: [
        HoldToConfirmDetail(
            label: 'Total', value: 'Tk $amount', mutedValue: '+ No charge'),
        const HoldToConfirmDetail(label: 'Type', value: 'Prepaid'),
        HoldToConfirmDetail(label: 'Mobile Operator', value: operator),
        HoldToConfirmDetail(label: 'Number', value: mobile),
      ],
    );
  }

  Widget _buildResultStep() {
    final result = _rechargeResult!;
    final isSuccess = result.status == 'SUCCESS';
    final recipient = _recipientProfile;

    return TransactionConfirmationScreen(
      success: isSuccess,
      actionName: 'Mobile Recharge',
      message: isSuccess
          ? 'Your mobile recharge is successful'
          : 'Mobile recharge failed',
      accountName: recipient?.displayName ?? result.mobileNumber,
      accountNumber: recipient == null
          ? result.operator
          : '${result.mobileNumber} - ${result.operator}',
      avatarUrl: recipient?.avatarUrl,
      avatarIcon: Icons.phone_android_outlined,
      totalText: '৳${result.amount.toStringAsFixed(2)}',
      transactionId: result.transactionReference,
      time: result.createdAt,
      newBalanceText: result.balanceAfter == null
          ? null
          : '৳${result.balanceAfter!.toStringAsFixed(2)}',
      typeText: 'Prepaid',
      extraLabel: 'Mobile Operator',
      extraValue: result.operator,
      secondaryLabel: 'View Inbox',
      onSecondaryAction: () =>
          context.pushNamed(NotificationInboxScreen.routeName),
      primaryLabel: 'Recharge Again',
      onPrimaryAction: _reset,
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
