class TransactionResponse {
  final int categoryId;
  final double amount;
  final DateTime transactionDate;
  final String description;

  TransactionResponse({
    required this.categoryId,
    required this.amount,
    required this.transactionDate,
    required this.description,
  });

  factory TransactionResponse.fromJson(Map<String, dynamic> json) {
    return TransactionResponse(
      categoryId: json['categoryId'] as int,
      amount: json['amount'] as double,
      transactionDate: DateTime.parse(json['transactionDate']),
      description: json['description'] as String,
    );
  }
}