class DebtTypeResponse {
  final int debtTypeId;
  final String debtTypeName;
  final String debtTypeDescription;

  DebtTypeResponse({
    required this.debtTypeId,
    required this.debtTypeName,
    required this.debtTypeDescription,
  });

  factory DebtTypeResponse.fromJson(Map<String, dynamic> json) {
    return DebtTypeResponse(
      debtTypeId: json['debtTypeId'] ?? 0,
      debtTypeName: json['debtTypeName'] ?? '',
      debtTypeDescription: json['debtTypeDescription'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'debtTypeId': debtTypeId,
      'debtTypeName': debtTypeName,
      'debtTypeDescription': debtTypeDescription,
    };
  }
}
