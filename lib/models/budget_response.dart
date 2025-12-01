class BudgetResponse {
  final String budgetId;
  final String userId;
  final double amount;
  final double limitBudget;

  BudgetResponse({
    required this.budgetId,
    required this.userId,
    required this.amount,
    required this.limitBudget,
  });

  factory BudgetResponse.fromJson(Map<String, dynamic> json) {
    return BudgetResponse(
      budgetId: json['budgetId'] as String,
      userId: json['userId'] as String,
      amount: (json['amount'] ?? 0).toDouble(), // <-- แก้ตรงนี้
      limitBudget: (json['limitBudget'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'budgetId': budgetId,
      'userId': userId,
      'amount': amount,
      'limitBudget': limitBudget,
    };
  }
}
