import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_token_storage.dart';
import '../domain/backend_auth_token.dart';
import '../domain/current_user_summary.dart';
import '../domain/pin_setup_result.dart';

class BackendAuthRepository {
  BackendAuthRepository({
    required ApiClient apiClient,
    required SecureTokenStorage tokenStorage,
  })  : _apiClient = apiClient,
        _tokenStorage = tokenStorage;

  final ApiClient _apiClient;
  final SecureTokenStorage _tokenStorage;

  Future<BackendAuthToken> loginWithFirebaseIdToken(
      String firebaseIdToken) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/api/auth/firebase-login',
      data: {'firebaseIdToken': firebaseIdToken},
    );

    final token = BackendAuthToken.fromJson(response.data ?? const {});
    await _tokenStorage.saveBackendToken(
      accessToken: token.accessToken,
      tokenType: token.tokenType,
    );

    return token;
  }

  Future<CurrentUserSummary> getCurrentUser() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/api/users/me',
    );

    return CurrentUserSummary.fromJson(response.data ?? const {});
  }

  Future<PinSetupResult> setPin({
    required String pin,
    required String confirmPin,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/api/auth/set-pin',
      data: {
        'pin': pin,
        'confirmPin': confirmPin,
      },
    );

    return PinSetupResult.fromJson(response.data ?? const {});
  }

  Future<void> signOutLocally() {
    return _tokenStorage.clearBackendToken();
  }
}
