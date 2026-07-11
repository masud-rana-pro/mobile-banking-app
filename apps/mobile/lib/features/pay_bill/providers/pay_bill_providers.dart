import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_providers.dart';
import '../data/pay_bill_repository.dart';

final payBillRepositoryProvider = Provider<PayBillRepository>(
  (ref) => PayBillRepository(apiClient: ref.watch(apiClientProvider)),
);
