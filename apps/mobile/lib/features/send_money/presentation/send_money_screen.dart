import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/feature_flow_widgets.dart';
import '../../../shared/widgets/contact_number_input.dart';
import '../../../shared/widgets/hold_to_confirm_screen.dart';
import '../../notification/presentation/notification_inbox_screen.dart';
import '../../qr/presentation/qr_screen.dart';
import '../../transaction/providers/transaction_providers.dart';
import '../../wallet/providers/wallet_providers.dart';
import '../domain/send_money_receiver.dart';
import '../providers/send_money_providers.dart';

class SendMoneyScreen extends ConsumerStatefulWidget {
  const SendMoneyScreen({
    this.initialQrPayload,
    super.key,
  });

  static const routeName = 'send-money';
  static const routePath = '/send-money';

  final String? initialQrPayload;

  @override
  ConsumerState<SendMoneyScreen> createState() => _SendMoneyScreenState();
}

enum _SendStep { receiver, amount, pin, confirm, result }

class _SendMoneyScreenState extends ConsumerState<SendMoneyScreen> {
  final _phoneController = TextEditingController();
  final _amountController = TextEditingController();
  final _pinController = TextEditingController();
  final _noteController = TextEditingController();
  _SendStep _currentStep = _SendStep.receiver;
  SendMoneyReceiver? _resolvedReceiver;
  SendMoneyResult? _sendResult;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final qrPayload = widget.initialQrPayload?.trim();
    if (qrPayload != null && qrPayload.isNotEmpty) {
      Future.microtask(() => _resolveReceiverFromQr(qrPayload));
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _amountController.dispose();
    _pinController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _resolveReceiver() async {
    final phone = _phoneController.text.trim();
    if (phone.length < 10) {
      _showMessage('Enter a valid mobile number (at least 10 digits).');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(sendMoneyRepositoryProvider);
      final receiver = await repo.resolveReceiver(phone);
      setState(() {
        _resolvedReceiver = receiver;
        _currentStep = _SendStep.amount;
        _isLoading = false;
      });
    } catch (error) {
      setState(() => _isLoading = false);
      _showMessage('Receiver not found: $error');
    }
  }

  Future<void> _resolveReceiverFromQr(String qrPayload) async {
    setState(() => _isLoading = true);

    try {
      final repo = ref.read(sendMoneyRepositoryProvider);
      final receiver = await repo.resolveReceiverByQr(qrPayload);
      setState(() {
        _phoneController.text = receiver.mobileNumber;
        _resolvedReceiver = receiver;
        _currentStep = _SendStep.amount;
        _isLoading = false;
      });
    } catch (error) {
      setState(() => _isLoading = false);
      _showMessage('QR receiver not found: $error');
    }
  }

  Future<void> _sendMoney() async {
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
      final repo = ref.read(sendMoneyRepositoryProvider);
      final result = await repo.sendMoney(
        mobileNumber: _resolvedReceiver!.mobileNumber,
        amount: amount,
        pin: pin,
        note: _noteController.text.trim(),
      );
      ref.read(walletRefreshProvider)();
      ref.read(transactionRefreshProvider)();
      setState(() {
        _sendResult = result;
        _currentStep = _SendStep.result;
        _isLoading = false;
      });
    } catch (error) {
      setState(() => _isLoading = false);
      _showMessage('Send Money failed: $error');
    }
  }

  void _continueToConfirm() {
    if (_pinController.text.trim().length != 5) {
      _showMessage('Enter your 5-digit PIN.');
      return;
    }
    setState(() => _currentStep = _SendStep.confirm);
  }

  void _reset() {
    setState(() {
      _currentStep = _SendStep.receiver;
      _resolvedReceiver = null;
      _sendResult = null;
      _phoneController.clear();
      _amountController.clear();
      _pinController.clear();
      _noteController.clear();
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPopupStep =
        _currentStep == _SendStep.confirm || _currentStep == _SendStep.result;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Money'),
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
      case _SendStep.receiver:
        return _buildReceiverStep();
      case _SendStep.amount:
        return _buildAmountStep();
      case _SendStep.pin:
        return _buildPinStep();
      case _SendStep.confirm:
        return _buildConfirmStep();
      case _SendStep.result:
        return _buildResultStep();
    }
  }

  Widget _buildReceiverStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FeatureIntroCard(
          icon: Icons.send_to_mobile,
          title: 'Send Money',
          subtitle:
              'Send money to a registered SmartKash number. Receiver must be active before transfer.',
        ),
        const SizedBox(height: 22),
        ContactNumberInput(
          controller: _phoneController,
          labelText: 'Mobile Number',
          hintText: '01XXXXXXXXX',
          contactButtonLabel: 'Contacts',
          qrButtonLabel: 'Scan QR',
          onChanged: (_) {
            if (_resolvedReceiver != null) {
              setState(() => _resolvedReceiver = null);
            }
          },
          onQrPressed: _isLoading
              ? null
              : () {
                  context.goNamed(
                    QrScreen.routeName,
                    queryParameters: {'tab': 'scan'},
                  );
                },
          loading: _isLoading,
          proceedButtonLabel: 'Find Receiver',
          onProceed: _resolveReceiver,
        ),
      ],
    );
  }

  Widget _buildAmountStep() {
    final receiver = _resolvedReceiver!;
    final balanceText = ref.watch(walletSummaryProvider).maybeWhen(
          data: (wallet) => '৳${wallet.balance.toStringAsFixed(2)}',
          orElse: () => null,
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AmountRecipientCard(
          label: 'Recipient',
          title: receiver.displayName ?? receiver.mobileNumber,
          subtitle: receiver.mobileNumber,
          imageUrl: receiver.avatarUrl,
          trailing: StatusPill(
            label: receiver.isValid ? 'Active' : 'Inactive',
            color: receiver.isValid
                ? const Color(0xFF2E7D32)
                : const Color(0xFFC62828),
          ),
        ),
        const SizedBox(height: 8),
        AmountEntryPanel(
          controller: _amountController,
          tabs: const ['Amount', 'Contact', 'Reference'],
          presets: const [100, 500, 1000],
          availableBalanceText: balanceText,
          proceedLabel: 'Proceed',
          onProceed: () {
            final amount = double.tryParse(_amountController.text.trim());
            if (amount == null || amount < 1) {
              _showMessage('Enter a valid amount.');
              return;
            }
            setState(() => _currentStep = _SendStep.pin);
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
          onPressed: () => setState(() => _currentStep = _SendStep.receiver),
          child: const Text('Change Receiver'),
        ),
      ],
    );
  }

  Widget _buildPinStep() {
    final receiver = _resolvedReceiver!;
    final amount =
        double.tryParse(_amountController.text.trim())?.toStringAsFixed(2) ??
            '0.00';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PinEntryPanel(
          pinController: _pinController,
          actionTitle: 'Send Money',
          amountText: '৳$amount',
          totalText: '৳$amount',
          showTypeSelector: false,
          loading: _isLoading,
          onConfirm: _continueToConfirm,
          onBackToAmount: () => setState(() => _currentStep = _SendStep.amount),
          recipient: AmountRecipientCard(
            label: 'Recipient',
            title: receiver.displayName ?? receiver.mobileNumber,
            subtitle: receiver.mobileNumber,
            imageUrl: receiver.avatarUrl,
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmStep() {
    final receiver = _resolvedReceiver!;
    final amount =
        double.tryParse(_amountController.text.trim())?.toStringAsFixed(2) ??
            '0.00';

    return HoldToConfirmScreen(
      actionName: 'Send Money',
      accountName: receiver.displayName ?? receiver.mobileNumber,
      accountNumber: receiver.mobileNumber,
      avatarUrl: receiver.avatarUrl,
      avatarIcon: Icons.person_outline,
      isLoading: _isLoading,
      onCancel: () => setState(() => _currentStep = _SendStep.pin),
      onConfirmed: _sendMoney,
      details: [
        HoldToConfirmDetail(
            label: 'Total', value: 'Tk $amount', mutedValue: '+ No charge'),
        const HoldToConfirmDetail(label: 'Type', value: 'Wallet Transfer'),
        HoldToConfirmDetail(label: 'Receiver', value: receiver.mobileNumber),
        const HoldToConfirmDetail(label: 'Reference', value: 'SmartKash'),
      ],
    );
  }

  Widget _buildResultStep() {
    final result = _sendResult!;
    final receiver = _resolvedReceiver;
    final amount = result.amount ?? double.tryParse(_amountController.text);

    return TransactionConfirmationScreen(
      success: result.success,
      actionName: 'Send Money',
      message: result.message,
      accountName: receiver?.displayName ??
          result.receiverMobileNumber ??
          receiver?.mobileNumber ??
          'Receiver',
      accountNumber:
          result.receiverMobileNumber ?? receiver?.mobileNumber ?? '',
      avatarUrl: receiver?.avatarUrl,
      avatarIcon: Icons.person_outline,
      totalText: '৳${(amount ?? 0).toStringAsFixed(2)}',
      transactionId: result.transactionReference,
      newBalanceText: result.senderBalanceAfter == null
          ? null
          : '৳${result.senderBalanceAfter!.toStringAsFixed(2)}',
      time: result.createdAt,
      typeText: 'Send Money',
      extraLabel: 'Reference',
      extraValue: 'SmartKash',
      secondaryLabel: 'View Inbox',
      onSecondaryAction: () =>
          context.pushNamed(NotificationInboxScreen.routeName),
      primaryLabel: 'Send Again',
      onPrimaryAction: _reset,
    );
  }
}
