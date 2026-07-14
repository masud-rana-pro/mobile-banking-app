import '../../core/errors/api_exception.dart';
import '../../core/network/api_client.dart';
import '../models/resolved_recipient_profile.dart';

class RecipientProfileRepository {
  RecipientProfileRepository({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<ResolvedRecipientProfile?> tryResolveByMobileNumber(
    String mobileNumber,
  ) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/api/users/resolve',
        queryParameters: {'mobileNumber': mobileNumber},
      );
      final data = response.data;
      if (data == null) {
        return null;
      }
      return ResolvedRecipientProfile.fromJson(data);
    } on ApiException catch (error) {
      if (error.statusCode == 404 || error.statusCode == 400) {
        return null;
      }
      rethrow;
    }
  }
}
