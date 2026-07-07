import 'package:flutter_riverpod/flutter_riverpod.dart';

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
        errorMessage: error.toString(),
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
}
