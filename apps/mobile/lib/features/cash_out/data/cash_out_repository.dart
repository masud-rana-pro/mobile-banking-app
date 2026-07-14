import 'dart:math';

import '../../../core/network/api_client.dart';
import '../domain/cash_out_agent.dart';
import '../domain/cash_out_result.dart';

class CashOutRepository {
  CashOutRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;
  final _random = Random();

  Future<CashOutAgent> resolveAgent(String agentNumber) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/api/agents/resolve',
      queryParameters: {'agentNumber': agentNumber},
    );

    return CashOutAgent.fromJson(response.data ?? const {});
  }

  Future<CashOutResult> cashOut({
    required String agentNumber,
    required double amount,
    required String pin,
    required String idempotencyKey,
    String? note,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/api/cash-out',
      data: {
        'agentNumber': agentNumber,
        'amount': amount,
        'pin': pin,
        'idempotencyKey': idempotencyKey,
        if (note != null && note.isNotEmpty) 'note': note,
      },
    );

    return CashOutResult.fromJson(response.data ?? const {});
  }

  String createIdempotencyKey() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = _random.nextInt(999999);
    return 'CO-$timestamp-$random';
  }
}
