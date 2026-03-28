class MonthlyDebtStatus {
  final double totalAmount;
  final double paidAmount;
  final double remainingAmount;

  MonthlyDebtStatus({
    required this.totalAmount,
    required this.paidAmount,
    required this.remainingAmount,
  });

  factory MonthlyDebtStatus.fromJson(Map<String, dynamic> json) {
    return MonthlyDebtStatus(
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (json['paidAmount'] as num?)?.toDouble() ?? 0.0,
      remainingAmount: (json['remainingAmount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
