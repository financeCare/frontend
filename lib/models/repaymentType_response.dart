class RepaymentTypeResponse {
  final int typeId;
  final String typeName;
  final String description;

  RepaymentTypeResponse({
    required this.typeId,
    required this.typeName,
    required this.description,
  });

  factory RepaymentTypeResponse.fromJson(Map<String, dynamic> json) {
    return RepaymentTypeResponse(
      typeId: json['repaymentTypeId'] ?? 0,
      typeName: json['repaymentTypeName'] ?? '',
      description: json['repaymentTypeDescription'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'repaymentTypeId': typeId,
      'repaymentTypeName': typeName,
      'repaymentTypeDescription': description,
    };
  }
}
