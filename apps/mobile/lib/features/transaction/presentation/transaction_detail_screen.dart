import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/transaction_summary.dart';
import '../providers/transaction_providers.dart';

class TransactionDetailScreen extends ConsumerWidget {
  const TransactionDetailScreen({super.key, required this.transactionId});

  static const routeName = 'transaction-detail';
  static const routePath = '/transactions/:id';

  final int transactionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(transactionDetailProvider(transactionId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Details'),
        centerTitle: true,
      ),
      body: detailAsync.when(
        data: (tx) => _TransactionDetailContent(transaction: tx),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  size: 48, color: Color(0xFFB42318)),
              const SizedBox(height: 12),
              Text(
                'Could not load transaction details',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TransactionDetailContent extends StatelessWidget {
  const _TransactionDetailContent({required this.transaction});

  final TransactionSummary transaction;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: transaction.isCredit
                  ? const Color(0xFFE8F5E9)
                  : const Color(0xFFFFEBEE),
              shape: BoxShape.circle,
            ),
            child: Icon(
              transaction.isCredit ? Icons.arrow_downward : Icons.arrow_upward,
              color: transaction.isCredit
                  ? const Color(0xFF2E7D32)
                  : const Color(0xFFC62828),
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            transaction.amountFormatted,
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: transaction.isCredit
                  ? const Color(0xFF0E9F6E)
                  : const Color(0xFFB42318),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            transaction.typeLabel,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF263238),
            ),
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
                _DetailRow(label: 'Status', value: transaction.statusLabel),
                const Divider(),
                _DetailRow(
                    label: 'Reference',
                    value: transaction.transactionReference),
                const Divider(),
                _DetailRow(
                    label: 'Date',
                    value:
                        '${transaction.createdAt.day}/${transaction.createdAt.month}/${transaction.createdAt.year} '
                        '${transaction.createdAt.hour.toString().padLeft(2, '0')}:'
                        '${transaction.createdAt.minute.toString().padLeft(2, '0')}'),
                if (transaction.counterpartyMobileNumber != null) ...[
                  const Divider(),
                  _DetailRow(
                      label: 'Counterparty',
                      value: transaction.counterpartyMobileNumber!),
                ],
                if (transaction.description != null &&
                    transaction.description!.isNotEmpty) ...[
                  const Divider(),
                  _DetailRow(
                      label: 'Description', value: transaction.description!),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF607D8B),
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF263238),
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
