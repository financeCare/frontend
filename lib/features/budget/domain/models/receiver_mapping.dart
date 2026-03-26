import 'category.dart';

class ReceiverMapping {
  final int id;
  final String userId;
  final String receiverName;
  final Categories category;
  final DateTime createdAt;

  ReceiverMapping({
    required this.id,
    required this.userId,
    required this.receiverName,
    required this.category,
    required this.createdAt,
  });

  factory ReceiverMapping.fromJson(Map<String, dynamic> json) {
    return ReceiverMapping(
      id: json['id'] as int,
      userId: json['userId'] as String,
      receiverName: json['receiverName'] as String,
      category: Categories.fromJson(json['category'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
