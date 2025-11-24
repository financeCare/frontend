class FinanceItem {
  String name;
  double amount;
  double interest;
  String type;
  DateTime createdAt;

  FinanceItem({
    required this.name,
    required this.amount,
    this.interest = 0,
    this.type = "",
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}
