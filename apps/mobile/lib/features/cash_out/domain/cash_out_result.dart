class CashOutResult {
  const CashOutResult({
    required this.success,
    required this.message,
    this.transactionReference,
    required this.status,
    required this.amount,
    this.chargeAmount,
    this.balanceAfter,
    required this.agentNumber,
  });

  final bool success;
  final String message;
  final String? transactionReference;
  final String status;
  final double amount;
  final double? chargeAmount;
  final double? balanceAfter;
  final String agentNumber;

  factory CashOutResult.fromJson(Map<String, dynamic> json) {
    return CashOutResult(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      transactionReference: json['transactionReference'] as String?,
      status: json['status'] as String? ?? 'FAILED',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      chargeAmount: (json['chargeAmount'] as num?)?.toDouble(),
      balanceAfter: (json['balanceAfter'] as num?)?.toDouble(),
      agentNumber: json['agentNumber'] as String? ?? '',
    );
  }

  CashOutResult copyWith({
    double? balanceAfter,
  }) {
    return CashOutResult(
      success: success,
      message: message,
      transactionReference: transactionReference,
      status: status,
      amount: amount,
      chargeAmount: chargeAmount,
      balanceAfter: balanceAfter ?? this.balanceAfter,
      agentNumber: agentNumber,
    );
  }
}
