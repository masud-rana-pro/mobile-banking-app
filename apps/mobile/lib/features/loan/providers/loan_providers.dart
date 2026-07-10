import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_providers.dart';
import '../data/loan_repository.dart';
import '../domain/loan_request_summary.dart';

final loanRepositoryProvider = Provider<LoanRepository>(
  (ref) => LoanRepository(apiClient: ref.watch(apiClientProvider)),
);

final loanRequestsProvider = FutureProvider<List<LoanRequestSummary>>(
  (ref) => ref.watch(loanRepositoryProvider).getMyRequests(),
);

final loanRefreshProvider = Provider<void Function()>(
  (ref) => () => ref.invalidate(loanRequestsProvider),
);
