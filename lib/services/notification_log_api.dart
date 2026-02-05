import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/notification_log_item.dart';

class NotificationLogApi {
  final String baseUrl;

  NotificationLogApi({required this.baseUrl});

  Future<List<NotificationLogItem>> getLogs({
    required String accessToken,
    int page = 0,
    int size = 20,
    String? refType,
    String? refId,
  }) async {
    final query = <String, String>{
      'page': page.toString(),
      'size': size.toString(),
    };

    if (refType != null && refType.isNotEmpty) {
      query['refType'] = refType;
    }
    if (refId != null && refId.isNotEmpty) {
      query['refId'] = refId;
    }

    final uri = Uri.parse('$baseUrl/api/notifications/logs')
        .replace(queryParameters: query);

    final res = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(
        'getLogs failed: ${res.statusCode} ${res.body}',
      );
    }

    final decoded = jsonDecode(res.body);

    // รองรับทั้ง response แบบ Page และแบบ List ตรง ๆ
    final List list =
        decoded is List ? decoded : (decoded['content'] as List? ?? []);

    return list
        .map((e) => NotificationLogItem.fromJson(e))
        .toList();
  }
}
