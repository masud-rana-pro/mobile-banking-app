import 'auth_session_status.dart';
import 'backend_auth_token.dart';

class AuthSessionState {
  const AuthSessionState({
    required this.status,
    this.backendToken,
    this.errorMessage,
    this.infoMessage,
    this.phoneNumber,
    this.verificationId,
    this.pinSet,
    this.pinUpdatedAt,
  });

  const AuthSessionState.initial()
      : status = AuthSessionStatus.initial,
        backendToken = null,
        errorMessage = null,
        infoMessage = null,
        phoneNumber = null,
        verificationId = null,
        pinSet = null,
        pinUpdatedAt = null;

  final AuthSessionStatus status;
  final BackendAuthToken? backendToken;
  final String? errorMessage;
  final String? infoMessage;
  final String? phoneNumber;
  final String? verificationId;
  final bool? pinSet;
  final DateTime? pinUpdatedAt;

  bool get isAuthenticated =>
      status == AuthSessionStatus.authenticated || backendToken != null;
  bool get isLoading => status == AuthSessionStatus.authenticating;
  bool get isOtpSent => status == AuthSessionStatus.otpSent;
  bool get needsPinSetup => isAuthenticated && pinSet != true;

  AuthSessionState copyWith({
    AuthSessionStatus? status,
    BackendAuthToken? backendToken,
    String? errorMessage,
    String? infoMessage,
    String? phoneNumber,
    String? verificationId,
    bool? pinSet,
    DateTime? pinUpdatedAt,
    bool clearBackendToken = false,
    bool clearError = false,
    bool clearInfo = false,
    bool clearOtp = false,
    bool clearPinState = false,
  }) {
    return AuthSessionState(
      status: status ?? this.status,
      backendToken:
          clearBackendToken ? null : backendToken ?? this.backendToken,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      infoMessage: clearInfo ? null : infoMessage ?? this.infoMessage,
      phoneNumber: clearOtp ? null : phoneNumber ?? this.phoneNumber,
      verificationId: clearOtp ? null : verificationId ?? this.verificationId,
      pinSet: clearPinState ? null : pinSet ?? this.pinSet,
      pinUpdatedAt: clearPinState ? null : pinUpdatedAt ?? this.pinUpdatedAt,
    );
  }
}
