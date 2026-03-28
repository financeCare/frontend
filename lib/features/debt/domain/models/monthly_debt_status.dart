class MonthlyDebtStatus {
  final double totalAmount;
  final double paidAmount;
  final double remainingAmount;
  final double requiredMinPayment;
  final bool isBudgetInsufficient;

  MonthlyDebtStatus({
    required this.totalAmount,
    required this.paidAmount,
    required this.remainingAmount,
    required this.requiredMinPayment,
    required this.isBudgetInsufficient,
  });

  factory MonthlyDebtStatus.fromJson(Map<String, dynamic> json) {
    return MonthlyDebtStatus(
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (json['paidAmount'] as num?)?.toDouble() ?? 0.0,
      remainingAmount: (json['remainingAmount'] as num?)?.toDouble() ?? 0.0,
      requiredMinPayment: (json['requiredMinPayment'] as num?)?.toDouble() ?? 0.0,
      isBudgetInsufficient: (json['budgetInsufficient'] as bool?) ?? (json['isBudgetInsufficient'] as bool?) ?? false,
    );
  }
}
