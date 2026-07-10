class MerchantPaymentTarget {
  const MerchantPaymentTarget({
    required this.merchantUserId,
    required this.merchantNumber,
    required this.businessName,
    required this.businessType,
    required this.status,
  });

  final int merchantUserId;
  final String merchantNumber;
  final String businessName;
  final String businessType;
  final String status;

  factory MerchantPaymentTarget.fromJson(Map<String, dynamic> json) {
    return MerchantPaymentTarget(
      merchantUserId: json['merchantUserId'] as int? ?? 0,
      merchantNumber: json['merchantNumber'] as String? ?? '',
      businessName: json['businessName'] as String? ?? '',
      businessType: json['businessType'] as String? ?? '',
      status: json['status'] as String? ?? '',
    );
  }
}
