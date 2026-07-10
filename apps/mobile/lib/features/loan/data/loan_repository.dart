import '../../../core/network/api_client.dart';
import '../domain/loan_request_summary.dart';

class LoanRepository {
  LoanRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<List<LoanRequestSummary>> getMyRequests() async {
    final response = await _apiClient.get<List<dynamic>>('/api/loans/requests');
    final data = response.data ?? const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(LoanRequestSummary.fromJson)
        .toList();
  }

  Future<LoanRequestSummary> createRequest({
    required double amount,
    required String purpose,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/api/loans/requests',
      data: {
        'amount': amount,
        'purpose': purpose,
      },
    );

    return LoanRequestSummary.fromJson(response.data ?? const {});
  }
}
