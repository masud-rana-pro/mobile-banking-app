import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_providers.dart';
import '../data/backend_auth_repository.dart';
import '../data/firebase_phone_auth_service.dart';
import '../domain/auth_session_state.dart';
import 'auth_controller.dart';

final firebasePhoneAuthServiceProvider = Provider<FirebasePhoneAuthService>(
  (ref) => FirebasePhoneAuthService(),
);

final backendAuthRepositoryProvider = Provider<BackendAuthRepository>(
  (ref) => BackendAuthRepository(
    apiClient: ref.watch(apiClientProvider),
    tokenStorage: ref.watch(secureTokenStorageProvider),
  ),
);

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthSessionState>(
  (ref) => AuthController(
    firebasePhoneAuthService: ref.watch(firebasePhoneAuthServiceProvider),
    backendAuthRepository: ref.watch(backendAuthRepositoryProvider),
  ),
);
