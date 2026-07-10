class SavingsGoal {
  const SavingsGoal({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.currentAmount,
    required this.status,
    this.targetDate,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final String status;
  final DateTime? targetDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  double get progress {
    if (targetAmount <= 0) {
      return 0;
    }
    return (currentAmount / targetAmount).clamp(0, 1);
  }

  factory SavingsGoal.fromJson(Map<String, dynamic> json) {
    return SavingsGoal(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      targetAmount: (json['targetAmount'] as num?)?.toDouble() ?? 0,
      currentAmount: (json['currentAmount'] as num?)?.toDouble() ?? 0,
      targetDate: json['targetDate'] != null
          ? DateTime.tryParse(json['targetDate'] as String)
          : null,
      status: json['status'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }
}
