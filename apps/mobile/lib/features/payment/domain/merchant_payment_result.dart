class MerchantPaymentResult {
  const MerchantPaymentResult({
    required this.success,
    required this.message,
    this.transactionReference,
    this.status,
    this.amount,
    this.customerBalanceAfter,
    this.merchantUserId,
    this.merchantNumber,
    this.businessName,
    this.createdAt,
  });

  final bool success;
  final String message;
  final String? transactionReference;
  final String? status;
  final double? amount;
  final double? customerBalanceAfter;
  final int? merchantUserId;
  final String? merchantNumber;
  final String? businessName;
  final DateTime? createdAt;

  factory MerchantPaymentResult.fromJson(Map<String, dynamic> json) {
    return MerchantPaymentResult(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      transactionReference: json['transactionReference'] as String?,
      status: json['status'] as String?,
      amount: (json['amount'] as num?)?.toDouble(),
      customerBalanceAfter: (json['customerBalanceAfter'] as num?)?.toDouble(),
      merchantUserId: json['merchantUserId'] as int?,
      merchantNumber: json['merchantNumber'] as String?,
      businessName: json['businessName'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }
}
