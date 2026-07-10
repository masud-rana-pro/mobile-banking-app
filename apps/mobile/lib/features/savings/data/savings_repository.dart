import 'dart:math';

import '../../../core/network/api_client.dart';
import '../domain/savings_deposit_result.dart';
import '../domain/savings_goal.dart';

class SavingsRepository {
  SavingsRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;
  final _random = Random();

  Future<List<SavingsGoal>> getMyGoals() async {
    final response = await _apiClient.get<List<dynamic>>('/api/savings/goals');
    final data = response.data ?? const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(SavingsGoal.fromJson)
        .toList();
  }

  Future<SavingsGoal> createGoal({
    required String name,
    required double targetAmount,
    DateTime? targetDate,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/api/savings/goals',
      data: {
        'name': name,
        'targetAmount': targetAmount,
        if (targetDate != null)
          'targetDate': targetDate.toIso8601String().substring(0, 10),
      },
    );

    return SavingsGoal.fromJson(response.data ?? const {});
  }

  Future<SavingsDepositResult> deposit({
    required int goalId,
    required double amount,
    required String pin,
    required String idempotencyKey,
    String? note,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/api/savings/goals/$goalId/deposit',
      data: {
        'amount': amount,
        'pin': pin,
        'idempotencyKey': idempotencyKey,
        if (note != null && note.isNotEmpty) 'note': note,
      },
    );

    return SavingsDepositResult.fromJson(response.data ?? const {});
  }

  String createIdempotencyKey() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = _random.nextInt(999999);
    return 'SG-$timestamp-$random';
  }
}
