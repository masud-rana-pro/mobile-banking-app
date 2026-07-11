import 'dart:math';

import '../../../core/network/api_client.dart';
import '../domain/add_money_summary.dart';

class AddMoneyRepository {
  AddMoneyRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;
  final _random = Random();

  Future<AddMoneySummary> createRequest({
    required double amount,
    required String sourceType,
    required String idempotencyKey,
    String? note,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/api/add-money/requests',
      data: {
        'amount': amount,
        'sourceType': sourceType,
        'idempotencyKey': idempotencyKey,
        if (note != null && note.isNotEmpty) 'note': note,
      },
    );

    return AddMoneySummary.fromJson(response.data ?? const {});
  }

  Future<List<AddMoneySummary>> getMyRequests() async {
    final response = await _apiClient.get<List<dynamic>>(
      '/api/add-money/requests',
    );

    final list = response.data ?? [];
    return list
        .map((item) => AddMoneySummary.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  String createIdempotencyKey() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = _random.nextInt(999999);
    return 'AM-$timestamp-$random';
  }
}
