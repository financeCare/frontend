
import 'package:uuid/uuid.dart';

class NotificationLogItem {
  final String logId;
  final String ruleId;
  final String title;
  final String body;
  final String status;
  final DateTime sentAt;
  final String? refType;
  final String? refId;

  NotificationLogItem({
    required this.logId,
    required this.ruleId,
    required this.title,
    required this.body,
    required this.status,
    required this.sentAt,
    this.refType,
    this.refId,
  });

  factory NotificationLogItem.fromJson(Map<String, dynamic> json) {
    return NotificationLogItem(
      logId: json['logId'].toString(),
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      sentAt: DateTime.parse(json['sentAt'].toString()),
      refType: json['refType']?.toString(),
      refId: json['refId']?.toString(),
      ruleId: json['ruleId'].toString(),
    );
  }
}
