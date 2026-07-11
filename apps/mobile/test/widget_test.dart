import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartkash/app/smartkash_app.dart';
import 'package:smartkash/features/auth/data/firebase_phone_auth_service.dart';
import 'package:smartkash/features/auth/providers/auth_providers.dart';

void main() {
  testWidgets('SmartKash app renders without crashing', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          firebasePhoneAuthServiceProvider.overrideWithValue(
            _FakeFirebasePhoneAuthService(),
          ),
        ],
        child: const SmartKashApp(),
      ),
    );
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}

class _FakeFirebasePhoneAuthService extends FirebasePhoneAuthService {
  @override
  User? get currentUser => null;
}
