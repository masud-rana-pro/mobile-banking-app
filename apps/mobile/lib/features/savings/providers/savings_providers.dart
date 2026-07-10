import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_providers.dart';
import '../data/savings_repository.dart';
import '../domain/savings_goal.dart';

final savingsRepositoryProvider = Provider<SavingsRepository>(
  (ref) => SavingsRepository(apiClient: ref.watch(apiClientProvider)),
);

final savingsGoalsProvider = FutureProvider<List<SavingsGoal>>(
  (ref) => ref.watch(savingsRepositoryProvider).getMyGoals(),
);

final savingsRefreshProvider = Provider<void Function()>(
  (ref) => () => ref.invalidate(savingsGoalsProvider),
);
