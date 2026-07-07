class BackendAuthToken {
  const BackendAuthToken({
    required this.tokenType,
    required this.accessToken,
    required this.expiresAt,
    required this.firebaseUid,
    required this.phoneNumber,
    required this.role,
  });

  final String tokenType;
  final String accessToken;
  final DateTime expiresAt;
  final String firebaseUid;
  final String phoneNumber;
  final String role;

  factory BackendAuthToken.fromJson(Map<String, dynamic> json) {
    return BackendAuthToken(
      tokenType: json['tokenType'] as String? ?? 'Bearer',
      accessToken: json['accessToken'] as String? ?? '',
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      firebaseUid: json['firebaseUid'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      role: json['role'] as String? ?? 'CUSTOMER',
    );
  }
}
