import 'package:flutter/material.dart';
import 'package:flutter_line_sdk/flutter_line_sdk.dart';
import 'package:google_sign_in/google_sign_in.dart';

// Import หน้าจออื่นๆ ที่ใช้ใน Bottom Navigation Bar
// NOTE: ต้องมั่นใจว่าไฟล์เหล่านี้มีอยู่จริงในโครงสร้างโปรเจกต์ของคุณ
import 'crud_page.dart'; // สมมติว่าเป็นหน้า Dashboard/Home
import 'budget_per_month_screen.dart'; // สมมติว่าเป็นหน้า Budget
import 'dashboard_page.dart';


// =========================================================
// 3. WIDGETS สำหรับหน้าจอ Placeholder (Notification/Setting)
// =========================================================

class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({required this.title, super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(title, style: Theme.of(context).textTheme.headlineMedium!.copyWith(color: Colors.grey)),
    );
  }
}

// =========================================================
// 4. HOMEPAGE: หน้าจอหลักพร้อม Bottom Navigation Bar
// =========================================================

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0; // Index ที่เลือกปัจจุบัน (เริ่มต้นที่ Home/Dashboard)
  // ประกาศ GoogleSignIn ไว้สำหรับ Logout
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);


  // รายชื่อหน้าจอทั้งหมดใน Navbar (4 รายการ, Index 2 ถูกข้าม)
  late final List<Widget> _widgetOptions;

  // ตั้งค่า List of Widgets ใน initState
  @override
  void initState() {
    super.initState();
    _widgetOptions = <Widget>[
      // ตรวจสอบว่า CrudPage และ BudgetPerMonthScreen มีอยู่จริง
      const CrudPage(), // Index 0: Home (Dashboard)
      const PlaceholderScreen(title: 'Notifications (แจ้งเตือน)'), // Index 1: Notification
      // Index 2 ถูกข้ามไปใน List แต่มีใน BottomNavigationBar (ตำแหน่ง FAB)
      const BudgetPerMonthScreen(), // Index 2 (แทน Index 3 เดิม): Budget
      const PlaceholderScreen(title: 'Settings (ตั้งค่า)'), // Index 3 (แทน Index 4 เดิม): Setting
    ];
  }

  // ปรับการ Mapping Index ของ BottomNavigationBar (0, 1, 2, 3, 4) ไปยัง List _widgetOptions (0, 1, 2, 3)
  void _onItemTapped(int index) {
    // Index 2 คือตำแหน่งของ FAB ไม่มีการเปลี่ยนหน้าจอหลัก
    if (index == 2) {
      return;
    }

    // Mapping Index:
    // 0 -> 0 (Home)
    // 1 -> 1 (Notification)
    // 3 -> 2 (Budget) <--- Budget Page ยังคงอยู่
    // 4 -> 3 (Setting)
    int newSelectedIndex = index;
    if (index > 2) {
      newSelectedIndex = index - 1; // ข้าม Index 2 (ตำแหน่ง FAB)
    }

    setState(() {
      _selectedIndex = newSelectedIndex;
    });
  }

  // ฟังก์ชันหาชื่อ Title ที่เหมาะสมสำหรับ AppBar
  String _getAppBarTitle(int index) {
    // ใช้ _selectedIndex (0, 1, 2, 3)
    switch(index) {
      case 0:
        return '';
      case 1:
        return 'แจ้งเตือน';
      case 2:
        return 'งบประมาณต่อเดือน'; // <--- Budget Page Title
      case 3:
        return 'ตั้งค่า';
      default:
        return 'Finance Care';
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getAppBarTitle(_selectedIndex), style: Theme.of(context).textTheme.titleLarge!.copyWith(color: Colors.white)),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              // ออกจากระบบ LINE SDK ด้วย
              try {
                await LineSDK.instance.logout();
                // ออกจากระบบ Google ด้วย
                await _googleSignIn.signOut();
              } catch (e) {
                print("Logout failed: $e");
              }
              // กลับไปหน้า Welcome (Named Route '/')
              Navigator.of(context).pushReplacementNamed('/');
            },
          ),
        ],
      ),

      // เนื้อหาของหน้าจอปัจจุบัน
      body: Center(child: _widgetOptions.elementAt(_selectedIndex)),

      // ----------------------------------------------------
      // Floating Action Button (ปุ่ม Calculate ที่โดดเด่น)
      // เปลี่ยนการทำงานเป็นการนำทางไปหน้า Simulator ตรงๆ
      // ----------------------------------------------------
      floatingActionButton: FloatingActionButton(
        // **FAB นำทางไปยัง /simulator โดยตรง**
        onPressed: () => Navigator.of(context).pushNamed('/simulator'),
        // ทำให้ปุ่มเด่นด้วยสีที่แตกต่าง
        backgroundColor: Colors.redAccent.shade700,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        elevation: 4.0,
        child: const Icon(Icons.calculate_outlined, size: 30),
      ),
      // กำหนดตำแหน่งปุ่มให้อยู่ตรงกลางของ Bottom Navigation Bar
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // ----------------------------------------------------
      // Bottom Navigation Bar
      // ----------------------------------------------------
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(), // ทำให้มีรอยเว้าสำหรับปุ่มกลาง
        notchMargin: 6.0,
        color: Theme.of(context).primaryColor,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            // 1. Home (Index 0)
            _buildNavItem(0, Icons.home, 'Home'),
            // 2. Notification (Index 1)
            _buildNavItem(1, Icons.notifications, 'Notify'),
            // ช่องว่างสำหรับปุ่มกลาง (Calculate, Index 2)
            const Expanded(child: SizedBox(height: 1)),
            // 4. Budget (Index 3) <--- ปุ่มนี้ยังอยู่และทำงานปกติ
            _buildNavItem(3, Icons.account_balance_wallet, 'Budget'),
            // 5. Setting (Index 4)
            _buildNavItem(4, Icons.settings, 'Setting'),
          ],
        ),
      ),
    );
  }

  // Widget สำหรับสร้างรายการใน Bottom Navigation Bar
  Widget _buildNavItem(int index, IconData icon, String label) {
    // Mapping Index (0, 1, 3, 4) ไปยัง _selectedIndex (0, 1, 2, 3)
    final int targetIndex = index == 0 ? 0 : (index == 1 ? 1 : (index == 3 ? 2 : 3));
    final isSelected = _selectedIndex == targetIndex;
    final color = isSelected ? Colors.white : Colors.white70;

    return Expanded(
      child: TextButton(
        onPressed: () => _onItemTapped(index),
        style: TextButton.styleFrom(
          foregroundColor: color, // ใช้สีตามสถานะที่เลือก
          minimumSize: const Size(48, 48), // กำหนดขนาดขั้นต่ำ
          padding: const EdgeInsets.symmetric(vertical: 7.0),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24),
            Text(label, style: const TextStyle(fontSize: 12.0)),
          ],
        ),
      ),
    );
  }
}