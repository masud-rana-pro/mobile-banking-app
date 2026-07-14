class LoanRequestSummary {
  const LoanRequestSummary({
    required this.id,
    required this.amount,
    required this.purpose,
    required this.status,
    this.transactionReference,
    this.reviewedAt,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final double amount;
  final String purpose;
  final String status;
  final String? transactionReference;
  final DateTime? reviewedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory LoanRequestSummary.fromJson(Map<String, dynamic> json) {
    return LoanRequestSummary(
      id: json['id'] as int? ?? 0,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      purpose: json['purpose'] as String? ?? '',
      status: json['status'] as String? ?? '',
      transactionReference: json['transactionReference'] as String?,
      reviewedAt: json['reviewedAt'] != null
          ? DateTime.tryParse(json['reviewedAt'] as String)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }
}
