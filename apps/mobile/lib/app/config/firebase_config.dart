import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class FirebaseConfig {
  const FirebaseConfig._();

  static const bool enabled = bool.fromEnvironment(
    'FIREBASE_ENABLED',
    defaultValue: true,
  );

  static const FirebaseOptions androidOptions = FirebaseOptions(
    apiKey: String.fromEnvironment('FIREBASE_ANDROID_API_KEY'),
    appId: String.fromEnvironment('FIREBASE_ANDROID_APP_ID'),
    messagingSenderId: String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID'),
    projectId: String.fromEnvironment('FIREBASE_PROJECT_ID'),
  );

  static bool get hasAndroidDartDefines {
    return androidOptions.apiKey.isNotEmpty &&
        androidOptions.appId.isNotEmpty &&
        androidOptions.messagingSenderId.isNotEmpty &&
        androidOptions.projectId.isNotEmpty;
  }

  static FirebaseOptions? get currentPlatform {
    if (!enabled) {
      throw StateError('Phone sign-in is disabled for this app run.');
    }

    if (defaultTargetPlatform != TargetPlatform.android) {
      throw UnsupportedError(
          'SmartKash sign-in is currently configured for Android.');
    }

    if (!hasAndroidDartDefines) {
      return null;
    }

    return androidOptions;
  }
}
