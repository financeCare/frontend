class RepaymentSimulationResponse {
  final int estimatedMonths;
  final double totalInterest;
  final double totalPaid;
  final List<MonthlyResult> monthlyResults;

  RepaymentSimulationResponse({
    required this.estimatedMonths,
    required this.totalInterest,
    required this.totalPaid,
    required this.monthlyResults,
  });

  factory RepaymentSimulationResponse.fromJson(Map<String, dynamic> json) {
    return RepaymentSimulationResponse(
      estimatedMonths: json['estimatedMonths'] ?? 0,
      totalInterest: (json['totalInterest'] as num?)?.toDouble() ?? 0.0,
      totalPaid: (json['totalPaid'] as num?)?.toDouble() ?? 0.0,
      monthlyResults:
          (json['monthlyResults'] as List?)
              ?.map((e) => MonthlyResult.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class MonthlyResult {
  final int monthNo;
  final double monthInterest;
  final double paidThisMonth;
  final double remainingDebtTotal;
  final List<DebtPayment> debtPayments;

  MonthlyResult({
    required this.monthNo,
    required this.monthInterest,
    required this.paidThisMonth,
    required this.remainingDebtTotal,
    required this.debtPayments,
  });

  factory MonthlyResult.fromJson(Map<String, dynamic> json) {
    return MonthlyResult(
      monthNo: json['monthNo'] ?? 0,
      monthInterest: (json['monthInterest'] as num?)?.toDouble() ?? 0.0,
      paidThisMonth: (json['paidThisMonth'] as num?)?.toDouble() ?? 0.0,
      remainingDebtTotal:
          (json['remainingDebtTotal'] as num?)?.toDouble() ?? 0.0,
      debtPayments:
          (json['debtPayments'] as List?)
              ?.map((e) => DebtPayment.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class DebtPayment {
  final String debtId;
  final String debtName;
  final double beforeBalance;
  final double interestAdded;
  final double minPaid;
  final double extraPaid;
  final double afterBalance;

  DebtPayment({
    required this.debtId,
    required this.debtName,
    required this.beforeBalance,
    required this.interestAdded,
    required this.minPaid,
    required this.extraPaid,
    required this.afterBalance,
  });

  factory DebtPayment.fromJson(Map<String, dynamic> json) {
    return DebtPayment(
      debtId: json['debtId']?.toString() ?? '',
      debtName: json['debtName']?.toString() ?? '',
      beforeBalance: (json['beforeBalance'] as num?)?.toDouble() ?? 0.0,
      interestAdded: (json['interestAdded'] as num?)?.toDouble() ?? 0.0,
      minPaid: (json['minPaid'] as num?)?.toDouble() ?? 0.0,
      extraPaid: (json['extraPaid'] as num?)?.toDouble() ?? 0.0,
      afterBalance: (json['afterBalance'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
