import 'dart:math';

import '../../../core/network/api_client.dart';
import '../domain/pay_bill_result.dart';

class PayBillRepository {
  PayBillRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;
  final _random = Random();

  Future<PayBillResult> payBill({
    required String billerCode,
    required String billAccountNumber,
    required double amount,
    required String pin,
    required String idempotencyKey,
    String? note,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/api/pay-bill',
      data: {
        'billerCode': billerCode,
        'billAccountNumber': billAccountNumber,
        'amount': amount,
        'pin': pin,
        'idempotencyKey': idempotencyKey,
        if (note != null && note.isNotEmpty) 'note': note,
      },
    );

    return PayBillResult.fromJson(response.data ?? const {});
  }

  String createIdempotencyKey() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = _random.nextInt(999999);
    return 'PB-$timestamp-$random';
  }
}
