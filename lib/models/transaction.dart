class Transaction {
  final int categoryId;
  final double amount;
  final DateTime transactionDate;
  final String description;
  final String type; // "Expense" หรือ "Income"
  final String budgetId;

  Transaction({
    required this.categoryId,
    required this.amount,
    required this.transactionDate,
    required this.description,
    required this.type,
    required this.budgetId,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      categoryId: json['categoryid'] as int,
      amount: json['amount'] as double,
      transactionDate: DateTime.parse(json['transactionDate']),
      description: json['description'] as String,
      type: json['type'] as String,
      budgetId: json['budgetid'] as String,
    );
  }
}