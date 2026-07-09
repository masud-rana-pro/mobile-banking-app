import '../../../core/network/api_client.dart';
import '../domain/add_money_summary.dart';

class AddMoneyRepository {
  AddMoneyRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<AddMoneySummary> createRequest({
    required double amount,
    required String sourceType,
    String? note,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/api/add-money/requests',
      data: {
        'amount': amount,
        'sourceType': sourceType,
        if (note != null && note.isNotEmpty) 'note': note,
      },
    );

    return AddMoneySummary.fromJson(response.data ?? const {});
  }

  Future<List<AddMoneySummary>> getMyRequests() async {
    final response = await _apiClient.get<List<dynamic>>(
      '/api/add-money/requests',
    );

    final list = response.data as List<dynamic>? ?? [];
    return list
        .map((item) => AddMoneySummary.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
