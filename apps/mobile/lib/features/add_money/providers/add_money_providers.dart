import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_providers.dart';
import '../data/add_money_repository.dart';
import '../domain/add_money_summary.dart';

final addMoneyRepositoryProvider = Provider<AddMoneyRepository>(
  (ref) => AddMoneyRepository(apiClient: ref.watch(apiClientProvider)),
);

final addMoneyRequestsProvider = FutureProvider<List<AddMoneySummary>>(
  (ref) {
    final repository = ref.watch(addMoneyRepositoryProvider);
    return repository.getMyRequests();
  },
);

final addMoneyRefreshProvider = Provider<void Function()>(
  (ref) => () => ref.invalidate(addMoneyRequestsProvider),
);
