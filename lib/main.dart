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
import './auth/email_login_page.dart';
import './pages/homepage.dart';

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
    await LineSDK.instance.setup('2008279064');
    print('LINE SDK initialized successfully.');
  } catch (e) {
    print('LINE SDK initialization failed: $e');
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
      title: 'FINANCE CARE FC App',
      theme: ThemeData(
        primaryColor: const Color(0xFF00796B), // Deep Teal
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF00796B)),
        useMaterial3: true,
      ),
      // ใช้ 'home' แทน 'initialRoute' เพื่อให้สามารถกำหนดหน้าเริ่มต้นตามสถานะ Auth ได้
      home: initialScreen,

      // กำหนด Named Routes ทั้งหมดที่แอปฯ ใช้ (ยังคงมีประโยชน์สำหรับการนำทางภายหลัง)
      routes: {
        // '/': (context) => const WelcomePage(), // ไม่จำเป็นต้องใช้เป็น Route หลักแล้ว เพราะถูกใช้ใน 'home'
        '/email_login': (context) => const EmailLoginPage(),
        '/home': (context) => const HomePage(), // Home Page with Navbar

        // Route สำหรับการบันทึกค่าใช้จ่าย
        '/expense_entry': (context) => const ExpenseEntryScreen(),

        // Route สำหรับ Simulator Screen
        '/simulator': (context) => const SimulatorScreen(),
      },
    );
  }
}