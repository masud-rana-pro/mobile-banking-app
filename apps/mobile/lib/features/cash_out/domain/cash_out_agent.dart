import '../../../app/config/app_config.dart';

class CashOutAgent {
  const CashOutAgent({
    required this.userId,
    required this.businessName,
    required this.agentNumber,
    this.location,
    this.avatarUrl,
    required this.status,
  });

  final int userId;
  final String businessName;
  final String agentNumber;
  final String? location;
  final String? avatarUrl;
  final String status;

  factory CashOutAgent.fromJson(Map<String, dynamic> json) {
    return CashOutAgent(
      userId: json['userId'] as int? ?? 0,
      businessName: json['businessName'] as String? ?? 'SmartKash Agent',
      agentNumber: json['agentNumber'] as String? ?? '',
      location: json['location'] as String?,
      avatarUrl: _absoluteAvatarUrl(json['avatarUrl'] as String?),
      status: json['status'] as String? ?? 'ACTIVE',
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
