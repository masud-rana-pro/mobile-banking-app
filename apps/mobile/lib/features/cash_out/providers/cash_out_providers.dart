import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_providers.dart';
import '../data/cash_out_repository.dart';

final cashOutRepositoryProvider = Provider<CashOutRepository>(
  (ref) => CashOutRepository(apiClient: ref.watch(apiClientProvider)),
);
