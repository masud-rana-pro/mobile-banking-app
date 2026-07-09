import 'dart:math';

import '../../../core/network/api_client.dart';
import '../domain/send_money_receiver.dart';

class SendMoneyRepository {
  SendMoneyRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;
  final _random = Random();

  Future<SendMoneyReceiver> resolveReceiver(String mobileNumber) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/api/send-money/resolve-receiver',
      data: {'mobileNumber': mobileNumber},
    );

    return SendMoneyReceiver.fromJson(response.data ?? const {});
  }

  Future<SendMoneyResult> sendMoney({
    required String mobileNumber,
    required double amount,
    required String pin,
    String? note,
  }) async {
    final idempotencyKey = _generateIdempotencyKey();

    final response = await _apiClient.post<Map<String, dynamic>>(
      '/api/send-money',
      data: {
        'mobileNumber': mobileNumber,
        'amount': amount,
        'pin': pin,
        'idempotencyKey': idempotencyKey,
        if (note != null && note.isNotEmpty) 'note': note,
      },
    );

    return SendMoneyResult.fromJson(response.data ?? const {});
  }

  String _generateIdempotencyKey() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = _random.nextInt(999999);
    return 'SM-$timestamp-$random';
  }
}
