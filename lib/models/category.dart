// lib/models/category.dart

class Category {
  final int id;
  final String name;
  final bool isExpense; // true: รายจ่าย, false: รายรับ

  // Constructor
  Category({
    required this.id,
    required this.name,
    required this.isExpense,
  });

  // 💡 Factory method สำหรับสร้าง Category Object จาก JSON (เมื่อโหลดจาก API)
  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as int,
      name: json['name'] as String,
      // API มักจะส่งค่าเป็น boolean หรืออาจจะส่งเป็น string (เช่น 'expense', 'income')
      // ถ้า API ส่ง boolean มาตรงๆ ก็ใช้โค้ดด้านล่างนี้
      isExpense: json['is_expense'] as bool,

      // *** หาก API ส่งเป็น String (เช่น 'type': 'expense') ให้ใช้โค้ดนี้แทน: ***
      // isExpense: json['type'] == 'expense',
    );
  }

  // Optional: เมธอดสำหรับแปลงกลับเป็น JSON หากต้องการส่งข้อมูลหมวดหมู่กลับไปที่ API
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'is_expense': isExpense,
    };
  }
}