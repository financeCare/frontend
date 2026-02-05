class DebtDto {
  int id;
  String name;
  double amount;
  double interest;
  String type;
  DateTime createdAt;

  DebtDto({
    required this.id,
    required this.name,
    required this.amount,
    this.interest = 0,
    this.type = "General",
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "amount": amount,
      "interest": interest,
      "type": type,
      "createdAt": createdAt.toIso8601String(),
    };
  }

  factory DebtDto.fromJson(Map<String, dynamic> json) {
    return DebtDto(
      id: json['id'],
      name: json['name'],
      amount: (json['amount'] as num).toDouble(),
      interest: json['interest'] != null ? (json['interest'] as num).toDouble() : 0,
      type: json['type'] ?? 'General',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  get principalAmount => null;

  get interestRate => null;

  get repaymentTypeId => null;

  get startDate => null;

  get endDate => null;

  get isActive => null;

  get priority => null;

  get debtTypeId => null;

  get debtName => null;
  static double totalAmount(List<DebtDto> items) {
    return items.fold(0.0, (sum, item) => sum + item.amount);
  }
}

