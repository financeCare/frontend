// lib/models/transaction.dart

class TransactionModel {
  final String? id; // เปลี่ยนเป็น String เพื่อรองรับ UUID
  final String type; // 'expense' หรือ 'income'
  final double amount;
  final String category;
  final String note;
  final DateTime date;
  final String? senderBank;
  final String? receiverName;
  final String? imagePath;
  final int? slipId;

  TransactionModel({
    this.id,
    required this.type,
    required this.amount,
    required this.category,
    required this.note,
    required this.date,
    this.senderBank,
    this.receiverName,
    this.imagePath,
    this.slipId,
  });

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'transactionId': id,
      'type': type,
      'amount': amount,
      'description': note,
      'transactionDate': date.toIso8601String(),
      if (senderBank != null) 'senderBank': senderBank,
      if (receiverName != null) 'receiverName': receiverName,
      if (imagePath != null) 'imagePath': imagePath,
      if (slipId != null) 'slipId': slipId,
    };
  }
}