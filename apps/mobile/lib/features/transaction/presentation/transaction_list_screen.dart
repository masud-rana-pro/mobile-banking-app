import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../domain/transaction_summary.dart';
import '../providers/transaction_providers.dart';

class TransactionListScreen extends ConsumerStatefulWidget {
  const TransactionListScreen({super.key});

  static const routeName = 'transactions';
  static const routePath = '/transactions';

  @override
  ConsumerState<TransactionListScreen> createState() =>
      _TransactionListScreenState();
}

class _TransactionListScreenState extends ConsumerState<TransactionListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(transactionRefreshProvider)(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        centerTitle: true,
      ),
      body: transactionsAsync.when(
        data: (transactions) {
          if (transactions.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_outlined,
                      size: 64, color: Color(0xFFB0BEC5)),
                  SizedBox(height: 16),
                  Text(
                    'No transactions yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Color(0xFF607D8B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Send money or add money to get started',
                    style: TextStyle(color: Color(0xFF90A4AE)),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(transactionListProvider);
              await ref.read(transactionListProvider.future);
            },
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: transactions.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final tx = transactions[index];
                return _TransactionTile(
                  transaction: tx,
                  onTap: () => context.pushNamed(
                    'transaction-detail',
                    pathParameters: {'id': tx.id.toString()},
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  size: 48, color: Color(0xFFB42318)),
              const SizedBox(height: 12),
              Text(
                'Could not load transactions',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => ref.invalidate(transactionListProvider),
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({
    required this.transaction,
    required this.onTap,
  });

  final TransactionSummary transaction;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final type = transaction.typeLabel;
    final amount = transaction.amountFormatted;
    final date = transaction.formattedDate;
    final isCredit = transaction.isCredit;
    final status = transaction.statusLabel;
    final counterparty = transaction.counterpartyMobileNumber;

    IconData icon;
    Color iconColor;

    switch (transaction.type) {
      case 'ADD_MONEY':
        icon = Icons.add_card_outlined;
        iconColor = const Color(0xFF7A4CC2);
        break;
      case 'SEND_MONEY':
        icon = Icons.send_to_mobile;
        iconColor = const Color(0xFF0E9F6E);
        break;
      case 'RECEIVE_MONEY':
        icon = Icons.call_received;
        iconColor = const Color(0xFF0E9F6E);
        break;
      case 'MERCHANT_PAYMENT':
        icon = Icons.shopping_bag_outlined;
        iconColor = const Color(0xFFE08B2D);
        break;
      case 'SAVINGS_DEPOSIT':
        icon = Icons.savings_outlined;
        iconColor = const Color(0xFF9C3A8D);
        break;
      case 'MOBILE_RECHARGE':
        icon = Icons.phone_android;
        iconColor = const Color(0xFF1D7ED6);
        break;
      case 'LOAN_REQUEST':
        icon = Icons.account_balance;
        iconColor = const Color(0xFF795548);
        break;
      default:
        icon = Icons.receipt_long;
        iconColor = const Color(0xFF607D8B);
    }

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          type,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        amount,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: isCredit
                              ? const Color(0xFF0E9F6E)
                              : const Color(0xFFB42318),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (counterparty != null) ...[
                        Text(
                          counterparty,
                          style: const TextStyle(
                            color: Color(0xFF607D8B),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 3,
                          height: 3,
                          decoration: const BoxDecoration(
                            color: Color(0xFFB0BEC5),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        date,
                        style: const TextStyle(
                          color: Color(0xFF90A4AE),
                          fontSize: 13,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: status == 'Success'
                              ? const Color(0xFFE8F5E9)
                              : status == 'Pending'
                                  ? const Color(0xFFFFF8E1)
                                  : const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: status == 'Success'
                                ? const Color(0xFF2E7D32)
                                : status == 'Pending'
                                    ? const Color(0xFFF57F17)
                                    : const Color(0xFFC62828),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
