import '../../../app/config/app_config.dart';

class SendMoneyReceiver {
  const SendMoneyReceiver({
    required this.userId,
    required this.mobileNumber,
    this.displayName,
    this.avatarUrl,
    required this.role,
    required this.userStatus,
    required this.walletStatus,
  });

  final int userId;
  final String mobileNumber;
  final String? displayName;
  final String? avatarUrl;
  final String role;
  final String userStatus;
  final String walletStatus;

  factory SendMoneyReceiver.fromJson(Map<String, dynamic> json) {
    return SendMoneyReceiver(
      userId: json['userId'] as int? ?? 0,
      mobileNumber: json['mobileNumber'] as String? ?? '',
      displayName: json['displayName'] as String?,
      avatarUrl: _absoluteAvatarUrl(json['avatarUrl'] as String?),
      role: json['role'] as String? ?? 'CUSTOMER',
      userStatus: json['userStatus'] as String? ?? 'ACTIVE',
      walletStatus: json['walletStatus'] as String? ?? 'ACTIVE',
    );
  }

  bool get isValid => userStatus == 'ACTIVE' && walletStatus == 'ACTIVE';

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

class SendMoneyResult {
  const SendMoneyResult({
    required this.success,
    required this.message,
    this.transactionReference,
    this.status,
    this.amount,
    this.chargeAmount,
    this.senderBalanceAfter,
    this.receiverUserId,
    this.receiverMobileNumber,
    this.createdAt,
  });

  final bool success;
  final String message;
  final String? transactionReference;
  final String? status;
  final double? amount;
  final double? chargeAmount;
  final double? senderBalanceAfter;
  final int? receiverUserId;
  final String? receiverMobileNumber;
  final DateTime? createdAt;

  factory SendMoneyResult.fromJson(Map<String, dynamic> json) {
    return SendMoneyResult(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      transactionReference: json['transactionReference'] as String?,
      status: json['status'] as String?,
      amount: (json['amount'] as num?)?.toDouble(),
      chargeAmount: (json['chargeAmount'] as num?)?.toDouble(),
      senderBalanceAfter: (json['senderBalanceAfter'] as num?)?.toDouble(),
      receiverUserId: json['receiverUserId'] as int?,
      receiverMobileNumber: json['receiverMobileNumber'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }

  SendMoneyResult copyWith({
    double? senderBalanceAfter,
  }) {
    return SendMoneyResult(
      success: success,
      message: message,
      transactionReference: transactionReference,
      status: status,
      amount: amount,
      chargeAmount: chargeAmount,
      senderBalanceAfter: senderBalanceAfter ?? this.senderBalanceAfter,
      receiverUserId: receiverUserId,
      receiverMobileNumber: receiverMobileNumber,
      createdAt: createdAt,
    );
  }
}
