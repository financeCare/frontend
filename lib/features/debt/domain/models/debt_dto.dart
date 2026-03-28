class DebtDto {
  String id;
  String name;
  double amount;
  double outstandingAmount;
  double interest;
  String type;
  double interestRemaining;
  double lateFeeRemaining;
  double penaltyInterestRemaining;
  DateTime createdAt;

  DebtDto({
    required this.id,
    required this.name,
    required this.amount,
    this.outstandingAmount = 0,
    this.interest = 0,
    this.type = "General",
    this.interestRemaining = 0,
    this.lateFeeRemaining = 0,
    this.penaltyInterestRemaining = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "amount": amount,
      "outstandingAmount": outstandingAmount,
      "interest": interest,
      "type": type,
      "interestRemaining": interestRemaining,
      "lateFeeRemaining": lateFeeRemaining,
      "penaltyInterestRemaining": penaltyInterestRemaining,
      "createdAt": createdAt.toIso8601String(),
    };
  }

  factory DebtDto.fromJson(Map<String, dynamic> json) {
    return DebtDto(
      id: json['id'],
      name: json['name'],
      amount: (json['amount'] as num).toDouble(),
      outstandingAmount: (json['outstandingAmount'] as num?)?.toDouble() ?? (json['amount'] as num).toDouble(),
      interest: json['interest'] != null
          ? (json['interest'] as num).toDouble()
          : 0,
      type: json['type'] ?? 'General',
      interestRemaining: (json['interestRemaining'] as num?)?.toDouble() ?? 0.0,
      lateFeeRemaining: (json['lateFeeRemaining'] as num?)?.toDouble() ?? 0.0,
      penaltyInterestRemaining: (json['penaltyInterestRemaining'] as num?)?.toDouble() ?? 0.0,
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
