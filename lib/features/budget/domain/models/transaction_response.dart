import 'category.dart';

class TransactionResponse {
  final String transactionId;
  final double amount;
  final DateTime transactionDate;
  final String description;
  final Categories category;
  final String? senderBank;
  final String? receiverName;
  final String? imagePath;
  final int? slipId;

  TransactionResponse({
    required this.transactionId,
    required this.amount,
    required this.transactionDate,
    required this.description,
    required this.category,
    this.senderBank,
    this.receiverName,
    this.imagePath,
    this.slipId,
  });

  factory TransactionResponse.fromJson(Map<String, dynamic> json) {
    return TransactionResponse(
      transactionId: json['transactionId'] as String,
      amount: (json['amount'] as num).toDouble(),
      transactionDate: DateTime.parse(json['transactionDate']),
      description: json['description'] as String? ?? '',
      category: Categories.fromJson(
        (json['categoryDTO'] ?? json['category']) as Map<String, dynamic>? ?? {},
      ),
      senderBank: json['senderBank'] as String?,
      receiverName: json['receiverName'] as String?,
      imagePath: json['imagePath'] as String?,
      slipId: json['slipId'] as int?,
    );
  }
}