class BudgetOverview {
  final String? budgetId;
  final String budgetName;
  final double amount;
  final double limitBudget;
  final String categoryId;

  BudgetOverview({
    this.budgetId,
    required this.budgetName,
    required this.amount,
    required this.limitBudget,
    required this.categoryId,
  });

  BudgetOverview copyWith({
    String? budgetId,
    String? budgetName,
    double? amount,
    double? limitBudget,
    String? categoryId,
  }) {
    return BudgetOverview(
      budgetId: budgetId ?? this.budgetId,
      budgetName: budgetName ?? this.budgetName,
      amount: amount ?? this.amount,
      limitBudget: limitBudget ?? this.limitBudget,
      categoryId: categoryId ?? this.categoryId,
    );
  }

  factory BudgetOverview.fromJson(Map<String, dynamic> json) {
    return BudgetOverview(
      budgetId:
          json['budgetId']?.toString() ??
          json['budget_id']?.toString() ??
          json['id']?.toString(),
      budgetName:
          json['budgetName']?.toString() ??
          json['budget_name']?.toString() ??
          json['name']?.toString() ??
          json['categoryName']?.toString() ??
          json['category_name']?.toString() ??
          '',
      amount:
          (json['amount'] ??
                  json['totalSpent'] ??
                  json['total_spent'] ??
                  json['spent'] ??
                  json['used'] ??
                  0)
              .toDouble(),
      limitBudget:
          (json['limitBudget'] ??
                  json['limit_budget'] ??
                  json['total_budget'] ??
                  json['totalBudget'] ??
                  json['budgetLimit'] ??
                  json['budget_limit'] ??
                  json['budget'] ??
                  json['limit'] ??
                  0)
              .toDouble(),
      categoryId:
          json['categoryId']?.toString() ??
          json['category_id']?.toString() ??
          '',
    );
  }

  @override
  String toString() {
    return 'BudgetOverview(budgetId: $budgetId, budgetName: $budgetName, amount: $amount, limitBudget: $limitBudget, categoryId: $categoryId)';
  }
}
