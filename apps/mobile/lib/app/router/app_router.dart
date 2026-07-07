import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/home/presentation/home_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: HomeScreen.routePath,
  routes: [
    GoRoute(
      path: HomeScreen.routePath,
      name: HomeScreen.routeName,
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: LoginScreen.routePath,
      name: LoginScreen.routeName,
      builder: (context, state) => const LoginScreen(),
    ),
  ],
);
