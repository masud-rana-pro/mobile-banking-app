import '../../../core/network/api_client.dart';
import '../domain/wallet_summary.dart';

class WalletRepository {
  WalletRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<WalletSummary> getMyWallet() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/api/wallet/me',
    );

    return WalletSummary.fromJson(response.data ?? const {});
  }
}
