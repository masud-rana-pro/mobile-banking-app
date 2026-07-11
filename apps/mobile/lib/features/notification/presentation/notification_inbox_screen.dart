import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../transaction/domain/transaction_summary.dart';
import '../../transaction/providers/transaction_providers.dart';

class NotificationInboxScreen extends ConsumerStatefulWidget {
  const NotificationInboxScreen({super.key});

  static const routeName = 'notification-inbox';
  static const routePath = '/notifications';

  @override
  ConsumerState<NotificationInboxScreen> createState() =>
      _NotificationInboxScreenState();
}

class _NotificationInboxScreenState
    extends ConsumerState<NotificationInboxScreen> {
  final _searchController = TextEditingController();
  int _selectedTab = 0;
  String _query = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(transactionRefreshProvider)());
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text('Inbox'),
        centerTitle: true,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(Icons.mark_email_unread_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          _InboxTabs(
            selectedTab: _selectedTab,
            onChanged: (index) => setState(() => _selectedTab = index),
          ),
          Expanded(
            child: _selectedTab == 0
                ? _TransactionInboxTab(
                    searchController: _searchController,
                    query: _query,
                  )
                : const _NotificationOffersTab(),
          ),
        ],
      ),
    );
  }
}

class _InboxTabs extends StatelessWidget {
  const _InboxTabs({
    required this.selectedTab,
    required this.onChanged,
  });

  final int selectedTab;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Row(
        children: [
          _InboxTabButton(
            label: 'Transactions',
            isSelected: selectedTab == 0,
            onTap: () => onChanged(0),
          ),
          _InboxTabButton(
            label: 'Notifications',
            isSelected: selectedTab == 1,
            onTap: () => onChanged(1),
          ),
        ],
      ),
    );
  }
}

class _InboxTabButton extends StatelessWidget {
  const _InboxTabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 58,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected
                    ? const Color(0xFF008F7A)
                    : const Color(0xFFE2E8F0),
                width: isSelected ? 3 : 1,
              ),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? const Color(0xFF008F7A)
                  : const Color(0xFF607D8B),
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _TransactionInboxTab extends ConsumerWidget {
  const _TransactionInboxTab({
    required this.searchController,
    required this.query,
  });

  final TextEditingController searchController;
  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionListProvider);

    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by TrxID or number',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
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
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Filter options will be added later.'),
                    ),
                  );
                },
                icon: const Icon(Icons.tune),
                label: const Text('Filter'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF008F7A),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  minimumSize: const Size(104, 54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
              ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 18, 20, 12),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Transactions from the last 90 days',
              style: TextStyle(
                color: Color(0xFF607D8B),
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        Expanded(
          child: transactionsAsync.when(
            data: (transactions) {
              final filtered = _filterTransactions(transactions, query);
              if (filtered.isEmpty) {
                return const _EmptyTransactions();
              }

              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(transactionListProvider);
                  await ref.read(transactionListProvider.future);
                },
                child: ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final transaction = filtered[index];
                    return _InboxTransactionTile(
                      transaction: transaction,
                      onTap: () => _showTransactionSheet(context, transaction),
                    );
                  },
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => _ErrorState(
              message: 'Could not load transaction history.',
              onRetry: () => ref.invalidate(transactionListProvider),
            ),
          ),
        ),
      ],
    );
  }

  List<TransactionSummary> _filterTransactions(
    List<TransactionSummary> transactions,
    String query,
  ) {
    if (query.isEmpty) return transactions;

    return transactions.where((transaction) {
      final reference = transaction.transactionReference.toLowerCase();
      final counterparty =
          transaction.counterpartyMobileNumber?.toLowerCase() ?? '';
      final type = transaction.typeLabel.toLowerCase();
      return reference.contains(query) ||
          counterparty.contains(query) ||
          type.contains(query);
    }).toList();
  }

  void _showTransactionSheet(
    BuildContext context,
    TransactionSummary transaction,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) => _TransactionReceiptSheet(transaction: transaction),
    );
  }
}

class _InboxTransactionTile extends StatelessWidget {
  const _InboxTransactionTile({
    required this.transaction,
    required this.onTap,
  });

  final TransactionSummary transaction;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(20, 16, 14, 16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: transaction.iconColor.withValues(alpha: 0.12),
              child: Icon(transaction.icon, color: transaction.iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.typeLabel,
                    style: const TextStyle(
                      color: Color(0xFF263238),
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    transaction.counterpartyMobileNumber ??
                        transaction.description ??
                        'SmartKash',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF607D8B),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'TrxID : ${transaction.transactionReference}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF455A64),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  transaction.amountFormatted,
                  style: TextStyle(
                    color: transaction.isCredit
                        ? const Color(0xFF008F7A)
                        : const Color(0xFFB42318),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  transaction.displayDate,
                  style: const TextStyle(
                    color: Color(0xFF455A64),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                const Icon(Icons.chevron_right, color: Color(0xFFB0BEC5)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionReceiptSheet extends StatelessWidget {
  const _TransactionReceiptSheet({required this.transaction});

  final TransactionSummary transaction;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        transaction.typeLabel,
                        style: const TextStyle(
                          color: Color(0xFF263238),
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              GridView.count(
                crossAxisCount: 2,
                childAspectRatio: 1.72,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _ReceiptCell(
                    label: 'Account',
                    value: transaction.counterpartyMobileNumber ?? 'SmartKash',
                  ),
                  _ReceiptCell(label: 'Time', value: transaction.displayDate),
                  _ReceiptCell(
                    label: 'Amount',
                    value: transaction.amountFormatted,
                    valueColor: transaction.isCredit
                        ? const Color(0xFF008F7A)
                        : const Color(0xFFB42318),
                  ),
                  const _ReceiptCell(label: 'Charge', value: 'Tk 0.00'),
                  _ReceiptCell(
                    label: 'Transaction ID',
                    value: transaction.transactionReference,
                    canCopy: true,
                  ),
                  _ReceiptCell(
                    label: 'Reference',
                    value: transaction.description ?? '-',
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 26),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Again'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF008F7A),
                          side: const BorderSide(color: Color(0xFF008F7A)),
                          minimumSize: const Size.fromHeight(52),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Clipboard.setData(
                            ClipboardData(
                              text:
                                  '${transaction.typeLabel} ${transaction.amountFormatted} ${transaction.transactionReference}',
                            ),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Transaction copied.'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.share_outlined),
                        label: const Text('Share'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF008F7A),
                          side: const BorderSide(color: Color(0xFF008F7A)),
                          minimumSize: const Size.fromHeight(52),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReceiptCell extends StatelessWidget {
  const _ReceiptCell({
    required this.label,
    required this.value,
    this.valueColor,
    this.canCopy = false,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool canCopy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE2E8F0), width: 0.6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF607D8B),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: valueColor ?? const Color(0xFF263238),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (canCopy) ...[
                const SizedBox(width: 6),
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: value));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Transaction ID copied.')),
                    );
                  },
                  child: const Icon(
                    Icons.copy,
                    size: 18,
                    color: Color(0xFF607D8B),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _NotificationOffersTab extends StatelessWidget {
  const _NotificationOffersTab();

  static const _items = [
    _NotificationItem(
      title: 'Add Money',
      body:
          'Instant top-up alerts appear after demo bank, card, or manual Add Money succeeds.',
      time: 'Wallet credit',
      color: Color(0xFF008F7A),
      icon: Icons.bolt_outlined,
    ),
    _NotificationItem(
      title: 'Send Money',
      body:
          'Transfer success alerts and receipt history appear for mobile number and QR receiver selection.',
      time: 'Wallet transfer',
      color: Color(0xFF0E9F6E),
      icon: Icons.send_to_mobile,
    ),
    _NotificationItem(
      title: 'Merchant Payment',
      body:
          'Merchant payment completion appears in transaction history for customer and merchant accounts.',
      time: 'Payment',
      color: Color(0xFFE08B2D),
      icon: Icons.shopping_bag_outlined,
    ),
    _NotificationItem(
      title: 'Statement',
      body:
          'Statement view is powered by the same transaction records shown in this Inbox history.',
      time: 'Records',
      color: Color(0xFF2446A6),
      icon: Icons.article_outlined,
    ),
    _NotificationItem(
      title: 'Transactions',
      body:
          'Use Inbox > Transactions to search TrxID, open receipts, copy IDs, and review money movement.',
      time: 'History',
      color: Color(0xFF2446A6),
      icon: Icons.receipt_long_outlined,
    ),
    _NotificationItem(
      title: 'Cash Out',
      body:
          'Demo Cash Out now debits wallet, creates ledger entries, and appears in transaction receipts.',
      time: 'Agent demo',
      color: Color(0xFF00A8A8),
      icon: Icons.payments_outlined,
    ),
    _NotificationItem(
      title: 'Pay Bill',
      body:
          'Demo bill payments now debit wallet, create receipts, and appear in transaction history.',
      time: 'Biller demo',
      color: Color(0xFF00695C),
      icon: Icons.bolt_outlined,
    ),
    _NotificationItem(
      title: 'Savings',
      body:
          'Savings deposit records appear after wallet-debit deposits into a goal are completed.',
      time: 'Goal deposit',
      color: Color(0xFF9C3A8D),
      icon: Icons.savings_outlined,
    ),
    _NotificationItem(
      title: 'Loan',
      body:
          'Loan request submissions now create pending history records; approval remains status-only in this MVP.',
      time: 'Request status',
      color: Color(0xFF795548),
      icon: Icons.account_balance_outlined,
    ),
    _NotificationItem(
      title: 'Mobile Recharge',
      body:
          'Demo recharge success creates wallet debit history and a receipt without real provider integration.',
      time: 'Recharge',
      color: Color(0xFF1D7ED6),
      icon: Icons.phone_android,
    ),
    _NotificationItem(
      title: 'Local FCM note',
      body:
          'Important push alerts are optional during local testing and can be fully tested after deployment.',
      time: 'MVP',
      color: Color(0xFF7A4CC2),
      icon: Icons.notifications_active_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
      itemCount: _items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final item = _items[index];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 130,
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.12),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(8),
                  ),
                ),
                child: Center(
                  child: Icon(item.icon, size: 66, color: item.color),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        color: Color(0xFF263238),
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.body,
                      style: const TextStyle(
                        color: Color(0xFF607D8B),
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      item.time,
                      style: const TextStyle(
                        color: Color(0xFF90A4AE),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NotificationItem {
  const _NotificationItem({
    required this.title,
    required this.body,
    required this.time,
    required this.color,
    required this.icon,
  });

  final String title;
  final String body;
  final String time;
  final Color color;
  final IconData icon;
}

class _EmptyTransactions extends StatelessWidget {
  const _EmptyTransactions();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 60, color: Color(0xFFB0BEC5)),
          SizedBox(height: 12),
          Text(
            'No matching transactions',
            style: TextStyle(
              color: Color(0xFF607D8B),
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 50, color: Color(0xFFB42318)),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(
              color: Color(0xFF607D8B),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          TextButton(onPressed: onRetry, child: const Text('Try Again')),
        ],
      ),
    );
  }
}
