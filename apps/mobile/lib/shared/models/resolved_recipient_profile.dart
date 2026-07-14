import '../../app/config/app_config.dart';

class ResolvedRecipientProfile {
  const ResolvedRecipientProfile({
    required this.userId,
    required this.mobileNumber,
    required this.displayName,
    this.avatarUrl,
    required this.role,
    required this.status,
  });

  final int userId;
  final String mobileNumber;
  final String displayName;
  final String? avatarUrl;
  final String role;
  final String status;

  factory ResolvedRecipientProfile.fromJson(Map<String, dynamic> json) {
    final profile = json['profile'] as Map<String, dynamic>?;
    final fullName = profile?['fullName'] as String?;
    final mobileNumber = json['mobileNumber'] as String? ?? '';

    return ResolvedRecipientProfile(
      userId: json['id'] as int? ?? 0,
      mobileNumber: mobileNumber,
      displayName: fullName == null || fullName.trim().isEmpty
          ? mobileNumber
          : fullName.trim(),
      avatarUrl: _absoluteAvatarUrl(profile?['avatarUrl'] as String?),
      role: json['role'] as String? ?? 'CUSTOMER',
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
