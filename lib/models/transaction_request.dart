class TransactionRequest {
  final String categoryId;
  final double amount;
  final DateTime transactionDate;
  final String description;

  TransactionRequest({
    required this.categoryId,
    required this.amount,
    required this.transactionDate,
    required this.description,
  });

  // สำหรับแปลงจาก JSON (response หรือ testing)
  factory TransactionRequest.fromJson(Map<String, dynamic> json) {
    return TransactionRequest(
      categoryId: json['categoryId'] ?? 0,
      amount: (json['amount'] as num).toDouble(),
      transactionDate: DateTime.parse(json['transactionDate']),
      description: json['description'] ?? '',
    );
  }

  // สำหรับส่ง POST request
  Map<String, dynamic> toJson() {
    return {
      'categoryId': categoryId,
      'amount': amount,
      'transactionDate': transactionDate.toIso8601String(),
      'description': description,
    };
  }
}