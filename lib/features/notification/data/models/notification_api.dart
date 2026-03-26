import 'dart:convert';
import 'package:http/http.dart' as http;

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
    final url = Uri.parse('$baseUrl/api/notifications/devices/');

    print('!!! Noti API: URL => $url');
    final res = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode({
        'deviceKey': deviceKey, // ✅ แนะนำให้ backend รับด้วย
        'fcmToken': fcmToken,
        'platform': platform,
        'deviceName': deviceName,
      }),
    );

    print('!!! Noti API: Status => ${res.statusCode}');
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('Register device failed: ${res.statusCode}');
    }
  }
}
