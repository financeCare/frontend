import 'package:flutter/material.dart';
import 'package:flutter_line_sdk/flutter_line_sdk.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

// Screens
// **NOTE:** ต้องมั่นใจว่าไฟล์เหล่านี้มีอยู่ในโครงสร้าง lib/ ของimport 'auth/auth_widget.darimport 'auth/auth_widget.dart';
import './auth/auth_widget.dart';
import './pages/homepage.dart'; // HomePage ที่มี Bottom Navigation Bar (สำคัญ: ต้องเป็นไฟล์ home_page.dart ที่มี FAB)
import 'expense_entry_screen.dart'; // Expense Entry (Route /expense_entry)
import './pages/simulator/simulator_screen.dart'; // Simulator (Route /simulator)

// Widget Helper: LogoHeader - **ปรับขนาดโลโก้**
class LogoHeader extends StatelessWidget {
  const LogoHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ใช้ Image.asset เพื่อแสดงโลโก้เดิม
        Image.asset(
          'assets/logo_finance_care.png',
          height: 280, // **เพิ่มขนาดให้ใหญ่ขึ้น**
          width: 380,  // **เพิ่มขนาดให้ใหญ่ขึ้น**
        ),
      ],
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await LineSDK.instance.setup('2008279064');
    print('start app');
  } catch (e) {
    print('LINE SDK initialization failed: $e');
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FINANCE CARE FC App',
      theme: ThemeData(
        primaryColor: const Color(0xFF00796B), // Deep Teal
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF00796B)),
        useMaterial3: true,
      ),
      initialRoute: '/',

      // กำหนด Named Routes ทั้งหมดที่แอปฯ ใช้
      routes: {
        '/': (context) => const WelcomePage(), // ถ้าอยาก test ตอนbe พัง เปลี่ยนเป็น /home
        '/email_login': (context) => const EmailLoginPage(),
        '/home': (context) => const HomePage(), // Home Page with Navbar

        // Route สำหรับการบันทึกค่าใช้จ่าย (ถูกเรียกจาก BudgetPerMonthScreen)
        '/expense_entry': (context) => const ExpenseEntryScreen(),

        // Route สำหรับ Simulator Screen (ถูกเรียกจากปุ่ม FAB)
        '/simulator': (context) => const SimulatorScreen(),
      },
    );
  }
}

void requestNotificationPermission() async {
  if (Platform.isAndroid && await Permission.notification.isDenied) {
    await Permission.notification.request();
  }
}
