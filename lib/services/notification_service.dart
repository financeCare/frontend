import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:uuid/uuid.dart';

import 'notification_api.dart';

typedef OnNotificationTap = void Function({
  required String? refType,
  required String? refId,
});

class NotificationService {
  NotificationService({
    required this.api,
    required this.storage,
  });

  final NotificationApi api;
  final FlutterSecureStorage storage;

  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  static const _deviceKeyStorageKey = 'device_key_v1';

  Future<void> init({
    required OnNotificationTap onTap,
  }) async {
    await FirebaseMessaging.instance.requestPermission();

    await _initLocal(onTap: onTap);
    _initFcmHandlers(onTap: onTap);
  }

  Future<void> registerTokenToBackend({
    required String accessToken,
  }) async {
    final fcmToken = await FirebaseMessaging.instance.getToken();
    if (fcmToken == null || fcmToken.isEmpty) return;

    final deviceKey = await _getOrCreateDeviceKey();
    final deviceName = await _getDeviceName();
    final platform = _platform();

    await api.upsertDevice(
      accessToken: accessToken,
      deviceKey: deviceKey,
      fcmToken: fcmToken,
      platform: platform,
      deviceName: deviceName,
    );

    // token เปลี่ยน -> ส่งขึ้น backend อีกครั้ง
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      if (newToken.isEmpty) return;
      try {
        await api.upsertDevice(
          accessToken: accessToken,
          deviceKey: deviceKey,
          fcmToken: newToken,
          platform: platform,
          deviceName: deviceName,
        );
      } catch (_) {
        // production แนะนำให้ทำ retry queue
      }
    });
  }

  // ---------- private ----------

  Future<void> _initLocal({required OnNotificationTap onTap}) async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();

    const init = InitializationSettings(android: androidInit, iOS: iosInit);

    await _local.initialize(
      init,
      onDidReceiveNotificationResponse: (resp) {
        final payload = resp.payload ?? '';
        final parts = payload.split('|');
        final refType = parts.isNotEmpty && parts[0].isNotEmpty ? parts[0] : null;
        final refId = parts.length > 1 && parts[1].isNotEmpty ? parts[1] : null;
        onTap(refType: refType, refId: refId);
      },
    );
  }

  void _initFcmHandlers({required OnNotificationTap onTap}) {
    // Foreground -> show local notification ให้เห็น banner
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final title = message.notification?.title ?? 'Notification';
      final body = message.notification?.body ?? '';
      final refType = message.data['refType']?.toString();
      final refId = message.data['refId']?.toString();

      await _showLocal(
        title: title,
        body: body,
        refType: refType,
        refId: refId,
      );
    });

    // background -> tap notification
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      final refType = message.data['refType']?.toString();
      final refId = message.data['refId']?.toString();
      onTap(refType: refType, refId: refId);
    });

    // terminated -> tap notification แล้วเปิดแอป
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message == null) return;
      final refType = message.data['refType']?.toString();
      final refId = message.data['refId']?.toString();
      onTap(refType: refType, refId: refId);
    });
  }

  Future<void> _showLocal({
    required String title,
    required String body,
    required String? refType,
    required String? refId,
  }) async {
    const android = AndroidNotificationDetails(
      'default_channel',
      'General',
      importance: Importance.max,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: android);

    final payload = '${refType ?? ''}|${refId ?? ''}';
    final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    await _local.show(id, title, body, details, payload: payload);
  }

  Future<String> _getOrCreateDeviceKey() async {
    final existing = await storage.read(key: _deviceKeyStorageKey);
    if (existing != null && existing.isNotEmpty) return existing;

    final key = const Uuid().v4();
    await storage.write(key: _deviceKeyStorageKey, value: key);
    return key;
  }

  String _platform() {
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return 'web';
  }

  Future<String> _getDeviceName() async {
    final info = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final a = await info.androidInfo;
      return '${a.brand} ${a.model}';
    }
    if (Platform.isIOS) {
      final i = await info.iosInfo;
      return i.utsname.machine ?? 'iPhone';
    }
    return 'web';
  }
}
