import 'savings_goal.dart';

class SavingsDepositResult {
  const SavingsDepositResult({
    required this.success,
    required this.message,
    required this.status,
    required this.amount,
    required this.goal,
    this.transactionReference,
    this.walletBalanceAfter,
    this.createdAt,
  });

  final bool success;
  final String message;
  final String status;
  final double amount;
  final SavingsGoal goal;
  final String? transactionReference;
  final double? walletBalanceAfter;
  final DateTime? createdAt;

  factory SavingsDepositResult.fromJson(Map<String, dynamic> json) {
    return SavingsDepositResult(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      transactionReference: json['transactionReference'] as String?,
      status: json['status'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      walletBalanceAfter: (json['walletBalanceAfter'] as num?)?.toDouble(),
      goal: SavingsGoal.fromJson(
        (json['goal'] as Map<String, dynamic>?) ?? const {},
      ),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }

  SavingsDepositResult copyWith({
    double? walletBalanceAfter,
  }) {
    return SavingsDepositResult(
      success: success,
      message: message,
      status: status,
      amount: amount,
      goal: goal,
      transactionReference: transactionReference,
      walletBalanceAfter: walletBalanceAfter ?? this.walletBalanceAfter,
      createdAt: createdAt,
    );
  }
}
