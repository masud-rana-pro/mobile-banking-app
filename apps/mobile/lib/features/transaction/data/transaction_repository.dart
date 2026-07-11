import '../../../core/network/api_client.dart';
import '../domain/transaction_summary.dart';

class TransactionRepository {
  TransactionRepository({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<List<TransactionSummary>> getMyTransactions() async {
    final response = await _apiClient.get<List<dynamic>>(
      '/api/transactions',
    );

    final list = response.data ?? [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(TransactionSummary.fromJson)
        .toList();
  }

  Future<TransactionSummary> getTransactionDetail(int id) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/api/transactions/$id',
    );

    return TransactionSummary.fromJson(response.data ?? const {});
  }
}
