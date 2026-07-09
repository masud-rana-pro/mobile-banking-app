class QrPayload {
  const QrPayload({required this.mobileNumber});

  final String mobileNumber;

  static const String _prefix = 'SMARTKASH_USER:';

  String get fullPayload => '$_prefix$mobileNumber';

  static String? extractMobileNumber(String payload) {
    final trimmed = payload.trim();
    if (!trimmed.startsWith(_prefix)) {
      return null;
    }

    final number = trimmed.substring(_prefix.length);
    if (number.isEmpty) {
      return null;
    }

    return number;
  }

  static bool isValid(String payload) {
    return extractMobileNumber(payload) != null;
  }
}
