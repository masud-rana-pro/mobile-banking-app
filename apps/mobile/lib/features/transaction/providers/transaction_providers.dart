import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_providers.dart';
import '../data/transaction_repository.dart';
import '../domain/transaction_summary.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>(
  (ref) => TransactionRepository(apiClient: ref.watch(apiClientProvider)),
);

final _transactionRefreshCounterProvider = StateProvider<int>((ref) => 0);

final transactionListProvider =
    FutureProvider.autoDispose<List<TransactionSummary>>(
  (ref) {
    ref.watch(_transactionRefreshCounterProvider);
    final repository = ref.watch(transactionRepositoryProvider);
    return repository.getMyTransactions();
  },
);

final transactionDetailProvider =
    FutureProvider.autoDispose.family<TransactionSummary, int>(
  (ref, id) {
    final repository = ref.watch(transactionRepositoryProvider);
    return repository.getTransactionDetail(id);
  },
);

final transactionRefreshProvider = Provider<void Function()>(
  (ref) {
    return () {
      ref.read(_transactionRefreshCounterProvider.notifier).state++;
      ref.invalidate(transactionListProvider);
    };
  },
);
