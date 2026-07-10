import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_providers.dart';
import '../data/payment_repository.dart';

final paymentRepositoryProvider = Provider<PaymentRepository>(
  (ref) => PaymentRepository(apiClient: ref.watch(apiClientProvider)),
);
