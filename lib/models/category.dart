class Categories {
  final int categoryId;        // ใช้ categoryId สำหรับ transaction
  final String userId;         // UUID เป็น String
  final String categoryName;
  final String type;
  final String budgetId;       // UUID, ไม่ต้องแปลง

  Categories({
    required this.categoryId,
    required this.userId,
    required this.categoryName,
    required this.type,
    required this.budgetId,
  });

  factory Categories.fromJson(Map<String, dynamic> json) {
    return Categories(
      categoryId: json['categoryId'],
      userId: json['userId'],
      categoryName: json['categoryName'],
      type: json['type'],
      budgetId: json['budgetId'],
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
