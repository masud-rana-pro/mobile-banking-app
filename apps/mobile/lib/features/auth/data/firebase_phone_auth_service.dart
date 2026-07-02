import 'package:firebase_auth/firebase_auth.dart';

class FirebasePhoneAuthService {
  FirebasePhoneAuthService({FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseAuth _firebaseAuth;

  Stream<User?> authStateChanges() {
    return _firebaseAuth.authStateChanges();
  }

  User? get currentUser => _firebaseAuth.currentUser;

  Future<String?> currentIdToken({bool forceRefresh = false}) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      return null;
    }

    return user.getIdToken(forceRefresh);
  }
}
