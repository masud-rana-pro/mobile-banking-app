import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_providers.dart';
import '../data/wallet_repository.dart';
import '../domain/wallet_summary.dart';

final walletRepositoryProvider = Provider<WalletRepository>(
  (ref) => WalletRepository(apiClient: ref.watch(apiClientProvider)),
);

final walletSummaryProvider = FutureProvider<WalletSummary>(
  (ref) {
    final repository = ref.watch(walletRepositoryProvider);
    return repository.getMyWallet();
  },
);

final walletRefreshProvider = Provider<void Function()>(
  (ref) {
    return () => ref.invalidate(walletSummaryProvider);
  },
);
