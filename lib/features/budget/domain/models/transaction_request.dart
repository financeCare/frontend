class TransactionRequest {
  final int categoryId;
  final double amount;
  final DateTime transactionDate;
  final String description;
  final String? budgetId;
  final String? senderBank;
  final String? receiverName;
  final String? imagePath;
  final int? slipId;

  TransactionRequest({
    required this.categoryId,
    required this.amount,
    required this.transactionDate,
    required this.description,
    this.budgetId,
    this.senderBank,
    this.receiverName,
    this.imagePath,
    this.slipId,
  });

  factory TransactionRequest.fromJson(Map<String, dynamic> json) {
    return TransactionRequest(
      categoryId: json['categoryId'] ?? 0,
      amount: (json['amount'] as num).toDouble(),
      transactionDate: DateTime.parse(json['transactionDate']),
      description: json['description'] ?? '',
      budgetId: json['budgetId'],
      senderBank: json['senderBank'],
      receiverName: json['receiverName'],
      imagePath: json['imagePath'],
      slipId: json['slipId'] is int ? json['slipId'] : (json['slipId'] != null ? int.tryParse(json['slipId'].toString()) : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'categoryId': categoryId,
      'amount': amount,
      'transactionDate': transactionDate.toIso8601String(),
      'description': description,
      if (budgetId != null) 'budgetId': budgetId,
      if (senderBank != null) 'senderBank': senderBank,
      if (receiverName != null) 'receiverName': receiverName,
      if (imagePath != null) 'imagePath': imagePath,
      if (slipId != null) 'slipId': slipId,
    };
  }
}
