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
  });

  factory DebtResponse.fromJson(Map<String, dynamic> json) {
    return DebtResponse(
      debtId: json['debtId'],
      userId: json['userId'],
      principalAmount: (json['principalAmount'] as num).toDouble(),
      interestRate: (json['interestRate'] as num).toDouble(),
      repaymentType: RepaymentTypeResponse.fromJson(json['repaymentType']),
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      priority: json['priority'],
      debtType: DebtTypeResponse.fromJson(json['debtType']),
      debtName: json['debtName'],
      isActive: json['active'],
      minPayment: (json['minPayment'] as num).toDouble(),
      dueDate: json['dueDate'],
    );
  }
}
