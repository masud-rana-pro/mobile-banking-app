class CurrentUserSummary {
  const CurrentUserSummary({
    required this.id,
    required this.mobileNumber,
    required this.role,
    required this.pinSet,
    this.pinUpdatedAt,
  });

  final int id;
  final String mobileNumber;
  final String role;
  final bool pinSet;
  final DateTime? pinUpdatedAt;

  factory CurrentUserSummary.fromJson(Map<String, dynamic> json) {
    final pinUpdatedAtValue = json['pinUpdatedAt'] as String?;

    return CurrentUserSummary(
      id: json['id'] as int? ?? 0,
      mobileNumber: json['mobileNumber'] as String? ?? '',
      role: json['role'] as String? ?? 'CUSTOMER',
      pinSet: json['pinSet'] as bool? ?? false,
      pinUpdatedAt: pinUpdatedAtValue == null
          ? null
          : DateTime.tryParse(pinUpdatedAtValue),
    );
  }
}
