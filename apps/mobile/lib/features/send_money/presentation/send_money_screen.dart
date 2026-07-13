import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/feature_flow_widgets.dart';
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
    final isConfirmStep = _currentStep == _SendStep.confirm;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Money'),
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
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Mobile Number',
            hintText: '01XXXXXXXXX',
            border: OutlineInputBorder(),
          ),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
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
          label: const Text('Scan receiver QR'),
        ),
        const SizedBox(height: 18),
        PrimaryActionButton(
          label: 'Find Receiver',
          loading: _isLoading,
          onPressed: _resolveReceiver,
        ),
      ],
    );
  }

  Widget _buildAmountStep() {
    final receiver = _resolvedReceiver!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FeatureSectionCard(
          child: Row(
            children: [
              ProfileImageAvatar(
                imageUrl: receiver.avatarUrl,
                fallbackIcon: Icons.person,
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
                      receiver.displayName ?? receiver.mobileNumber,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      receiver.mobileNumber,
                      style: const TextStyle(
                        color: Color(0xFF607D8B),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              StatusPill(
                label: receiver.isValid ? 'Active' : 'Inactive',
                color: receiver.isValid
                    ? const Color(0xFF2E7D32)
                    : const Color(0xFFC62828),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Amount (BDT)',
            prefixText: 'Tk ',
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
            setState(() => _currentStep = _SendStep.pin);
          },
        ),
        TextButton(
          onPressed: () => setState(() => _currentStep = _SendStep.receiver),
          child: const Text('Change Receiver'),
        ),
      ],
    );
  }

  Widget _buildPinStep() {
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
          'Sending Tk ${double.tryParse(_amountController.text.trim())?.toStringAsFixed(2) ?? '0.00'} to ${_resolvedReceiver?.mobileNumber}',
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
          label: 'Review Send Money',
          loading: _isLoading,
          onPressed: _continueToConfirm,
        ),
        TextButton(
          onPressed: () => setState(() => _currentStep = _SendStep.amount),
          child: const Text('Change Amount'),
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
          isSuccess ? 'Money Sent!' : 'Transfer Failed',
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
            if (result.receiverMobileNumber != null)
              ReceiptSummaryRow('To', result.receiverMobileNumber!),
            if (result.transactionReference != null)
              ReceiptSummaryRow('TrxID', result.transactionReference!),
            if (result.senderBalanceAfter != null)
              ReceiptSummaryRow(
                'New Balance',
                'Tk ${result.senderBalanceAfter!.toStringAsFixed(2)}',
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
                label: 'Send Again',
                icon: Icons.refresh,
                onPressed: _reset,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
