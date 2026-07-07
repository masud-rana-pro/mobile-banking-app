import 'auth_session_status.dart';
import 'backend_auth_token.dart';

class AuthSessionState {
  const AuthSessionState({
    required this.status,
    this.backendToken,
    this.errorMessage,
  });

  const AuthSessionState.initial()
      : status = AuthSessionStatus.initial,
        backendToken = null,
        errorMessage = null;

  final AuthSessionStatus status;
  final BackendAuthToken? backendToken;
  final String? errorMessage;

  bool get isAuthenticated => status == AuthSessionStatus.authenticated;
  bool get isLoading => status == AuthSessionStatus.authenticating;

  AuthSessionState copyWith({
    AuthSessionStatus? status,
    BackendAuthToken? backendToken,
    String? errorMessage,
    bool clearBackendToken = false,
    bool clearError = false,
  }) {
    return AuthSessionState(
      status: status ?? this.status,
      backendToken:
          clearBackendToken ? null : backendToken ?? this.backendToken,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}
