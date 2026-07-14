import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_providers.dart';
import '../services/recipient_profile_repository.dart';

final recipientProfileRepositoryProvider = Provider<RecipientProfileRepository>(
  (ref) => RecipientProfileRepository(apiClient: ref.watch(apiClientProvider)),
);
