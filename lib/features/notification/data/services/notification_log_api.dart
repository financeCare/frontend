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

    String path = '/api/notifications/logs';
    if (refType == 'BUDGET') {
      path = '/api/notifications/logs/filter-refType/BUDGET';
    } else if (refType == 'DEBT') {
      path = '/api/notifications/logs/filter-refType/DEBT';
    }

    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);

    final res = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('getLogs failed: ${res.statusCode} ${res.body}');
    }

    final decoded = jsonDecode(res.body);

    // รองรับทั้ง response แบบ Page และแบบ List ตรง ๆ
    final List list = decoded is List
        ? decoded
        : (decoded['content'] as List? ?? []);

    return list.map((e) => NotificationLogItem.fromJson(e)).toList();
  }

  Future<bool> markAsClicked({
    required String accessToken,
    required String logId,
  }) async {
    final uri = Uri.parse('$baseUrl/api/notifications/logs/$logId/clicked');
    final res = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $accessToken'},
    );
    return res.statusCode == 200;
  }

  Future<bool> markAllAsRead({required String accessToken}) async {
    final uri = Uri.parse('$baseUrl/api/notifications/logs/read-all');
    final res = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $accessToken'},
    );
    return res.statusCode == 200;
  }
}
