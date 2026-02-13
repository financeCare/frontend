class RepaymentStrategyResponse {
  final String strategyId;
  final String strategyName;
  final String description;
  final bool isActive;

  RepaymentStrategyResponse({
    required this.strategyId,
    required this.strategyName,
    required this.description,
    required this.isActive,
  });

  factory RepaymentStrategyResponse.fromJson(Map<String, dynamic> json) {
    return RepaymentStrategyResponse(
      strategyId: json['strategyId'],
      strategyName: json['strategyName'],
      description: json['description'],
      isActive: json['isActive'],
    );
  }
}
