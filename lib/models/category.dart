class Categories {
  final int categoryId;        // ใช้ categoryId สำหรับ transaction
  final String userId;         // UUID เป็น String
  final String categoryName;
  final String type;
  final String? budgetId;      // <-- เปลี่ยนเป็น nullable

  Categories({
    required this.categoryId,
    required this.userId,
    required this.categoryName,
    required this.type,
    this.budgetId,              // <-- ไม่ต้อง required
  });

  factory Categories.fromJson(Map<String, dynamic> json) {
    return Categories(
      categoryId: json['categoryId'],
      userId: json['userId'],
      categoryName: json['categoryName'],
      type: json['type'],
      budgetId: json['budgetId'] ?? '', // <-- ถ้าไม่มี ให้เป็น empty string
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'categoryId': categoryId,
      'userId': userId,
      'categoryName': categoryName,
      'type': type,
      'budgetId': budgetId,
    };
  }
}