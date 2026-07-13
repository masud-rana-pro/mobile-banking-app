enum QrPayloadType { user, merchant }

class QrPayload {
  const QrPayload.user({required String mobileNumber})
      : type = QrPayloadType.user,
        value = mobileNumber;

  const QrPayload.merchant({required String merchantNumber})
      : type = QrPayloadType.merchant,
        value = merchantNumber;

  final QrPayloadType type;
  final String value;

  static const String userPrefix = 'SMARTKASH_USER:';
  static const String merchantPrefix = 'SMARTKASH_MERCHANT:';

  String get fullPayload {
    return switch (type) {
      QrPayloadType.user => '$userPrefix$value',
      QrPayloadType.merchant => '$merchantPrefix$value',
    };
  }

  static String? extractMobileNumber(String payload) {
    final parsed = parse(payload);
    return parsed?.type == QrPayloadType.user ? parsed?.value : null;
  }

  static String? extractMerchantNumber(String payload) {
    final parsed = parse(payload);
    return parsed?.type == QrPayloadType.merchant ? parsed?.value : null;
  }

  static QrPayload? parse(String payload) {
    final trimmed = payload.trim();
    if (trimmed.startsWith(userPrefix)) {
      final number = trimmed.substring(userPrefix.length).trim();
      return number.isEmpty ? null : QrPayload.user(mobileNumber: number);
    }
    if (trimmed.startsWith(merchantPrefix)) {
      final merchantNumber = trimmed.substring(merchantPrefix.length).trim();
      return merchantNumber.isEmpty
          ? null
          : QrPayload.merchant(merchantNumber: merchantNumber);
    }
    return null;
  }

  static bool isValid(String payload) => parse(payload) != null;
}
