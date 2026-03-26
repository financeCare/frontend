class DebtPriorityResponse {
  final String debtId;
  final String debtName;
  final int priority;
  final double principalAmount;

  DebtPriorityResponse({
    required this.debtId,
    required this.debtName,
    required this.priority,
    required this.principalAmount,
  });

  factory DebtPriorityResponse.fromJson(Map<String, dynamic> json) {
    return DebtPriorityResponse(
      debtId: json['debtId']?.toString() ?? '',
      debtName: json['debtName']?.toString() ?? '',
      priority: json['priority'] ?? 0,
      principalAmount: (json['principalAmount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class DebtPriorityUpdateRequest {
  final String debtId;
  final int priority;

  DebtPriorityUpdateRequest({
    required this.debtId,
    required this.priority,
  });

  Map<String, dynamic> toJson() {
    return {
      'debtId': debtId,
      'priority': priority,
    };
  }
}
