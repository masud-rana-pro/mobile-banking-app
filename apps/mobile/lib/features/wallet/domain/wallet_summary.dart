class WalletSummary {
  const WalletSummary({
    required this.id,
    required this.userId,
    required this.balance,
    required this.currency,
    required this.status,
  });

  final int id;
  final int userId;
  final double balance;
  final String currency;
  final String status;

  factory WalletSummary.fromJson(Map<String, dynamic> json) {
    return WalletSummary(
      id: json['id'] as int? ?? 0,
      userId: json['userId'] as int? ?? 0,
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'BDT',
      status: json['status'] as String? ?? 'ACTIVE',
    );
  }

  String get balanceFormatted {
    return '${balance.toStringAsFixed(2)} $currency';
  }
}
