class RepaymentStrategyResponse {
  final String strategyId;
  final String strategyName;
  final String description;
  final bool isActive;
  final DateTime? createdAt;
  final List<String> tags;

  RepaymentStrategyResponse({
    required this.strategyId,
    required this.strategyName,
    required this.description,
    required this.isActive,
    required this.tags,
    this.createdAt,
  });

  factory RepaymentStrategyResponse.fromJson(Map<String, dynamic> json) {
    return RepaymentStrategyResponse(
      strategyId: json['strategyId'],
      strategyName: json['strategyName'],
      description: json['description'],
      isActive: json['isActive'],
      tags: List<String>.from(json['tags'] ?? []),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
    );
  }
}
