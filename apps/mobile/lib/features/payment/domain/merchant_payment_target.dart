import '../../../app/config/app_config.dart';

class MerchantPaymentTarget {
  const MerchantPaymentTarget({
    required this.merchantUserId,
    required this.merchantNumber,
    required this.businessName,
    required this.businessType,
    this.avatarUrl,
    required this.status,
  });

  final int merchantUserId;
  final String merchantNumber;
  final String businessName;
  final String businessType;
  final String? avatarUrl;
  final String status;

  factory MerchantPaymentTarget.fromJson(Map<String, dynamic> json) {
    return MerchantPaymentTarget(
      merchantUserId: json['merchantUserId'] as int? ?? 0,
      merchantNumber: json['merchantNumber'] as String? ?? '',
      businessName: json['businessName'] as String? ?? '',
      businessType: json['businessType'] as String? ?? '',
      avatarUrl: _absoluteAvatarUrl(json['avatarUrl'] as String?),
      status: json['status'] as String? ?? '',
    );
  }

  static String? _absoluteAvatarUrl(String? avatarUrl) {
    if (avatarUrl == null || avatarUrl.trim().isEmpty) {
      return null;
    }

    final trimmed = avatarUrl.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }

    final baseUrl = AppConfig.backendBaseUrl.replaceFirst(RegExp(r'/$'), '');
    final path = trimmed.startsWith('/') ? trimmed : '/$trimmed';
    return '$baseUrl$path';
  }
}
