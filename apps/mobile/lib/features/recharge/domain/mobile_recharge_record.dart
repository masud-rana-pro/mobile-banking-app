class MobileRechargeRecord {
  const MobileRechargeRecord({
    required this.id,
    required this.operator,
    required this.mobileNumber,
    required this.amount,
    required this.status,
    this.transactionReference,
    this.balanceAfter,
    this.createdAt,
  });

  final int id;
  final String operator;
  final String mobileNumber;
  final double amount;
  final String status;
  final String? transactionReference;
  final double? balanceAfter;
  final DateTime? createdAt;

  factory MobileRechargeRecord.fromJson(Map<String, dynamic> json) {
    return MobileRechargeRecord(
      id: json['id'] as int? ?? 0,
      operator: json['operator'] as String? ?? '',
      mobileNumber: json['mobileNumber'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      status: json['status'] as String? ?? '',
      transactionReference: json['transactionReference'] as String?,
      balanceAfter: (json['balanceAfter'] as num?)?.toDouble(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }

  MobileRechargeRecord copyWith({
    double? balanceAfter,
  }) {
    return MobileRechargeRecord(
      id: id,
      operator: operator,
      mobileNumber: mobileNumber,
      amount: amount,
      status: status,
      transactionReference: transactionReference,
      balanceAfter: balanceAfter ?? this.balanceAfter,
      createdAt: createdAt,
    );
  }
}
