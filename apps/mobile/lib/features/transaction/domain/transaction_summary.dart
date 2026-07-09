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
        return 'Received';
      case 'MERCHANT_PAYMENT':
        return 'Payment';
      case 'SAVINGS_DEPOSIT':
        return 'Savings';
      case 'MOBILE_RECHARGE':
        return 'Recharge';
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
    return '$prefix৳ ${amount.toStringAsFixed(2)}';
  }

  String get amountColorHex => isCredit ? '0xFF0E9F6E' : '0xFFB42318';

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
