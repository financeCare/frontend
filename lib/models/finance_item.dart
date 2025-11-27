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
    this.type = "General",
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      "name": name,
      "amount": amount,
      "interest": interest,
      "type": type,
      "createdAt": createdAt.toIso8601String(),
    };
  }

  factory FinanceItem.fromJson(Map<String, dynamic> json) {
    return FinanceItem(
      name: json['name'],
      amount: (json['amount'] as num).toDouble(),
      interest: json['interest'] != null ? (json['interest'] as num).toDouble() : 0,
      type: json['type'] ?? 'General',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
}
