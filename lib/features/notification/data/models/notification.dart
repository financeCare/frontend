class NotificationDTO {
  final String notificationId;        // ใช้ categoryId สำหรับ transaction
  final String userId;         // UUID เป็น String
  final String type;
  final String message;
  final bool isRead;
  final DateTime? createdAt;      // <-- เปลี่ยนเป็น nullable

  NotificationDTO({
    required this.notificationId,
    required this.userId,
    required this.type,
    required this.message,
    required this.isRead,
    this.createdAt,              // <-- ไม่ต้อง required
  });

  factory NotificationDTO.fromJson(Map<String, dynamic> json) {
    return NotificationDTO(
      notificationId: json['notificationId'],
      userId: json['userId'],
      type: json['type'],
      message: json['message'],
      isRead: json['isRead'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null, // <-- ถ้าไม่มี ให้เป็น null
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'notificationId': notificationId,
      'userId': userId,
      'type': type,
      'message': message,
      'isRead': isRead,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}