import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/api_exception.dart';
import '../../../shared/widgets/feature_flow_widgets.dart';
import '../../transaction/providers/transaction_providers.dart';
import '../../wallet/providers/wallet_providers.dart';
import '../domain/add_money_summary.dart';
import '../providers/add_money_providers.dart';

class AddMoneyScreen extends ConsumerStatefulWidget {
  const AddMoneyScreen({super.key});

  static const routeName = 'add-money';
  static const routePath = '/add-money';

  @override
  ConsumerState<AddMoneyScreen> createState() => _AddMoneyScreenState();
}

class _AddMoneySource {
  const _AddMoneySource({
    required this.value,
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String value;
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
}

class _AddMoneyScreenState extends ConsumerState<AddMoneyScreen> {
  static const _sources = [
    _AddMoneySource(
      value: 'DEMO_BANK',
      label: 'Bank',
      subtitle: 'Bank transfer',
      icon: Icons.account_balance_outlined,
      color: Color(0xFF2446A6),
    ),
    _AddMoneySource(
      value: 'DEMO_CARD',
      label: 'Card',
      subtitle: 'Card top-up',
      icon: Icons.credit_card_outlined,
      color: Color(0xFF7A4CC2),
    ),
    _AddMoneySource(
      value: 'MANUAL',
      label: 'Manual',
      subtitle: 'Direct wallet credit',
      icon: Icons.account_balance_wallet_outlined,
      color: Color(0xFF008F7A),
    ),
  ];

  static const _quickAmounts = [100, 500, 1000, 2000, 5000, 10000];

  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  String _selectedSource = _sources.first.value;
  String? _idempotencyKey;
  AddMoneySummary? _lastResult;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submitAddMoney() async {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount < 1) {
      _showMessage('Enter a valid amount. Minimum amount is Tk 1.00.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final repository = ref.read(addMoneyRepositoryProvider);
      final result = await repository.createRequest(
        amount: amount,
        sourceType: _selectedSource,
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
      ref.read(addMoneyRefreshProvider)();
      ref.read(transactionRefreshProvider)();
      if (!mounted) {
        return;
      }
      setState(() {
        _lastResult = AddMoneySummary(
          id: result.id,
          amount: result.amount,
          sourceType: result.sourceType,
          status: result.status,
          note: result.note,
          transactionReference: result.transactionReference,
          balanceAfter: latestBalance,
          approvedAt: result.approvedAt,
          createdAt: result.createdAt,
        );
        _idempotencyKey = null;
        _amountController.clear();
        _noteController.clear();
      });
    } catch (error) {
      _showMessage(_friendlyError(error));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String _friendlyError(Object error) {
    if (error is ApiException) {
      final details = error.errors.isEmpty ? '' : ' ${error.errors.join(' ')}';
      return '${error.message}$details';
    }
    return 'Add Money failed. Please try again.';
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _reset() {
    setState(() {
      _lastResult = null;
      _idempotencyKey = null;
      _amountController.clear();
      _noteController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final result = _lastResult;
    final balanceText = ref.watch(walletSummaryProvider).maybeWhen(
          data: (wallet) => '৳${wallet.balance.toStringAsFixed(2)}',
          orElse: () => null,
        );

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: const Text('Add Money'),
        centerTitle: true,
      ),
      body: result == null
          ? RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(addMoneyRequestsProvider);
                await ref.read(addMoneyRequestsProvider.future);
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
                children: [
                  const _InstantTopUpHeader(),
                  const SizedBox(height: 18),
                  AmountEntryPanel(
                    controller: _amountController,
                    tabs: const ['Amount', 'Source', 'Reference'],
                    presets: _quickAmounts,
                    availableBalanceText: balanceText,
                    sourceLabel: 'Top Up Source',
                    secondarySourceLabel: 'Later',
                    proceedLabel: 'Proceed',
                    showProceed: false,
                    onProceed: null,
                  ),
                  const SizedBox(height: 14),
                  _SourceSelector(
                    sources: _sources,
                    selectedSource: _selectedSource,
                    onChanged: (value) =>
                        setState(() => _selectedSource = value),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _noteController,
                    maxLength: 255,
                    decoration: InputDecoration(
                      labelText: 'Reference note (optional)',
                      hintText: 'Example: bank top-up reference',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitAddMoney,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF008F7A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Add Money Now',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                SizedBox(width: 10),
                                Icon(Icons.arrow_forward),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const _InboxHistoryHint(),
                ],
              ),
            )
          : _buildResult(result),
    );
  }

  Widget _buildResult(AddMoneySummary result) {
    final success = result.isApproved;
    return TransactionConfirmationScreen(
      success: success,
      actionName: 'Add Money',
      message: success ? 'Your Add Money is successful' : 'Add Money failed',
      accountName: 'SmartKash Wallet',
      accountNumber: result.sourceLabel,
      avatarIcon: Icons.account_balance_wallet_outlined,
      totalText: '৳${result.amount.toStringAsFixed(2)}',
      transactionId: result.transactionReference,
      time: result.approvedAt ?? result.createdAt,
      newBalanceText: result.balanceAfter == null
          ? null
          : '৳${result.balanceAfter!.toStringAsFixed(2)}',
      typeText: result.sourceLabel,
      extraLabel: 'Status',
      extraValue: result.statusLabel,
      primaryLabel: 'Add Money Again',
      onPrimaryAction: _reset,
    );
  }
}

class _InstantTopUpHeader extends StatelessWidget {
  const _InstantTopUpHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF008F7A), Color(0xFF2446A6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        children: [
          Icon(Icons.bolt_outlined, color: Colors.white, size: 34),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Instant Add Money',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Submit an amount and your SmartKash wallet is credited instantly.',
                  style: TextStyle(
                    color: Color(0xFFEAF7F4),
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceSelector extends StatelessWidget {
  const _SourceSelector({
    required this.sources,
    required this.selectedSource,
    required this.onChanged,
  });

  final List<_AddMoneySource> sources;
  final String selectedSource;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select source',
          style: TextStyle(
            color: Color(0xFF263238),
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        for (final source in sources)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => onChanged(source.value),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: selectedSource == source.value
                        ? source.color
                        : const Color(0xFFE2E8F0),
                    width: selectedSource == source.value ? 1.6 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: source.color.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(source.icon, color: source.color),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            source.label,
                            style: const TextStyle(
                              color: Color(0xFF263238),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            source.subtitle,
                            style: const TextStyle(
                              color: Color(0xFF607D8B),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      selectedSource == source.value
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: selectedSource == source.value
                          ? source.color
                          : const Color(0xFFB0BEC5),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
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
              'All Add Money history is saved in Inbox > Transactions. Open any item there to see receipt details.',
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
