import 'package:flutter/material.dart';
import 'package:flutter_line_sdk/flutter_line_sdk.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// 🚨 (1) เพิ่มการ Import ไฟล์ที่สร้างโดย FlutterFire CLI
import 'firebase_options.dart';

// <<<< เพิ่มการ Import AuthManager ที่นี่ >>>>
import './auth/auth_manager.dart';

// Screens
import './auth/welcome_page.dart';
import 'pages/expense_entry_screen.dart';
import './pages/simulator/simulator_screen.dart';
import 'pages/email_login_page.dart';
import './pages/homepage.dart';
import 'notification/notification_screen.dart';


// 🚨 ฟังก์ชัน main() ต้องเป็น async และรวมการเริ่มต้น (Initialization) ของทั้งสองบริการ
void main() async {
  // 🚨 1. ตรวจสอบให้แน่ใจว่า Flutter Engine ถูกเชื่อมต่อก่อนเรียกใช้ Native Code
  WidgetsFlutterBinding.ensureInitialized();

  // <<<< [สำคัญ] โหลด Token ที่บันทึกไว้ก่อนเริ่มแอป >>>>
  await AuthManager.init();

  // 🚨 2. เริ่มต้น Firebase App โดยส่ง DefaultFirebaseOptions เข้าไปโดยตรง
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully with options.');
  } catch (e) {
    print('Firebase initialization failed: $e');
  }

  // 3. เริ่มต้น LINE SDK
  try {
    // แทนที่ด้วย Channel ID ของคุณ
    await LineSDK.instance.setup('2008279064');
    debugPrint('LINE SDK initialized successfully');
  } catch (e) {
    debugPrint('LINE SDK initialization failed: $e');
  }

  // 4. เริ่มต้นแอป Flutter
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {

    // <<<< [สำคัญ] ตรวจสอบ Token และกำหนดหน้าจอแรกทันที >>>>
    // ถ้ามี Token อยู่แล้ว ให้ไปยัง HomePage (หน้าหลัก)
    // ถ้าไม่มี Token ให้ไปยัง WelcomePage (หน้าต้อนรับ/ล็อกอิน)
    final initialScreen = AuthManager.token != null
        ? const HomePage()
        : const WelcomePage();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FINANCE CARE FC App',
      theme: ThemeData(
        primaryColor: const Color(0xFF00796B), // Deep Teal
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00796B),
          primary: const Color(0xFF00796B),
        ),
        useMaterial3: true,
        // กำหนด Font หลักของแอปถ้ามี
        // fontFamily: 'Kanit',
      ),

      // เส้นทางเริ่มต้นเมื่อเปิดแอป
      initialRoute: '/',

      // การจัดการเส้นทาง (Routes) ทั้งหมดภายในแอป
      routes: {
        // หน้าต้อนรับ / เลือกวิธี Login
        '/': (context) => const WelcomePage(),

        // หน้าล็อคอินด้วยอีเมล
        '/email_login': (context) => const EmailLoginPage(),

        // หน้าหลัก (ที่มี Bottom Navigation Bar)
        '/home': (context) => const HomePage(),

        // หน้าบันทึกค่าใช้จ่าย
        '/expense_entry': (context) => const ExpenseEntryScreen(),

        // หน้าเครื่องมือคำนวณ (Simulator)
        '/simulator': (context) => const SimulatorScreen(),

        // --- เพิ่ม Route สำหรับการแจ้งเตือน ---
        '/notify': (context) => const NotificationScreen(),
      },
    );
  }
}

// Widget Helper สำหรับแสดงโลโก้
class LogoHeader extends StatelessWidget {
  const LogoHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/logo_finance_care.png',
          height: 280, // ปรับขนาดตามที่คุณต้องการ
          width: 380,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(Icons.account_balance_wallet, size: 100, color: Color(0xFF00796B));
          },
        ),
      ],
    );
  }
}