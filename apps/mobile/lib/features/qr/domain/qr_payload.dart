enum QrPayloadType { user, merchant, agent }

class QrPayload {
  const QrPayload.user({required String mobileNumber})
      : type = QrPayloadType.user,
        value = mobileNumber;

  const QrPayload.merchant({required String merchantNumber})
      : type = QrPayloadType.merchant,
        value = merchantNumber;

  const QrPayload.agent({required String agentNumber})
      : type = QrPayloadType.agent,
        value = agentNumber;

  final QrPayloadType type;
  final String value;

  static const String userPrefix = 'SMARTKASH_USER:';
  static const String merchantPrefix = 'SMARTKASH_MERCHANT:';
  static const String agentPrefix = 'SMARTKASH_AGENT:';

  String get fullPayload {
    return switch (type) {
      QrPayloadType.user => '$userPrefix$value',
      QrPayloadType.merchant => '$merchantPrefix$value',
      QrPayloadType.agent => '$agentPrefix$value',
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

  static String? extractAgentNumber(String payload) {
    final parsed = parse(payload);
    return parsed?.type == QrPayloadType.agent ? parsed?.value : null;
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
    if (trimmed.startsWith(agentPrefix)) {
      final agentNumber = trimmed.substring(agentPrefix.length).trim();
      return agentNumber.isEmpty
          ? null
          : QrPayload.agent(agentNumber: agentNumber);
    }
    return null;
  }

  static bool isValid(String payload) => parse(payload) != null;
}
