import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:finance_care/core/utils/app_logger.dart';

class NotificationApi {
  final String baseUrl;

  NotificationApi({required this.baseUrl});

  Future<void> upsertDevice({
    required String accessToken,
    required String deviceKey,
    required String fcmToken,
    required String platform,
    required String deviceName,
  }) async {
    final url = Uri.parse('$baseUrl/api/notifications/devices/register');

    final res = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode({
        'deviceKey': deviceKey,
        'fcmToken': fcmToken,
        'platform': platform,
        'deviceName': deviceName,
      }),
    );

    AppLog.d('upsertDevice: ${res.statusCode}');
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('Register device failed: ${res.statusCode}');
    }
  }
}
