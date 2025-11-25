import 'package:flutter/material.dart';
import 'package:flutter_line_sdk/flutter_line_sdk.dart';

// Screens
// **NOTE:** ต้องมั่นใจว่าไฟล์เหล่านี้มีอยู่ในโครงสร้าง lib/ ของคุณ
import 'pages/welcome_page.dart';
import 'email_login_page.dart';
import 'pages/homepage.dart'; // HomePage ที่มี Bottom Navigation Bar (สำคัญ: ต้องเป็นไฟล์ home_page.dart ที่มี FAB)
import 'expense_entry_screen.dart'; // Expense Entry (Route /expense_entry)
import 'pages/simulator_screen.dart'; // Simulator (Route /simulator)

// Widget Helper: LogoHeader - **ใช้ Image.asset สำหรับโลโก้**
class LogoHeader extends StatelessWidget {
  const LogoHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ใช้ Image.asset เพื่อแสดงโลโก้เดิม
        Image.asset(
          'assets/logo_finance_care.png',
          height: 120, // ปรับขนาด
          width: 120,
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize LINE SDK (ใช้ dummy ID สำหรับการทดสอบ)
  try {
    LineSDK.instance.setup('dummy_line_channel_id');
  } catch (e) {
    // print('LINE SDK initialization failed: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FINANCE CARE FC App',
      // **แก้ไข: เปลี่ยนสี Primary Color และ Seed Color เป็น Teal (สีเขียวอมน้ำเงิน) เพื่อให้เข้ากับโลโก้**
      theme: ThemeData(
        primaryColor: const Color(0xFF00796B), // Deep Teal
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF00796B)),
        useMaterial3: true,
      ),
      initialRoute: '/',

      // กำหนด Named Routes ทั้งหมดที่แอปฯ ใช้
      routes: {
        '/': (context) => const WelcomePage(),
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