import 'category.dart';

class TransactionDetail {
  final String transactionId;
  final String userId;
  final Categories category;
  final double amount;
  final DateTime transactionDate;
  final String description;
  final String? senderBank;
  final String? receiverName;
  final String? imagePath;
  final int? slipId;

  TransactionDetail({
    required this.transactionId,
    required this.userId,
    required this.category,
    required this.amount,
    required this.transactionDate,
    required this.description,
    this.senderBank,
    this.receiverName,
    this.imagePath,
    this.slipId,
  });

  factory TransactionDetail.fromJson(Map<String, dynamic> json) {
    return TransactionDetail(
      transactionId: json['transactionId'] as String,
      userId: json['userId'] as String,
      category: Categories.fromJson(json['category'] as Map<String, dynamic>),
      amount: (json['amount'] as num).toDouble(),
      transactionDate: DateTime.parse(json['transactionDate'] as String),
      description: json['description'] as String? ?? '',
      senderBank: json['senderBank'] as String?,
      receiverName: json['receiverName'] as String?,
      imagePath: json['imagePath'] as String?,
      slipId: json['slipId'] as int?,
    );
  }
}
