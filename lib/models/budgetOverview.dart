class BudgetOverview {
  String budgetName;
  double amount;
  double limitBudget;

  BudgetOverview({
    required this.budgetName,
    required this.amount,
    required this.limitBudget,
  });

  factory BudgetOverview.fromJson(Map<String, dynamic> json) {
    return BudgetOverview(
      budgetName: json['budgetName']?.toString() ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      limitBudget: (json['limitBudget'] ?? 0).toDouble(),
    );
  }
}