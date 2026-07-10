import 'dart:math';

import '../../../core/network/api_client.dart';
import '../domain/mobile_recharge_record.dart';

class RechargeRepository {
  RechargeRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;
  final _random = Random();

  Future<List<MobileRechargeRecord>> getMyRecharges() async {
    final response = await _apiClient.get<List<dynamic>>('/api/recharge');
    final data = response.data ?? const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(MobileRechargeRecord.fromJson)
        .toList();
  }

  Future<MobileRechargeRecord> createRecharge({
    required String operator,
    required String mobileNumber,
    required double amount,
    required String pin,
    required String idempotencyKey,
    String? note,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/api/recharge',
      data: {
        'operator': operator,
        'mobileNumber': mobileNumber,
        'amount': amount,
        'pin': pin,
        'idempotencyKey': idempotencyKey,
        if (note != null && note.isNotEmpty) 'note': note,
      },
    );

    return MobileRechargeRecord.fromJson(response.data ?? const {});
  }

  String createIdempotencyKey() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = _random.nextInt(999999);
    return 'RC-$timestamp-$random';
  }
}
