import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_providers.dart';
import '../data/backend_auth_repository.dart';
import '../data/firebase_phone_auth_service.dart';

final firebasePhoneAuthServiceProvider = Provider<FirebasePhoneAuthService>(
  (ref) => FirebasePhoneAuthService(),
);

final backendAuthRepositoryProvider = Provider<BackendAuthRepository>(
  (ref) => BackendAuthRepository(
    apiClient: ref.watch(apiClientProvider),
    tokenStorage: ref.watch(secureTokenStorageProvider),
  ),
);
