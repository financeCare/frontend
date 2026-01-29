import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:flutter/foundation.dart';

class NotificationManager {
  // สร้าง Singleton instance
  static final NotificationManager _instance = NotificationManager._internal();
  factory NotificationManager() => _instance;
  NotificationManager._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  /// เริ่มต้นตั้งค่าระบบการแจ้งเตือน
  Future<void> initialize() async {
    // 1. ตั้งค่า Timezone สำหรับการตั้งเวลาแจ้งเตือน
    tz.initializeTimeZones();
    // ระบุชื่อโซนเวลาของไทย (Asia/Bangkok)
    // หมายเหตุ: ในเครื่องจริงจะใช้ tz.local แต่การระบุเจาะจงจะแม่นยำกว่าในบางกรณี

    // 2. ตั้งค่าสำหรับ Android
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    // 3. ตั้งค่าสำหรับ iOS
    const DarwinInitializationSettings initializationSettingsIOS =
    DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    // 4. เริ่มต้นระบบ Plugin
    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // จัดการเมื่อผู้ใช้กดที่การแจ้งเตือน
        debugPrint("Notification clicked: ${response.payload}");
      },
    );
  }

  /// ฟังก์ชันสำหรับส่งการแจ้งเตือนทันที (สำหรับทดสอบ)
  Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'finance_care_channel_id',
      'Finance Care Notifications',
      channelDescription: 'แจ้งเตือนเกี่ยวกับรายการเงินและหนี้สิน',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _notificationsPlugin.show(id, title, body, platformDetails, payload: payload);
  }

  /// ฟังก์ชันตั้งเวลาแจ้งเตือนล่วงหน้า 1 วัน ก่อนวันนัดชำระ (เช่น เวลา 10:30 น.)
  Future<void> setupDebtReminder(int id, String debtName, DateTime dueDate) async {
    // คำนวณวันที่ต้องแจ้งเตือน (ล่วงหน้า 1 วัน)
    final reminderDate = dueDate.subtract(const Duration(days: 1));

    // กำหนดเวลาที่ต้องการให้แจ้งเตือน (เช่น 10:30 น. ของวันนั้น)
    final scheduledTime = tz.TZDateTime(
      tz.local,
      reminderDate.year,
      reminderDate.month,
      reminderDate.day,
      10,
      30,
    );

    // ตรวจสอบว่าเวลาที่กำหนดเลยปัจจุบันไปหรือยัง (ถ้าเลยแล้วจะไม่ตั้ง)
    if (scheduledTime.isBefore(tz.TZDateTime.now(tz.local))) {
      debugPrint("Scheduled time for $debtName is in the past. Notification not set.");
      return;
    }

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'debt_reminders_id',
      'Debt Reminders',
      channelDescription: 'เตือนชำระหนี้สินและค่าใช้จ่าย',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _notificationsPlugin.zonedSchedule(
      id,
      'พรุ่งนี้มีนัดชำระ!',
      'อย่าลืมชำระ $debtName ตามกำหนดการในวันพรุ่งนี้',
      scheduledTime,
      platformDetails,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle, // สำหรับความแม่นยำสูง
      payload: 'debt_$id',
    );

    debugPrint("Notification set for $debtName at $scheduledTime");
  }

  /// ยกเลิกการแจ้งเตือนตาม ID
  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  /// ยกเลิกการแจ้งเตือนทั้งหมด
  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }
}