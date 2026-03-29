class MonthlyStatusResponse {
  final double totalAmount;
  final double paidAmount;
  final double remainingAmount;

  MonthlyStatusResponse({
    required this.totalAmount,
    required this.paidAmount,
    required this.remainingAmount,
  });

  factory MonthlyStatusResponse.fromJson(Map<String, dynamic> json) {
    return MonthlyStatusResponse(
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (json['paidAmount'] as num?)?.toDouble() ?? 0.0,
      remainingAmount: (json['remainingAmount'] as num?)?.toDouble() ?? 0.0,
    );
  }

  factory MonthlyStatusResponse.empty() {
    return MonthlyStatusResponse(
      totalAmount: 0.0,
      paidAmount: 0.0,
      remainingAmount: 0.0,
    );
  }
}
