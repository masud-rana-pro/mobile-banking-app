class PinSetupResult {
  const PinSetupResult({
    required this.pinSet,
    this.pinUpdatedAt,
  });

  final bool pinSet;
  final DateTime? pinUpdatedAt;

  factory PinSetupResult.fromJson(Map<String, dynamic> json) {
    final pinUpdatedAtValue = json['pinUpdatedAt'] as String?;

    return PinSetupResult(
      pinSet: json['pinSet'] as bool? ?? false,
      pinUpdatedAt: pinUpdatedAtValue == null
          ? null
          : DateTime.tryParse(pinUpdatedAtValue),
    );
  }
}
