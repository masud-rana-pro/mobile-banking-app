import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_providers.dart';
import '../data/transaction_repository.dart';
import '../domain/transaction_summary.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>(
  (ref) => TransactionRepository(apiClient: ref.watch(apiClientProvider)),
);

final transactionListProvider = FutureProvider<List<TransactionSummary>>(
  (ref) {
    final repository = ref.watch(transactionRepositoryProvider);
    return repository.getMyTransactions();
  },
);

final transactionDetailProvider =
    FutureProvider.family<TransactionSummary, int>(
  (ref, id) {
    final repository = ref.watch(transactionRepositoryProvider);
    return repository.getTransactionDetail(id);
  },
);

final transactionRefreshProvider = Provider<void Function()>(
  (ref) {
    return () => ref.invalidate(transactionListProvider);
  },
);
