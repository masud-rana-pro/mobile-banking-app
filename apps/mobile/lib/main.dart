import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/config/firebase_bootstrap.dart';
import 'app/smartkash_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseBootstrap.initialize();

  runApp(const ProviderScope(child: SmartKashApp()));
}
