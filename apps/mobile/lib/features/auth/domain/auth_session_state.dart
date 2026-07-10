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
    this.profileComplete,
    this.fullName,
    this.email,
    this.avatarImageId,
    this.avatarUrl,
  });

  const AuthSessionState.initial()
      : status = AuthSessionStatus.initial,
        backendToken = null,
        errorMessage = null,
        infoMessage = null,
        phoneNumber = null,
        verificationId = null,
        pinSet = null,
        pinUpdatedAt = null,
        profileComplete = null,
        fullName = null,
        email = null,
        avatarImageId = null,
        avatarUrl = null;

  final AuthSessionStatus status;
  final BackendAuthToken? backendToken;
  final String? errorMessage;
  final String? infoMessage;
  final String? phoneNumber;
  final String? verificationId;
  final bool? pinSet;
  final DateTime? pinUpdatedAt;
  final bool? profileComplete;
  final String? fullName;
  final String? email;
  final String? avatarImageId;
  final String? avatarUrl;

  bool get isAuthenticated =>
      status == AuthSessionStatus.authenticated || backendToken != null;
  bool get isLoading => status == AuthSessionStatus.authenticating;
  bool get isOtpSent => status == AuthSessionStatus.otpSent;
  bool get canVerifyOtp => verificationId != null && verificationId!.isNotEmpty;
  bool get needsPinSetup => isAuthenticated && pinSet != true;
  bool get needsProfileCompletion =>
      isAuthenticated && !needsPinSetup && profileComplete != true;

  AuthSessionState copyWith({
    AuthSessionStatus? status,
    BackendAuthToken? backendToken,
    String? errorMessage,
    String? infoMessage,
    String? phoneNumber,
    String? verificationId,
    bool? pinSet,
    DateTime? pinUpdatedAt,
    bool? profileComplete,
    String? fullName,
    String? email,
    String? avatarImageId,
    String? avatarUrl,
    bool clearBackendToken = false,
    bool clearError = false,
    bool clearInfo = false,
    bool clearOtp = false,
    bool clearPinState = false,
    bool clearProfileState = false,
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
      profileComplete:
          clearProfileState ? null : profileComplete ?? this.profileComplete,
      fullName: clearProfileState ? null : fullName ?? this.fullName,
      email: clearProfileState ? null : email ?? this.email,
      avatarImageId:
          clearProfileState ? null : avatarImageId ?? this.avatarImageId,
      avatarUrl: clearProfileState ? null : avatarUrl ?? this.avatarUrl,
    );
  }
}
