class DebtRequest {
  final double principalAmount;
  final double interestRate;
  final int repaymentTypeId;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final int priority;
  final int debtTypeId;
  final String debtName;
  final double minPayment;
  final int dueDate;

  DebtRequest({
    required this.principalAmount,
    required this.interestRate,
    required this.repaymentTypeId,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    required this.priority,
    required this.debtTypeId,
    required this.debtName,
    required this.minPayment,
    required this.dueDate,
  });

  factory DebtRequest.fromJson(Map<String, dynamic> json) {
    return DebtRequest(
      principalAmount: (json['principalAmount'] as num).toDouble(),
      interestRate: (json['interestRate'] as num).toDouble(),
      repaymentTypeId: json['repaymentTypeId'] ?? 0,
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      isActive: json['isActive'] ?? true,
      priority: json['priority'] ?? 0,
      debtTypeId: json['debtTypeId'] ?? 0,
      debtName: json['debtName'] ?? '',
      minPayment: (json['minPayment'] as num).toDouble(),
      dueDate: json['dueDate'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'principalAmount': principalAmount,
      'interestRate': interestRate,
      'repaymentTypeId': repaymentTypeId,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'isActive': isActive,
      'priority': priority,
      'debtTypeId': debtTypeId,
      'debtName': debtName,
      'minPayment': minPayment,
      'dueDate': dueDate,
    };
  }
}