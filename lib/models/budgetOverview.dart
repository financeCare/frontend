class BudgetOverview {
  String? budgetId;
  String budgetName;
  double amount;
  double limitBudget;
  String categoryId;

  BudgetOverview({
    required this.budgetName,
    required this.amount,
    required this.limitBudget,
    required this.categoryId,
  });

  factory BudgetOverview.fromJson(Map<String, dynamic> json) {
    return BudgetOverview(
      budgetName: json['budgetName']?.toString() ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      limitBudget: (json['limitBudget'] ?? 0).toDouble(),
      categoryId: json['categoryId']?.toString() ?? '',
    );
  }
}