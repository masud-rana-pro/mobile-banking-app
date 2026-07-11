class AddMoneySummary {
  const AddMoneySummary({
    required this.id,
    required this.amount,
    required this.sourceType,
    required this.status,
    this.note,
    this.approvedAt,
    required this.createdAt,
  });

  final int id;
  final double amount;
  final String sourceType;
  final String status;
  final String? note;
  final DateTime? approvedAt;
  final DateTime createdAt;

  factory AddMoneySummary.fromJson(Map<String, dynamic> json) {
    return AddMoneySummary(
      id: json['id'] as int? ?? 0,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      sourceType: json['sourceType'] as String? ?? 'MANUAL',
      status: json['status'] as String? ?? 'PENDING',
      note: json['note'] as String?,
      approvedAt: json['approvedAt'] != null
          ? DateTime.tryParse(json['approvedAt'] as String)
          : null,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  String get sourceLabel {
    switch (sourceType) {
      case 'DEMO_BANK':
        return 'Bank Transfer';
      case 'DEMO_CARD':
        return 'Debit/Credit Card';
      case 'MANUAL':
        return 'Manual Deposit';
      default:
        return sourceType;
    }
  }

  String get statusLabel {
    switch (status) {
      case 'APPROVED':
        return 'Success';
      case 'REJECTED':
        return 'Rejected';
      default:
        return 'Pending';
    }
  }

  bool get isApproved => status == 'APPROVED';
  bool get isRejected => status == 'REJECTED';
  bool get isPending => status == 'PENDING';

  String get shortDate {
    final hour = createdAt.hour.toString().padLeft(2, '0');
    final minute = createdAt.minute.toString().padLeft(2, '0');
    return '$hour:$minute ${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }
}
