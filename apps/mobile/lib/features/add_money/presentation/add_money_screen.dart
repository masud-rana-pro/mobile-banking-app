import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/api_exception.dart';
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
      subtitle: 'Demo bank transfer',
      icon: Icons.account_balance_outlined,
      color: Color(0xFF2446A6),
    ),
    _AddMoneySource(
      value: 'DEMO_CARD',
      label: 'Card',
      subtitle: 'Demo card top-up',
      icon: Icons.credit_card_outlined,
      color: Color(0xFF7A4CC2),
    ),
    _AddMoneySource(
      value: 'MANUAL',
      label: 'Manual',
      subtitle: 'Learning MVP credit',
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
    Future.microtask(() => ref.read(addMoneyRefreshProvider)());
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

      ref.read(walletRefreshProvider)();
      ref.read(addMoneyRefreshProvider)();
      ref.read(transactionRefreshProvider)();
      setState(() {
        _lastResult = result;
        _idempotencyKey = null;
        _amountController.clear();
        _noteController.clear();
      });
      _showMessage('Money added instantly. Check Inbox > Transactions.');
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

  @override
  Widget build(BuildContext context) {
    final requestsAsync = ref.watch(addMoneyRequestsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: const Text('Add Money'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(addMoneyRequestsProvider);
          await ref.read(addMoneyRequestsProvider.future);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
          children: [
            const _InstantTopUpHeader(),
            const SizedBox(height: 18),
            _AmountCard(
              controller: _amountController,
              quickAmounts: _quickAmounts,
              onQuickAmountTap: (amount) {
                _amountController.text = amount.toString();
              },
            ),
            const SizedBox(height: 14),
            _SourceSelector(
              sources: _sources,
              selectedSource: _selectedSource,
              onChanged: (value) => setState(() => _selectedSource = value),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _noteController,
              maxLength: 255,
              decoration: InputDecoration(
                labelText: 'Reference note (optional)',
                hintText: 'Example: demo bank top-up',
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
            if (_lastResult != null) ...[
              const SizedBox(height: 16),
              _SuccessCard(result: _lastResult!),
            ],
            const SizedBox(height: 28),
            const Text(
              'Recent Add Money',
              style: TextStyle(
                color: Color(0xFF263238),
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            _RecentAddMoneyList(requestsAsync: requestsAsync),
          ],
        ),
      ),
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
                  'No admin approval in this learning MVP. Submit amount and your wallet is credited immediately.',
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

class _AmountCard extends StatelessWidget {
  const _AmountCard({
    required this.controller,
    required this.quickAmounts,
    required this.onQuickAmountTap,
  });

  final TextEditingController controller;
  final List<int> quickAmounts;
  final ValueChanged<int> onQuickAmountTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Amount',
              prefixText: 'Tk ',
              border: UnderlineInputBorder(),
            ),
            style: const TextStyle(
              color: Color(0xFF263238),
              fontSize: 30,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final amount in quickAmounts)
                ActionChip(
                  label: Text('Tk $amount'),
                  onPressed: () => onQuickAmountTap(amount),
                  backgroundColor: const Color(0xFFE9F8F4),
                  labelStyle: const TextStyle(
                    color: Color(0xFF008F7A),
                    fontWeight: FontWeight.w800,
                  ),
                  side: const BorderSide(color: Color(0xFFBFE8DD)),
                ),
            ],
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

class _SuccessCard extends StatelessWidget {
  const _SuccessCard({required this.result});

  final AddMoneySummary result;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFC8E6C9)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 34),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Tk ${result.amount.toStringAsFixed(2)} added successfully. A transaction history item was created.',
              style: const TextStyle(
                color: Color(0xFF1B5E20),
                fontWeight: FontWeight.w800,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentAddMoneyList extends StatelessWidget {
  const _RecentAddMoneyList({required this.requestsAsync});

  final AsyncValue<List<AddMoneySummary>> requestsAsync;

  @override
  Widget build(BuildContext context) {
    return requestsAsync.when(
      data: (requests) {
        if (requests.isEmpty) {
          return const _EmptyAddMoney();
        }

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: requests.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              return _AddMoneyTile(request: requests[index]);
            },
          ),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(22),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Could not load Add Money history: $error',
          style: const TextStyle(color: Color(0xFFB42318)),
        ),
      ),
    );
  }
}

class _EmptyAddMoney extends StatelessWidget {
  const _EmptyAddMoney();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Column(
        children: [
          Icon(Icons.account_balance_wallet_outlined,
              size: 44, color: Color(0xFFB0BEC5)),
          SizedBox(height: 10),
          Text(
            'No Add Money records yet',
            style: TextStyle(
              color: Color(0xFF607D8B),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddMoneyTile extends StatelessWidget {
  const _AddMoneyTile({required this.request});

  final AddMoneySummary request;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      leading: Container(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(
          color: Color(0xFFE9F8F4),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.add_card_outlined, color: Color(0xFF008F7A)),
      ),
      title: Text(
        '+ Tk ${request.amount.toStringAsFixed(2)}',
        style: const TextStyle(
          color: Color(0xFF008F7A),
          fontWeight: FontWeight.w900,
        ),
      ),
      subtitle: Text('${request.sourceLabel} - ${request.shortDate}'),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(999),
        ),
        child: const Text(
          'Success',
          style: TextStyle(
            color: Color(0xFF2E7D32),
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
