import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_application_1/features/auth/data/services/device_service.dart';
import '../../../../core/config/config.dart' as Config;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../../../../features/auth/data/services/access_token_service.dart';

class PushService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterSecureStorage _storage = AccesstokenService.sharedStorage;

  // เปลี่ยนเป็นของคุณ
  final String baseUrl = "${Config.baseUrl}";

  Future<void> init() async {
    // 1) ขอ permission (สำคัญมาก โดยเฉพาะ iOS และ Android 13+)
    await _requestPermission();

    // 2) ตั้งค่าการแสดง notification ตอน foreground (iOS)
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // 3) Get token ครั้งแรก
    final token = await _messaging.getToken();
    if (token != null) {
      await _registerDevice(token);
    }

    // 4) ฟัง token refresh (ต้องทำ ไม่งั้นวันหนึ่งจะส่งไม่ถึง)
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      await _registerDevice(newToken);
    });

    // 5) (Optional) รับ event ตอนผู้ใช้กด notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // TODO: navigate ไปหน้าที่ต้องการ
    });

    // 6) (Optional) ตอนแอปเปิดอยู่ (foreground) จะได้รับ message ที่นี่
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // ถ้าส่งเป็น "notification" แบบปกติ
      // Android มักแสดงเองใน background, แต่ foreground อาจต้องทำ UI เอง
      // หรือพึ่ง setForegroundNotificationPresentationOptions บน iOS
    });
  }

  Future<void> _requestPermission() async {
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      // ผู้ใช้ปิด permission -> ส่งไม่เด้ง
      // คุณอาจแจ้ง UI ให้ผู้ใช้ไปเปิด settings
    }
  }

  Future<void> _registerDevice(String fcmToken) async {
    final deviceKey = await DeviceService.getOrCreateDeviceId();
    final info = await DeviceService.getDeviceInfo();

    // ถ้าคุณใช้ JWT ให้แนบ token ด้วย
    final accessToken = await _storage.read(key: "accessToken");

    final body = jsonEncode({
      "deviceKey": deviceKey,
      "fcmToken": fcmToken,
      "platform": info["platform"],
      "deviceName": info["deviceName"],
    });

    final res = await http.post(
      Uri.parse("$baseUrl/api/notifications/devices/register"),
      headers: {
        "Content-Type": "application/json",
        if (accessToken != null) "Authorization": "Bearer $accessToken",
      },
      body: body,
    );

    if (res.statusCode != 200) {
      // log ไว้ debug
      // ignore: avoid_print
      print("Register device failed: ${res.statusCode} ${res.body}");
    }
  }
}
