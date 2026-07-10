class CurrentUserSummary {
  const CurrentUserSummary({
    required this.id,
    required this.mobileNumber,
    required this.role,
    required this.pinSet,
    required this.profileComplete,
    this.fullName,
    this.email,
    this.avatarUrl,
    this.pinUpdatedAt,
  });

  final int id;
  final String mobileNumber;
  final String role;
  final bool pinSet;
  final bool profileComplete;
  final String? fullName;
  final String? email;
  final String? avatarUrl;
  final DateTime? pinUpdatedAt;

  factory CurrentUserSummary.fromJson(Map<String, dynamic> json) {
    final pinUpdatedAtValue = json['pinUpdatedAt'] as String?;
    final profile = json['profile'] as Map<String, dynamic>?;
    final fullName = profile?['fullName'] as String?;
    final avatarUrl = profile?['avatarUrl'] as String?;

    return CurrentUserSummary(
      id: json['id'] as int? ?? 0,
      mobileNumber: json['mobileNumber'] as String? ?? '',
      role: json['role'] as String? ?? 'CUSTOMER',
      pinSet: json['pinSet'] as bool? ?? false,
      profileComplete: fullName != null && fullName.trim().isNotEmpty,
      fullName: fullName,
      email: profile?['email'] as String?,
      avatarUrl: avatarUrl,
      pinUpdatedAt: pinUpdatedAtValue == null
          ? null
          : DateTime.tryParse(pinUpdatedAtValue),
    );
  }
}
