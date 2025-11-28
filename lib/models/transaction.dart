// lib/models/transaction.dart

class TransactionModel {
  final int id;
  final String type; // 'expense' หรือ 'income'
  final double amount;
  final String category;
  final String note;
  final DateTime date;

  TransactionModel({
    required this.id,
    required this.type,
    required this.amount,
    required this.category,
    required this.note,
    required this.date,
  });

  // 💡 เมธอดนี้สำคัญมากสำหรับ expense_entry_screen.dart
  // เพราะจะใช้แปลง Object เป็น Map ก่อนส่งให้ API Service
  Map<String, dynamic> toJson() {
    return {
      // id ไม่ต้องส่งไปถ้าเป็นการสร้างรายการใหม่ แต่มีไว้เพื่อความสมบูรณ์
      // 'id': id,
      'type': type,
      'amount': amount,
      'category': category,
      'note': note,
      'date': date.toIso8601String().substring(0, 10), // ส่งแค่ YYYY-MM-DD
    };
  }
}