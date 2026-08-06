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
      transactionId: (json['transactionId'] ?? json['id'] ?? '').toString(),
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      transactionDate: _normalizeDate(json['transactionDate'] != null 
          ? DateTime.parse(json['transactionDate'])
          : (json['transferDate'] != null 
              ? DateTime.parse(json['transferDate']) 
              : DateTime.now())),
      description: json['description'] as String? ?? '',
      category: Categories.fromJson(
        (json['categoryDTO'] ?? json['category']) as Map<String, dynamic>? ?? {},
      ),
      senderBank: json['senderBank'] as String?,
      receiverName: json['receiverName'] as String?,
      imagePath: json['imagePath'] as String?,
      slipId: json['slipId'] is int 
          ? json['slipId'] as int 
          : (json['id'] is int 
              ? json['id'] as int 
              : (json['slipId'] != null 
                  ? int.tryParse(json['slipId'].toString()) 
                  : (json['id'] != null ? int.tryParse(json['id'].toString()) : null))),
    );
  }

  static DateTime _normalizeDate(DateTime date) {
    if (date.year > 2500) {
      return DateTime(
        date.year - 543,
        date.month,
        date.day,
        date.hour,
        date.minute,
        date.second,
      );
    }
    return date;
  }
}