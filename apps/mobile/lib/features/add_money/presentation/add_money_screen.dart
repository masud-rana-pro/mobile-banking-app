import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/add_money_repository.dart';
import '../domain/add_money_summary.dart';
import '../providers/add_money_providers.dart';

class AddMoneyScreen extends ConsumerStatefulWidget {
  const AddMoneyScreen({super.key});

  static const routeName = 'add-money';
  static const routePath = '/add-money';

  @override
  ConsumerState<AddMoneyScreen> createState() => _AddMoneyScreenState();
}

class _AddMoneyScreenState extends ConsumerState<AddMoneyScreen> {
  final _amountController = TextEditingController();
  String _selectedSource = 'DEMO_BANK';
  final _noteController = TextEditingController();
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

  Future<void> _submitRequest() async {
    final amountText = _amountController.text.trim();
    final amount = double.tryParse(amountText);
    if (amount == null || amount < 1) {
      _showMessage('Enter a valid amount (minimum 1.00).');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final repository = ref.read(addMoneyRepositoryProvider);
      await repository.createRequest(
        amount: amount,
        sourceType: _selectedSource,
        note: _noteController.text.trim(),
      );

      _amountController.clear();
      _noteController.clear();
      ref.invalidate(addMoneyRequestsProvider);
      _showMessage('Add Money request submitted for admin approval.');
    } catch (error) {
      _showMessage('Failed to submit request: $error');
    } finally {
      setState(() => _isSubmitting = false);
    }
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
      appBar: AppBar(
        title: const Text('Add Money'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'New Request',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF263238),
              ),
            ),
            const SizedBox(height: 16),
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
            DropdownButtonFormField<String>(
              value: _selectedSource,
              decoration: const InputDecoration(
                labelText: 'Source',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                    value: 'DEMO_BANK', child: Text('Bank Transfer')),
                DropdownMenuItem(
                    value: 'DEMO_CARD', child: Text('Debit/Credit Card')),
                DropdownMenuItem(
                    value: 'MANUAL', child: Text('Manual Deposit')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _selectedSource = value);
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _noteController,
              maxLength: 255,
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
                onPressed: _isSubmitting ? null : _submitRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF008F7A),
                  foregroundColor: Colors.white,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Text('Submit Request',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'My Requests',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF263238),
              ),
            ),
            const SizedBox(height: 12),
            requestsAsync.when(
              data: (requests) {
                if (requests.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'No requests yet',
                        style: TextStyle(color: Color(0xFF90A4AE)),
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: requests.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final req = requests[index];
                    return _RequestTile(request: req);
                  },
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Could not load requests: $error'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RequestTile extends StatelessWidget {
  const _RequestTile({required this.request});

  final AddMoneySummary request;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: request.isApproved
              ? const Color(0xFFE8F5E9)
              : request.isRejected
                  ? const Color(0xFFFFEBEE)
                  : const Color(0xFFFFF8E1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          request.isApproved
              ? Icons.check_circle
              : request.isRejected
                  ? Icons.cancel
                  : Icons.hourglass_empty,
          color: request.isApproved
              ? const Color(0xFF2E7D32)
              : request.isRejected
                  ? const Color(0xFFC62828)
                  : const Color(0xFFF57F17),
          size: 24,
        ),
      ),
      title: Text(
        '৳ ${request.amount.toStringAsFixed(2)}',
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(request.sourceLabel),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: request.isApproved
              ? const Color(0xFFE8F5E9)
              : request.isRejected
                  ? const Color(0xFFFFEBEE)
                  : const Color(0xFFFFF8E1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          request.statusLabel,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: request.isApproved
                ? const Color(0xFF2E7D32)
                : request.isRejected
                    ? const Color(0xFFC62828)
                    : const Color(0xFFF57F17),
          ),
        ),
      ),
    );
  }
}
