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
      strategyId: json['strategyId']?.toString() ?? '',
      strategyName: json['strategyName']?.toString() ?? 'Unknown Strategy',
      description: json['description']?.toString() ?? '',
      isActive: json['isActive'] == true || json['isActive'] == 1,
      tags: json['tags'] != null ? List<String>.from(json['tags']) : [],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }
}
