import 'package:flutter/material.dart';
import 'package:flutter_line_sdk/flutter_line_sdk.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/finance_item.dart'; // 🚨 ต้อง Import FinanceItem ด้วย

// Import หน้าจออื่นๆ ที่ใช้ใน Bottom Navigation Bar
import 'crud_page.dart';
import 'budget_per_month_screen.dart';
import 'dashboard_page.dart'; // 🚨 เพิ่ม DashboardPage เข้ามาใน Widget Options

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
// 4. HOMEPAGE: หน้าจอหลักพร้อม Bottom Navigation Bar (Stateful)
// =========================================================

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);

  // 🌟 State สำหรับเก็บข้อมูลการเงินที่มาจาก CrudPage
  List<FinanceItem> _allIncomes = [];
  List<FinanceItem> _allDebts = [];

  // 🌟 ต้องประกาศ _widgetOptions เป็น List ที่สร้าง Dynamic ได้
  late List<Widget> _widgetOptions;

  // 🌟 ฟังก์ชันสำหรับอัปเดต List ของ Widgets
  void _updateWidgetOptions() {
    _widgetOptions = <Widget>[
      // Index 0: Dashboard (Home) - แสดงผลจาก Incomes/Debts ที่เก็บไว้
      DashboardPage(incomes: _allIncomes, debts: _allDebts),
      const PlaceholderScreen(title: 'Notifications (แจ้งเตือน)'),
      // Index 2: Budget - ส่งข้อมูล Incomes/Debts ไปให้
      BudgetPerMonthScreen(incomes: _allIncomes, debts: _allDebts),
      const PlaceholderScreen(title: 'Settings (ตั้งค่า)'),
    ];
  }

  @override
  void initState() {
    super.initState();
    _updateWidgetOptions(); // ตั้งค่าเริ่มต้น
  }

  // 🌟 จัดการการนำทางไปยัง CrudPage และรับผลลัพธ์กลับมา
  void _openCrudPage() async {
    // นำทางไปยัง CrudPage (FAB)
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CrudPage()),
    );

    // 🌟 รับผลลัพธ์กลับมา (เป็น Map {'incomes': ..., 'debts': ...})
    if (result != null && result is Map<String, dynamic>) {
      if (mounted) {
        setState(() {
          _allIncomes = result['incomes'] as List<FinanceItem>;
          _allDebts = result['debts'] as List<FinanceItem>;
          _updateWidgetOptions(); // อัปเดต List ของ Widgets ให้ใช้ข้อมูลใหม่
          _selectedIndex = 2; // ย้ายไปที่ Budget Page (Index 2 ใน List) ทันที
        });
      }
    }
  }


  void _onItemTapped(int index) {
    if (index == 2) {
      _openCrudPage(); // กด FAB เปิด CrudPage
      return;
    }

    // Mapping Index: 0 -> 0, 1 -> 1, 3 -> 2 (Budget), 4 -> 3 (Setting)
    int newSelectedIndex = index;
    if (index > 2) {
      newSelectedIndex = index - 1;
    }

    setState(() {
      _selectedIndex = newSelectedIndex;
    });
  }

  // ฟังก์ชันหาชื่อ Title ที่เหมาะสมสำหรับ AppBar
  String _getAppBarTitle(int index) {
    switch(index) {
      case 0:
        return 'Dashboard (หน้าหลัก)';
      case 1:
        return 'แจ้งเตือน';
      case 2:
        return 'งบประมาณต่อเดือน';
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
              try {
                await LineSDK.instance.logout();
                await _googleSignIn.signOut();
              } catch (e) {
                print("Logout failed: $e");
              }
              Navigator.of(context).pushReplacementNamed('/');
            },
          ),
        ],
      ),

      // เนื้อหาของหน้าจอปัจจุบัน
      body: Center(child: _widgetOptions.elementAt(_selectedIndex)),

      floatingActionButton: FloatingActionButton(
        onPressed: _openCrudPage, // 🌟 ใช้ _openCrudPage แทน
        backgroundColor: Colors.redAccent.shade700,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        elevation: 4.0,
        child: const Icon(Icons.calculate_outlined, size: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 6.0,
        color: Theme.of(context).primaryColor,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            _buildNavItem(0, Icons.home, 'Home'),
            _buildNavItem(1, Icons.notifications, 'Notify'),
            const Expanded(child: SizedBox(height: 1)),
            _buildNavItem(3, Icons.account_balance_wallet, 'Budget'),
            _buildNavItem(4, Icons.settings, 'Setting'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final int targetIndex = index == 0 ? 0 : (index == 1 ? 1 : (index == 3 ? 2 : 3));
    final isSelected = _selectedIndex == targetIndex;
    final color = isSelected ? Colors.white : Colors.white70;

    return Expanded(
      child: TextButton(
        onPressed: () => _onItemTapped(index),
        style: TextButton.styleFrom(
          foregroundColor: color,
          minimumSize: const Size(48, 48),
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