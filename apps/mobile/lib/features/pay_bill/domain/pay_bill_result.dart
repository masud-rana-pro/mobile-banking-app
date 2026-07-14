class PayBillResult {
  const PayBillResult({
    required this.success,
    required this.message,
    this.transactionReference,
    required this.status,
    required this.amount,
    this.balanceAfter,
    required this.billerCode,
    required this.billAccountNumber,
  });

  final bool success;
  final String message;
  final String? transactionReference;
  final String status;
  final double amount;
  final double? balanceAfter;
  final String billerCode;
  final String billAccountNumber;

  factory PayBillResult.fromJson(Map<String, dynamic> json) {
    return PayBillResult(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      transactionReference: json['transactionReference'] as String?,
      status: json['status'] as String? ?? 'FAILED',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      balanceAfter: (json['balanceAfter'] as num?)?.toDouble(),
      billerCode: json['billerCode'] as String? ?? '',
      billAccountNumber: json['billAccountNumber'] as String? ?? '',
    );
  }

  PayBillResult copyWith({
    double? balanceAfter,
  }) {
    return PayBillResult(
      success: success,
      message: message,
      transactionReference: transactionReference,
      status: status,
      amount: amount,
      balanceAfter: balanceAfter ?? this.balanceAfter,
      billerCode: billerCode,
      billAccountNumber: billAccountNumber,
    );
  }
}
