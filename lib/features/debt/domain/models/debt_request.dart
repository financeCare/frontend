import 'interest_calculation_type.dart';

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
  final int dueDay;
  final double penaltyAnnualRate;
  final int gracePeriodDays;
  final int penaltyTriggerDays;
  final bool isDefaulted;
  final bool isInformal;
  final InterestCalculationType interestCalculationType;

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
    required this.dueDay,
    this.penaltyAnnualRate = 0.0,
    this.gracePeriodDays = 0,
    this.penaltyTriggerDays = 0,
    this.isDefaulted = false,
    this.isInformal = false,
    this.interestCalculationType = InterestCalculationType.THIRTY_360,
  });

  factory DebtRequest.fromJson(Map<String, dynamic> json) {
    return DebtRequest(
      principalAmount: (json['principalAmount'] as num).toDouble(),
      interestRate: (json['interestRate'] as num).toDouble(),
      repaymentTypeId: json['repaymentTypeId'] ?? 0,
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate'] ?? DateTime.now().toIso8601String()),
      isActive: json['isActive'] ?? true,
      priority: json['priority'] ?? 0,
      debtTypeId: json['debtTypeId'] ?? 0,
      debtName: json['debtName'] ?? '',
      minPayment: (json['minPayment'] as num).toDouble(),
      dueDay: json['dueDay'] ?? 1,
      penaltyAnnualRate: (json['penaltyAnnualRate'] as num?)?.toDouble() ?? 0.0,
      gracePeriodDays: json['gracePeriodDays'] as int? ?? 0,
      penaltyTriggerDays: json['penaltyTriggerDays'] as int? ?? 0,
      isDefaulted: json['isDefaulted'] as bool? ?? false,
      isInformal: json['isInformal'] as bool? ?? false,
      interestCalculationType: InterestCalculationType.fromString(json['interestCalculationType'] as String? ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'principalAmount': principalAmount,
      'interestRate': interestRate,
      'repaymentTypeId': repaymentTypeId,
      'startDate': startDate.toIso8601String().split('T')[0],
      'endDate': endDate.toIso8601String().split('T')[0],
      'isActive': isActive,
      'priority': priority,
      'debtTypeId': debtTypeId,
      'debtName': debtName,
      'minPayment': minPayment,
      'dueDay': dueDay,
      'penaltyAnnualRate': penaltyAnnualRate,
      'gracePeriodDays': gracePeriodDays,
      'penaltyTriggerDays': penaltyTriggerDays,
      'isDefaulted': isDefaulted,
      'isInformal': isInformal,
      'interestCalculationType': interestCalculationType.name,
    };
  }
}
