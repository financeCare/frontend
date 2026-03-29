class DebtTransactionResponse {
  final String transactionId;
  final String txnType;
  final double amount;
  final DateTime txnDate;
  final String description;
  final int? slipId;

  DebtTransactionResponse({
    required this.transactionId,
    required this.txnType,
    required this.amount,
    required this.txnDate,
    required this.description,
    this.slipId,
  });

  factory DebtTransactionResponse.fromJson(Map<String, dynamic> json) {
    return DebtTransactionResponse(
      transactionId: (json['transactionId'] ?? '').toString(),
      txnType: json['txnType'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      txnDate: json['txnDate'] != null 
          ? DateTime.parse(json['txnDate']) 
          : DateTime.now(),
      description: json['description'] as String? ?? '',
      slipId: json['slipId'] as int?,
    );
  }
}
