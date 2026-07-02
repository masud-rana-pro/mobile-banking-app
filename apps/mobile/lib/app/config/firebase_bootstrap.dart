import 'package:firebase_core/firebase_core.dart';

import 'firebase_config.dart';

class FirebaseBootstrap {
  const FirebaseBootstrap._();

  static Future<void> initialize() async {
    if (!FirebaseConfig.enabled) {
      return;
    }

    if (Firebase.apps.isNotEmpty) {
      return;
    }

    await Firebase.initializeApp(options: FirebaseConfig.currentPlatform);
  }
}
