import 'dart:math';

import '../../../core/network/api_client.dart';
import '../domain/merchant_payment_result.dart';
import '../domain/merchant_payment_target.dart';

class PaymentRepository {
  PaymentRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;
  final _random = Random();

  Future<MerchantPaymentTarget> resolveMerchant({
    required String merchantNumber,
  }) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/api/payments/merchant/resolve',
      queryParameters: {'merchantNumber': merchantNumber},
    );

    return MerchantPaymentTarget.fromJson(response.data ?? const {});
  }

  Future<MerchantPaymentResult> payMerchant({
    required String merchantNumber,
    required double amount,
    required String pin,
    required String idempotencyKey,
    String? note,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/api/payments/merchant',
      data: {
        'merchantNumber': merchantNumber,
        'amount': amount,
        'pin': pin,
        'idempotencyKey': idempotencyKey,
        if (note != null && note.isNotEmpty) 'note': note,
      },
    );

    return MerchantPaymentResult.fromJson(response.data ?? const {});
  }

  String createIdempotencyKey() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = _random.nextInt(999999);
    return 'MP-$timestamp-$random';
  }
}
