// import 'package:flutter/material.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// // 1. สร้าง Service สำหรับจัดการ Notification โดยเฉพาะ
// class NotificationService {
//   static final NotificationService _instance = NotificationService._internal();
//   factory NotificationService() => _instance;
//   NotificationService._internal();

//   final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

//   // ฟังก์ชันเริ่มต้น (ต้องเรียกใช้ใน main.dart หรือ initState)
//   Future<void> initNotification() async {
//     // 'app_icon' คือชื่อไฟล์ใน android/app/src/main/res/drawable/app_icon.png
//     // ถ้ายังไม่มีไอคอน ให้ใช้ '@mipmap/ic_launcher' (ไอคอนแอปมาตรฐาน) ไปก่อนได้ครับ
//     const AndroidInitializationSettings initializationSettingsAndroid =
//     AndroidInitializationSettings('@mipmap/ic_launcher');

//     const InitializationSettings initializationSettings = InitializationSettings(
//       android: initializationSettingsAndroid,
//     );

//     await _notificationsPlugin.initialize(
//       initializationSettings,
//       onDidReceiveNotificationResponse: (NotificationResponse response) {
//         // จัดการเมื่อผู้ใช้กดที่แถบแจ้งเตือน (เช่น เปิดไปหน้าเฉพาะ)
//         print("Notification clicked: ${response.payload}");
//       },
//     );

//     // ขอสิทธิ์สำหรับ Android 13+
//     await _notificationsPlugin
//         .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
//         ?.requestNotificationsPermission();
//   }

//   // ฟังก์ชันสำหรับสั่งให้แจ้งเตือนเด้งขึ้นมา
//   Future<void> showInstantNotification({
//     required int id,
//     required String title,
//     required String body,
//     String? payload,
//   }) async {
//     const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
//       'high_importance_channel', // ID ของ Channel
//       'Important Notifications', // ชื่อที่ผู้ใช้จะเห็นในตั้งค่าเครื่อง
//       importance: Importance.max,
//       priority: Priority.high,
//       showWhen: true,
//     );

//     const NotificationDetails platformDetails = NotificationDetails(
//       android: androidDetails,
//     );

//     await _notificationsPlugin.show(
//       id,
//       title,
//       body,
//       platformDetails,
//       payload: payload,
//     );
//   }
// }

// // 2. ตัวอย่างการนำไปใช้ในหน้า UI (NotificationScreen)
// // สมมติว่านี่คือหน้าจอที่คุณมีอยู่แล้ว
// class NotificationScreen extends StatefulWidget {
//   @override
//   _NotificationScreenState createState() => _NotificationScreenState();
// }

// class _NotificationScreenState extends State<NotificationScreen> {
//   final NotificationService _notificationService = NotificationService();

//   @override
//   void initState() {
//     super.initState();
//     // เรียกให้ Service เตรียมพร้อมทำงาน
//     _notificationService.initNotification();
//   }

// @override
// Widget build(BuildContext context) {
//   final args = ModalRoute.of(context)?.settings.arguments as Map?;
//   final refType = args?['refType'];
//   final refId = args?['refId'];

//   return Scaffold(
//     appBar: AppBar(title: const Text('Notifications')),
//     body: Text('refType=$refType refId=$refId'),
//   );
// }
// }