import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/firebase_phone_auth_service.dart';

final firebasePhoneAuthServiceProvider = Provider<FirebasePhoneAuthService>(
  (ref) => FirebasePhoneAuthService(),
);
