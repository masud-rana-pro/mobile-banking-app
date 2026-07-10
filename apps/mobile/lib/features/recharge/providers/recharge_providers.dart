import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_providers.dart';
import '../data/recharge_repository.dart';
import '../domain/mobile_recharge_record.dart';

final rechargeRepositoryProvider = Provider<RechargeRepository>(
  (ref) => RechargeRepository(apiClient: ref.watch(apiClientProvider)),
);

final mobileRechargeHistoryProvider =
    FutureProvider<List<MobileRechargeRecord>>(
  (ref) => ref.watch(rechargeRepositoryProvider).getMyRecharges(),
);

final mobileRechargeRefreshProvider = Provider<void Function()>(
  (ref) => () => ref.invalidate(mobileRechargeHistoryProvider),
);
