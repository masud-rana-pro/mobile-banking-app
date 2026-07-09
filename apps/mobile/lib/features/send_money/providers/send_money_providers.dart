import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_providers.dart';
import '../data/send_money_repository.dart';

final sendMoneyRepositoryProvider = Provider<SendMoneyRepository>(
  (ref) => SendMoneyRepository(apiClient: ref.watch(apiClientProvider)),
);
