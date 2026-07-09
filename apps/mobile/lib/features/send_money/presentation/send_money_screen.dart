import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/send_money_repository.dart';
import '../domain/send_money_receiver.dart';
import '../providers/send_money_providers.dart';

class SendMoneyScreen extends ConsumerStatefulWidget {
  const SendMoneyScreen({super.key});

  static const routeName = 'send-money';
  static const routePath = '/send-money';

  @override
  ConsumerState<SendMoneyScreen> createState() => _SendMoneyScreenState();
}

enum _SendStep { receiver, amount, pin, result }

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Money'),
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
      case _SendStep.receiver:
        return _buildReceiverStep();
      case _SendStep.amount:
        return _buildAmountStep();
      case _SendStep.pin:
        return _buildPinStep();
      case _SendStep.result:
        return _buildResultStep();
    }
  }

  Widget _buildReceiverStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Receiver Mobile Number',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF263238),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Enter the SmartKash account number to send money to.',
          style: TextStyle(color: Color(0xFF607D8B)),
        ),
        const SizedBox(height: 20),
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
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _resolveReceiver,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF008F7A),
              foregroundColor: Colors.white,
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5),
                  )
                : const Text('Find Receiver',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ),
        ),
      ],
    );
  }

  Widget _buildAmountStep() {
    final receiver = _resolvedReceiver!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
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
                child: const Icon(Icons.person, color: Colors.white, size: 28),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: receiver.isValid
                      ? const Color(0xFF2E7D32).withValues(alpha: 0.1)
                      : const Color(0xFFC62828).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  receiver.isValid ? 'Active' : 'Inactive',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: receiver.isValid
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFFC62828),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _amountController,
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Amount (BDT)',
            prefixText: '৳ ',
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
              setState(() => _currentStep = _SendStep.pin);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF008F7A),
              foregroundColor: Colors.white,
            ),
            child: const Text('Next: Enter PIN',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
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
          'Sending ৳ ${double.tryParse(_amountController.text.trim())?.toStringAsFixed(2) ?? '0.00'} to ${_resolvedReceiver?.mobileNumber}',
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
            onPressed: _isLoading ? null : _sendMoney,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF008F7A),
              foregroundColor: Colors.white,
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5),
                  )
                : const Text('Send Money',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ),
        ),
        TextButton(
          onPressed: () => setState(() => _currentStep = _SendStep.amount),
          child: const Text('Change Amount'),
        ),
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
                _detailRow('Amount', '৳ ${result.amount!.toStringAsFixed(2)}'),
              if (result.receiverMobileNumber != null)
                _detailRow('To', result.receiverMobileNumber!),
              if (result.transactionReference != null)
                _detailRow('Reference', result.transactionReference!),
              if (result.senderBalanceAfter != null)
                _detailRow('New Balance',
                    '৳ ${result.senderBalanceAfter!.toStringAsFixed(2)}'),
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
            child: const Text('Send Again',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ),
        ),
      ],
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  color: Color(0xFF607D8B), fontWeight: FontWeight.w600)),
          Text(value,
              style: const TextStyle(
                  color: Color(0xFF263238), fontWeight: FontWeight.w700),
              textAlign: TextAlign.end),
        ],
      ),
    );
  }
}
