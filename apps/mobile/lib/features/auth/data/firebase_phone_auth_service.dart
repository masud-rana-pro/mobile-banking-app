import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

class PhoneOtpStartResult {
  const PhoneOtpStartResult({
    required this.verificationId,
    required this.autoVerified,
  });

  final String verificationId;
  final bool autoVerified;
}

class FirebasePhoneAuthService {
  FirebasePhoneAuthService({FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth;

  final FirebaseAuth? _firebaseAuth;

  FirebaseAuth get _auth => _firebaseAuth ?? FirebaseAuth.instance;

  Stream<User?> authStateChanges() {
    return _auth.authStateChanges();
  }

  User? get currentUser => _auth.currentUser;

  Future<String?> currentIdToken({bool forceRefresh = false}) async {
    final user = _auth.currentUser;
    if (user == null) {
      return null;
    }

    return user.getIdToken(forceRefresh);
  }

  Future<PhoneOtpStartResult> startPhoneVerification(String phoneNumber) async {
    final completer = Completer<PhoneOtpStartResult>();

    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (credential) async {
        await _auth.signInWithCredential(credential);
        if (!completer.isCompleted) {
          completer.complete(
            const PhoneOtpStartResult(
              verificationId: '',
              autoVerified: true,
            ),
          );
        }
      },
      verificationFailed: (exception) {
        if (!completer.isCompleted) {
          completer.completeError(
            FirebasePhoneAuthException.fromFirebase(exception),
            StackTrace.current,
          );
        }
      },
      codeSent: (verificationId, forceResendingToken) {
        if (!completer.isCompleted) {
          completer.complete(
            PhoneOtpStartResult(
              verificationId: verificationId,
              autoVerified: false,
            ),
          );
        }
      },
      codeAutoRetrievalTimeout: (verificationId) {
        if (!completer.isCompleted) {
          completer.complete(
            PhoneOtpStartResult(
              verificationId: verificationId,
              autoVerified: false,
            ),
          );
        }
      },
    );

    return completer.future;
  }

  Future<UserCredential> signInWithSmsCode({
    required String verificationId,
    required String smsCode,
  }) {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );

    return _auth.signInWithCredential(credential);
  }

  Future<void> signOut() {
    return _auth.signOut();
  }
}

class FirebasePhoneAuthException implements Exception {
  const FirebasePhoneAuthException({
    required this.code,
    required this.message,
  });

  factory FirebasePhoneAuthException.fromFirebase(
    FirebaseAuthException exception,
  ) {
    return FirebasePhoneAuthException(
      code: exception.code,
      message: exception.message ?? exception.code,
    );
  }

  final String code;
  final String message;

  @override
  String toString() => 'Firebase phone auth failed [$code]: $message';
}
