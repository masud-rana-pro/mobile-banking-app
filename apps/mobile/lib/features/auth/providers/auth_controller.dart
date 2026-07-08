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

      state = AuthSessionState(
        status: AuthSessionStatus.authenticated,
        backendToken: backendToken,
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

  String _friendlyError(Object error) {
    if (error is ApiException) {
      return 'Firebase OTP verified, but backend login failed. Check backend Firebase Admin env values.';
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
      return 'Firebase OTP verified, but backend login failed. Check backend Firebase Admin env values.';
    }

    return message;
  }
}
