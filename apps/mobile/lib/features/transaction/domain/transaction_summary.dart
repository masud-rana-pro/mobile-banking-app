import 'package:flutter/material.dart';

class TransactionSummary {
  const TransactionSummary({
    required this.id,
    required this.transactionReference,
    required this.type,
    required this.status,
    required this.amount,
    this.counterpartyUserId,
    this.counterpartyMobileNumber,
    this.description,
    required this.createdAt,
  });

  final int id;
  final String transactionReference;
  final String type;
  final String status;
  final double amount;
  final int? counterpartyUserId;
  final String? counterpartyMobileNumber;
  final String? description;
  final DateTime createdAt;

  factory TransactionSummary.fromJson(Map<String, dynamic> json) {
    return TransactionSummary(
      id: json['id'] as int? ?? 0,
      transactionReference: json['transactionReference'] as String? ?? '',
      type: json['type'] as String? ?? 'SEND_MONEY',
      status: json['status'] as String? ?? 'PENDING',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      counterpartyUserId: json['counterpartyUserId'] as int?,
      counterpartyMobileNumber: json['counterpartyMobileNumber'] as String?,
      description: json['description'] as String?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  String get typeLabel {
    switch (type) {
      case 'ADD_MONEY':
        return 'Add Money';
      case 'SEND_MONEY':
        return 'Send Money';
      case 'RECEIVE_MONEY':
        return 'Received Money';
      case 'MERCHANT_PAYMENT':
        return 'Payment';
      case 'CASH_OUT':
        return 'Cash Out';
      case 'PAY_BILL':
        return 'Pay Bill';
      case 'SAVINGS_DEPOSIT':
        return 'Savings';
      case 'MOBILE_RECHARGE':
        return 'Mobile Recharge';
      case 'LOAN_REQUEST':
        return 'Loan';
      default:
        return type;
    }
  }

  String get statusLabel {
    switch (status) {
      case 'SUCCESS':
        return 'Success';
      case 'PENDING':
        return 'Pending';
      case 'FAILED':
        return 'Failed';
      case 'REJECTED':
        return 'Rejected';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return status;
    }
  }

  bool get isCredit => type == 'ADD_MONEY' || type == 'RECEIVE_MONEY';

  bool get isDebit => !isCredit;

  String get amountFormatted {
    final prefix = isCredit ? '+' : '-';
    return '$prefix Tk ${amount.toStringAsFixed(2)}';
  }

  String get amountColorHex => isCredit ? '0xFF0E9F6E' : '0xFFB42318';

  IconData get icon {
    switch (type) {
      case 'ADD_MONEY':
        return Icons.add_card_outlined;
      case 'SEND_MONEY':
        return Icons.send_to_mobile;
      case 'RECEIVE_MONEY':
        return Icons.call_received;
      case 'MERCHANT_PAYMENT':
        return Icons.shopping_bag_outlined;
      case 'CASH_OUT':
        return Icons.payments_outlined;
      case 'PAY_BILL':
        return Icons.bolt_outlined;
      case 'SAVINGS_DEPOSIT':
        return Icons.savings_outlined;
      case 'MOBILE_RECHARGE':
        return Icons.phone_android;
      case 'LOAN_REQUEST':
        return Icons.account_balance_outlined;
      default:
        return Icons.receipt_long_outlined;
    }
  }

  Color get iconColor {
    switch (type) {
      case 'ADD_MONEY':
        return const Color(0xFF7A4CC2);
      case 'SEND_MONEY':
      case 'RECEIVE_MONEY':
        return const Color(0xFF008F7A);
      case 'MERCHANT_PAYMENT':
        return const Color(0xFFE08B2D);
      case 'CASH_OUT':
        return const Color(0xFF00A8A8);
      case 'PAY_BILL':
        return const Color(0xFF00695C);
      case 'SAVINGS_DEPOSIT':
        return const Color(0xFF9C3A8D);
      case 'MOBILE_RECHARGE':
        return const Color(0xFF1D7ED6);
      case 'LOAN_REQUEST':
        return const Color(0xFF795548);
      default:
        return const Color(0xFF607D8B);
    }
  }

  String get displayDate {
    final hour = createdAt.hour.toString().padLeft(2, '0');
    final minute = createdAt.minute.toString().padLeft(2, '0');
    return '$hour:$minute ${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }

  String get formattedDate {
    final now = DateTime.now();
    final diff = now.difference(createdAt);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }
}
