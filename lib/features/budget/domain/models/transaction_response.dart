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

  final bool autoCreated;

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
    this.autoCreated = false,
  });

  factory TransactionResponse.fromJson(Map<String, dynamic> json) {
    // Handle nested 'slip' key if returned from backend Map<String, Object>
    final Map<String, dynamic> data = json.containsKey('slip') 
        ? json['slip'] as Map<String, dynamic> 
        : json;
    
    final bool auto = json['autoCreated'] as bool? ?? data['autoCreated'] as bool? ?? false;

    return TransactionResponse(
      transactionId: (data['transactionId'] ?? data['id'] ?? '').toString(),
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      transactionDate: _normalizeDate(data['transactionDate'] != null 
          ? DateTime.parse(data['transactionDate'])
          : (data['transferDate'] != null 
              ? DateTime.parse(data['transferDate']) 
              : DateTime.now())),
      description: data['description'] as String? ?? '',
      category: Categories.fromJson(
        (data['categoryDTO'] ?? data['category']) as Map<String, dynamic>? ?? {},
      ),
      senderBank: data['senderBank'] as String?,
      receiverName: data['receiverName'] as String?,
      imagePath: data['imagePath'] as String?,
      slipId: data['slipId'] as int?,
      autoCreated: auto,
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