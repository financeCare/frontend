import 'interest_calculation_type.dart';
import 'package:flutter_application_1/features/debt/domain/models/debt_type_response.dart';
import 'package:flutter_application_1/features/debt/domain/models/repayment_type_response.dart';

class DebtResponse {
  final String debtId;
  final String userId;
  final double principalAmount;
  final double interestRate;
  final RepaymentTypeResponse repaymentType;
  final DateTime startDate;
  final DateTime endDate;
  final int priority;
  final DebtTypeResponse debtType;
  final String debtName;
  final bool isActive;
  final double minPayment;
  final int? dueDate;
  final double penaltyAnnualRate;
  final int gracePeriodDays;
  final int penaltyTriggerDays;
  final bool isDefaulted;
  final bool isInformal;
  final InterestCalculationType interestCalculationType;

  DebtResponse({
    required this.debtId,
    required this.userId,
    required this.principalAmount,
    required this.interestRate,
    required this.repaymentType,
    required this.startDate,
    required this.endDate,
    required this.priority,
    required this.debtType,
    required this.debtName,
    required this.isActive,
    required this.minPayment,
    required this.dueDate,
    this.penaltyAnnualRate = 0.0,
    this.gracePeriodDays = 0,
    this.penaltyTriggerDays = 0,
    this.isDefaulted = false,
    this.isInformal = false,
    this.interestCalculationType = InterestCalculationType.THIRTY_360,
  });

  factory DebtResponse.fromJson(Map<String, dynamic> json) {
    return DebtResponse(
      debtId: json['debtId'] ?? '',
      userId: json['userId'] ?? '',
      principalAmount: (json['principalAmount'] as num?)?.toDouble() ?? 0.0,
      interestRate: (json['interestRate'] as num?)?.toDouble() ?? 0.0,
      repaymentType: json['repaymentType'] != null 
          ? RepaymentTypeResponse.fromJson(json['repaymentType'])
          : RepaymentTypeResponse(typeId: 0, typeName: "Unknown", description: ""),
      startDate: json['startDate'] != null ? DateTime.parse(json['startDate']) : DateTime.now(),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : DateTime.now(),
      priority: json['priority'] ?? 0,
      debtType: json['debtType'] != null 
          ? DebtTypeResponse.fromJson(json['debtType'])
          : DebtTypeResponse(debtTypeId: 0, debtTypeName: "Unknown", debtTypeDescription: ""),
      debtName: json['debtName'] ?? '',
      isActive: json['active'] ?? json['isActive'] ?? true,
      minPayment: (json['minPayment'] as num?)?.toDouble() ?? 0.0,
      dueDate: json['dueDate'] ?? json['dueDay'] ?? 1,
      penaltyAnnualRate: (json['penaltyAnnualRate'] as num?)?.toDouble() ?? 0.0,
      gracePeriodDays: json['gracePeriodDays'] as int? ?? 0,
      penaltyTriggerDays: json['penaltyTriggerDays'] as int? ?? 0,
      isDefaulted: json['isDefaulted'] as bool? ?? false,
      isInformal: json['isInformal'] as bool? ?? false,
      interestCalculationType: InterestCalculationType.fromString(json['interestCalculationType'] as String? ?? ''),
    );
  }
}
