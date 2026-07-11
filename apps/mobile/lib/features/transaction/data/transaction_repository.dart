import '../../../core/network/api_client.dart';
import '../domain/transaction_summary.dart';

class TransactionRepository {
  TransactionRepository({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<List<TransactionSummary>> getMyTransactions() async {
    final response = await _apiClient.get<dynamic>(
      '/api/transactions',
      queryParameters: {
        '_': DateTime.now().millisecondsSinceEpoch,
      },
    );

    final list = _extractList(response.data);
    return list.map(TransactionSummary.fromJson).toList();
  }

  Future<TransactionSummary> getTransactionDetail(int id) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/api/transactions/$id',
    );

    return TransactionSummary.fromJson(response.data ?? const {});
  }

  List<Map<String, dynamic>> _extractList(Object? data) {
    final rawList = switch (data) {
      final List<dynamic> list => list,
      final Map<String, dynamic> map when map['data'] is List<dynamic> =>
        map['data'] as List<dynamic>,
      final Map<String, dynamic> map
          when map['transactions'] is List<dynamic> =>
        map['transactions'] as List<dynamic>,
      _ => const <dynamic>[],
    };

    return rawList
        .whereType<Map>()
        .map(
            (item) => item.map((key, value) => MapEntry(key.toString(), value)))
        .toList();
  }
}
