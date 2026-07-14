import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/config/firebase_config.dart';
import '../../../core/errors/api_exception.dart';
import '../data/backend_auth_repository.dart';
import '../data/firebase_phone_auth_service.dart';
import '../domain/auth_session_state.dart';
import '../domain/auth_session_status.dart';

class AuthController extends StateNotifier<AuthSessionState> {
  AuthController({
    required FirebasePhoneAuthService firebasePhoneAuthService,
    required BackendAuthRepository backendAuthRepository,
  })  : _firebasePhoneAuthService = firebasePhoneAuthService,
        _backendAuthRepository = backendAuthRepository,
        super(const AuthSessionState.initial());

  final FirebasePhoneAuthService _firebasePhoneAuthService;
  final BackendAuthRepository _backendAuthRepository;

  Future<void> restoreSession() async {
    if (!FirebaseConfig.enabled) {
      state = const AuthSessionState(status: AuthSessionStatus.unauthenticated);
      return;
    }

    if (_firebasePhoneAuthService.currentUser == null) {
      state = const AuthSessionState(status: AuthSessionStatus.unauthenticated);
      return;
    }

    await syncBackendSession();
  }

  Future<void> sendLoginOtp(String phoneNumber) async {
    final firebaseBlockReason = _firebaseOtpBlockReason();
    if (firebaseBlockReason != null) {
      state = state.copyWith(
        status: AuthSessionStatus.failure,
        phoneNumber: phoneNumber,
        clearOtp: true,
        clearInfo: true,
        errorMessage: firebaseBlockReason,
      );
      return;
    }

    state = state.copyWith(
      status: AuthSessionStatus.authenticating,
      phoneNumber: phoneNumber,
      clearError: true,
      clearInfo: true,
      clearOtp: true,
    );

    try {
      final result =
          await _firebasePhoneAuthService.startPhoneVerification(phoneNumber);

      if (result.autoVerified) {
        await syncBackendSession(forceRefresh: true);
        return;
      }

      state = state.copyWith(
        status: AuthSessionStatus.otpSent,
        phoneNumber: phoneNumber,
        verificationId: result.verificationId,
        infoMessage: 'Test OTP sent. Enter the fixed Firebase test OTP.',
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        status: AuthSessionStatus.failure,
        errorMessage: _friendlyError(error),
      );
    }
  }

  Future<void> verifyLoginOtp(String smsCode) async {
    final verificationId = state.verificationId;
    if (verificationId == null || verificationId.isEmpty) {
      state = state.copyWith(
        status: AuthSessionStatus.failure,
        errorMessage: 'Send OTP first, then verify the code.',
      );
      return;
    }

    state = state.copyWith(
      status: AuthSessionStatus.authenticating,
      clearError: true,
      clearInfo: true,
    );

    try {
      await _firebasePhoneAuthService.signInWithSmsCode(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      await syncBackendSession(forceRefresh: true);
    } catch (error) {
      state = state.copyWith(
        status: AuthSessionStatus.failure,
        errorMessage: _friendlyError(error),
      );
    }
  }

  Future<void> syncBackendSession({bool forceRefresh = false}) async {
    state = state.copyWith(
      status: AuthSessionStatus.authenticating,
      clearError: true,
    );

    try {
      final firebaseIdToken = await _firebasePhoneAuthService.currentIdToken(
        forceRefresh: forceRefresh,
      );

      if (firebaseIdToken == null || firebaseIdToken.isEmpty) {
        state = state.copyWith(
          status: AuthSessionStatus.unauthenticated,
          clearBackendToken: true,
          errorMessage: 'Firebase user is not signed in.',
        );
        return;
      }

      final backendToken =
          await _backendAuthRepository.loginWithFirebaseIdToken(
        firebaseIdToken,
      );
      final currentUser = await _backendAuthRepository.getCurrentUser();

      state = AuthSessionState(
        status: AuthSessionStatus.authenticated,
        backendToken: backendToken,
        pinSet: currentUser.pinSet,
        pinUpdatedAt: currentUser.pinUpdatedAt,
        role: currentUser.role,
        profileComplete: currentUser.profileComplete,
        fullName: currentUser.fullName,
        email: currentUser.email,
        avatarImageId: currentUser.avatarImageId,
        avatarUrl: currentUser.avatarUrl,
      );
    } catch (error) {
      state = state.copyWith(
        status: AuthSessionStatus.failure,
        errorMessage: _friendlyError(error),
      );
    }
  }

  Future<void> setPin({
    required String pin,
    required String confirmPin,
  }) async {
    if (!_isFiveDigitPin(pin) || !_isFiveDigitPin(confirmPin)) {
      state = state.copyWith(
        status: AuthSessionStatus.failure,
        errorMessage: 'PIN must be exactly 5 digits.',
      );
      return;
    }

    if (pin != confirmPin) {
      state = state.copyWith(
        status: AuthSessionStatus.failure,
        errorMessage: 'PIN and confirm PIN do not match.',
      );
      return;
    }

    state = state.copyWith(
      status: AuthSessionStatus.authenticating,
      clearError: true,
      clearInfo: true,
    );

    try {
      final result = await _backendAuthRepository.setPin(
        pin: pin,
        confirmPin: confirmPin,
      );

      state = state.copyWith(
        status: AuthSessionStatus.authenticated,
        pinSet: result.pinSet,
        pinUpdatedAt: result.pinUpdatedAt,
        infoMessage: 'PIN setup completed.',
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        status: AuthSessionStatus.failure,
        errorMessage: _friendlyError(error),
      );
    }
  }

  Future<void> updateProfile({
    required String fullName,
    String? email,
  }) async {
    if (fullName.trim().isEmpty) {
      state = state.copyWith(
        status: AuthSessionStatus.failure,
        errorMessage: 'Full name is required.',
      );
      return;
    }

    state = state.copyWith(
      status: AuthSessionStatus.authenticating,
      clearError: true,
      clearInfo: true,
    );

    try {
      final currentUser = await _backendAuthRepository.updateProfile(
        fullName: fullName.trim(),
        email: email?.trim(),
      );

      state = state.copyWith(
        status: AuthSessionStatus.authenticated,
        profileComplete: currentUser.profileComplete,
        role: currentUser.role,
        fullName: currentUser.fullName,
        email: currentUser.email,
        avatarImageId: currentUser.avatarImageId,
        avatarUrl: currentUser.avatarUrl,
        infoMessage: 'Profile saved.',
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        status: AuthSessionStatus.failure,
        errorMessage: _friendlyError(error),
      );
    }
  }

  Future<void> completeProfile({
    required String fullName,
    String? email,
    Uint8List? avatarImageBytes,
    String? avatarFileName,
  }) async {
    if (fullName.trim().isEmpty) {
      state = state.copyWith(
        status: AuthSessionStatus.failure,
        errorMessage: 'Full name is required.',
      );
      return;
    }

    state = state.copyWith(
      status: AuthSessionStatus.authenticating,
      clearError: true,
      clearInfo: true,
    );

    try {
      var currentUser = await _backendAuthRepository.updateProfile(
        fullName: fullName.trim(),
        email: email?.trim(),
      );

      if (avatarImageBytes != null &&
          avatarImageBytes.isNotEmpty &&
          avatarFileName != null &&
          avatarFileName.isNotEmpty) {
        currentUser = await _backendAuthRepository.uploadProfileImage(
          imageBytes: avatarImageBytes,
          fileName: avatarFileName,
        );
      }

      state = state.copyWith(
        status: AuthSessionStatus.authenticated,
        profileComplete: currentUser.profileComplete,
        role: currentUser.role,
        fullName: currentUser.fullName,
        email: currentUser.email,
        avatarImageId: currentUser.avatarImageId,
        avatarUrl: currentUser.avatarUrl,
        infoMessage: 'Profile saved.',
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        status: AuthSessionStatus.failure,
        errorMessage: _friendlyError(error),
      );
    }
  }

  Future<void> signOut() async {
    await _firebasePhoneAuthService.signOut();
    await _backendAuthRepository.signOutLocally();
    state = const AuthSessionState(
      status: AuthSessionStatus.unauthenticated,
    );
  }

  Future<void> refreshCurrentUser() async {
    if (!state.isAuthenticated) {
      return;
    }

    try {
      final currentUser = await _backendAuthRepository.getCurrentUser();
      state = state.copyWith(
        status: AuthSessionStatus.authenticated,
        pinSet: currentUser.pinSet,
        pinUpdatedAt: currentUser.pinUpdatedAt,
        role: currentUser.role,
        profileComplete: currentUser.profileComplete,
        fullName: currentUser.fullName,
        email: currentUser.email,
        avatarImageId: currentUser.avatarImageId,
        avatarUrl: currentUser.avatarUrl,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(errorMessage: _friendlyError(error));
    }
  }

  String _friendlyError(Object error) {
    if (error is FirebasePhoneAuthException) {
      return _firebasePhoneAuthMessage(error);
    }

    if (error is ApiException) {
      if (error.path == '/api/auth/firebase-login') {
        return 'Firebase OTP verified, but backend login failed: ${error.message}';
      }

      if (error.errors.isNotEmpty) {
        return error.errors.first;
      }

      return error.message;
    }

    final message = error.toString();
    if (message.contains('firebase_auth/invalid-verification-code')) {
      return 'Invalid OTP. Use the fixed Firebase test OTP.';
    }
    if (message.contains('firebase_auth/too-many-requests')) {
      return 'Too many attempts. Please wait before trying again.';
    }
    if (message.contains('Firebase is disabled')) {
      return 'Firebase is disabled. Run Flutter with FIREBASE_ENABLED=true.';
    }
    if (message.contains('/api/auth/firebase-login')) {
      return 'Firebase OTP verified, but backend login failed. Check the backend terminal for the exact error.';
    }

    return message;
  }

  String _firebasePhoneAuthMessage(FirebasePhoneAuthException error) {
    switch (error.code) {
      case 'invalid-phone-number':
        return 'Invalid phone number. Use +880 format or a valid BD mobile number.';
      case 'too-many-requests':
        return 'Too many OTP attempts. Please wait before trying again.';
      case 'quota-exceeded':
        return 'Firebase SMS quota is not available. Use Firebase test phone/OTP only.';
      case 'operation-not-allowed':
        return 'Firebase Phone Auth is not enabled for this project.';
      case 'app-not-authorized':
        return 'This Android app is not authorized in Firebase. Check package name and google-services.json.';
      case 'missing-client-identifier':
        return 'Firebase cannot identify this app. Recheck google-services.json and run flutter clean.';
      default:
        return 'Firebase OTP failed: ${error.message}';
    }
  }

  String? _firebaseOtpBlockReason() {
    if (!FirebaseConfig.enabled) {
      return 'Firebase is disabled. Run with --dart-define=FIREBASE_ENABLED=true.';
    }

    if (kIsWeb) {
      return 'You are running on Chrome/Web. Current SmartKash OTP setup is Android-only. Run on Android emulator, or add a Firebase Web app config first.';
    }

    if (defaultTargetPlatform != TargetPlatform.android) {
      return 'Firebase OTP is configured for Android in this MVP. Run on Android emulator for now.';
    }

    return null;
  }

  bool _isFiveDigitPin(String pin) {
    return RegExp(r'^\d{5}$').hasMatch(pin);
  }
}
