import 'interest_calculation_type.dart';
import 'interest_interval.dart';
import 'payment_interval.dart';
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
  final int? dueDay;
  final double penaltyAnnualRate;
  final int gracePeriodDays;
  final int penaltyTriggerDays;
  final bool isDefaulted;
  final bool isInformal;
  final InterestCalculationType interestCalculationType;
  final InterestInterval interestInterval;
  final PaymentInterval paymentInterval;
  final double principalOutstanding;
  final double interestRemaining;
  final double lateFeeRemaining;
  final double penaltyInterestRemaining;
  final double interestRemainingMonth;
  final double lateFeeRemainingMonth;
  final double penaltyInterestRemainingMonth;
  final double totalRemaining;
  final double initialInterestRemaining;
  final double initialLateFeeRemaining;
  final double initialPenaltyRemaining;

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
    required this.dueDay,
    this.penaltyAnnualRate = 0.0,
    this.gracePeriodDays = 0,
    this.penaltyTriggerDays = 0,
    this.isDefaulted = false,
    this.isInformal = false,
    this.interestCalculationType = InterestCalculationType.THIRTY_360,
    this.interestInterval = InterestInterval.YEARLY,
    this.paymentInterval = PaymentInterval.MONTHLY,
    this.principalOutstanding = 0.0,
    this.interestRemaining = 0.0,
    this.lateFeeRemaining = 0.0,
    this.penaltyInterestRemaining = 0.0,
    this.interestRemainingMonth = 0.0,
    this.lateFeeRemainingMonth = 0.0,
    this.penaltyInterestRemainingMonth = 0.0,
    this.totalRemaining = 0.0,
    this.initialInterestRemaining = 0.0,
    this.initialLateFeeRemaining = 0.0,
    this.initialPenaltyRemaining = 0.0,
  });

  factory DebtResponse.fromJson(Map<String, dynamic> json) {
    final debtJson = json['debt'] ?? json;
    final summaryJson = json['summary'];

    return DebtResponse(
      debtId: debtJson['debtId'] ?? '',
      userId: debtJson['userId'] ?? '',
      principalAmount: (debtJson['principalAmount'] as num?)?.toDouble() ?? 0.0,
      interestRate: (debtJson['interestRate'] as num?)?.toDouble() ?? 0.0,
      repaymentType: debtJson['repaymentType'] != null 
          ? RepaymentTypeResponse.fromJson(debtJson['repaymentType'])
          : RepaymentTypeResponse(typeId: 0, typeName: "ไม่ระบุ", description: ""),
      startDate: debtJson['startDate'] != null ? DateTime.parse(debtJson['startDate']) : DateTime.now(),
      endDate: debtJson['endDate'] != null ? DateTime.parse(debtJson['endDate']) : DateTime.now(),
      priority: debtJson['priority'] ?? 0,
      debtType: debtJson['debtType'] != null 
          ? DebtTypeResponse.fromJson(debtJson['debtType'])
          : DebtTypeResponse(debtTypeId: 0, debtTypeName: "ไม่ระบุ", debtTypeDescription: ""),
      debtName: debtJson['debtName'] ?? '',
      isActive: debtJson['active'] ?? debtJson['isActive'] ?? true,
      minPayment: (debtJson['minPayment'] as num?)?.toDouble() ?? 0.0,
      dueDay: debtJson['dueDay'] ?? debtJson['dueDate'] ?? 1,
      penaltyAnnualRate: (debtJson['penaltyAnnualRate'] as num?)?.toDouble() ?? 0.0,
      gracePeriodDays: debtJson['gracePeriodDays'] as int? ?? 0,
      penaltyTriggerDays: debtJson['penaltyTriggerDays'] as int? ?? 0,
      isDefaulted: debtJson['isDefaulted'] as bool? ?? false,
      isInformal: debtJson['isInformal'] as bool? ?? false,
      interestCalculationType: InterestCalculationType.fromString(debtJson['interestCalculationType'] as String? ?? ''),
      interestInterval: InterestInterval.fromString(debtJson['interestInterval'] as String?),
      paymentInterval: PaymentInterval.fromString(debtJson['paymentInterval'] as String?),
      principalOutstanding: summaryJson != null 
          ? (summaryJson['principalRemaining'] as num?)?.toDouble() ?? (debtJson['principalOutstanding'] as num?)?.toDouble() ?? 0.0
          : (debtJson['principalOutstanding'] as num?)?.toDouble() ?? 0.0,
      interestRemaining: summaryJson != null ? (summaryJson['interestRemaining'] as num?)?.toDouble() ?? 0.0 : 0.0,
      lateFeeRemaining: summaryJson != null ? (summaryJson['lateFeeRemaining'] as num?)?.toDouble() ?? 0.0 : 0.0,
      penaltyInterestRemaining: summaryJson != null ? (summaryJson['penaltyInterestRemaining'] as num?)?.toDouble() ?? 0.0 : 0.0,
      interestRemainingMonth: summaryJson != null ? (summaryJson['interestRemainingMonth'] as num?)?.toDouble() ?? 0.0 : 0.0,
      lateFeeRemainingMonth: summaryJson != null ? (summaryJson['lateFeeRemainingMonth'] as num?)?.toDouble() ?? 0.0 : 0.0,
      penaltyInterestRemainingMonth: summaryJson != null ? (summaryJson['penaltyInterestRemainingMonth'] as num?)?.toDouble() ?? 0.0 : 0.0,
      totalRemaining: summaryJson != null ? (summaryJson['totalRemaining'] as num?)?.toDouble() ?? 0.0 : 0.0,
      initialInterestRemaining: (debtJson['initialInterestRemaining'] as num?)?.toDouble() ?? 0.0,
      initialLateFeeRemaining: (debtJson['initialLateFeeRemaining'] as num?)?.toDouble() ?? 0.0,
      initialPenaltyRemaining: (debtJson['initialPenaltyRemaining'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
