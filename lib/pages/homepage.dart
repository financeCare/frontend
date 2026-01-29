import 'package:flutter/material.dart';
import 'package:flutter_line_sdk/flutter_line_sdk.dart';
import 'package:google_sign_in/google_sign_in.dart';

// Import เดิมของคุณ
import 'crud_page.dart';
import 'budget_per_month_screen.dart';
import '../notification/notification_manager.dart';

// =========================================================
// 1. NOTIFICATION LIST SCREEN
// =========================================================
class NotificationListScreen extends StatelessWidget {
  const NotificationListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        return ListTile(
          leading: const CircleAvatar(
            backgroundColor: Colors.orangeAccent,
            child: Icon(Icons.notifications_active, color: Colors.white),
          ),
          title: Text('แจ้งเตือนรายการที่ ${index + 1}'),
          subtitle: const Text('คุณมีนัดชำระหนี้ในวันพรุ่งนี้ กรุณาตรวจสอบข้อมูล'),
          trailing: const Text('10:30', style: TextStyle(fontSize: 12, color: Colors.grey)),
          onTap: () {},
        );
      },
    );
  }
}

// =========================================================
// 2. PROFILE SCREEN (หน้าโปรไฟล์ที่ปรับปรุงตามบรีฟ)
// =========================================================
class ProfileScreen extends StatelessWidget {
  final VoidCallback onBack;

  const ProfileScreen({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // แถบสีเขียวด้านบนพร้อมปุ่ม Back ตามภาพที่ต้องการ
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: onBack, // กดแล้วกลับไปหน้า Home (index 0)
        ),
        title: const Text('โปรไฟล์ผู้ใช้งาน'),
        backgroundColor: const Color(0xFF00796B),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 30),
              decoration: const BoxDecoration(
                color: Color(0xFF00796B),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      const CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.white,
                        child: CircleAvatar(
                          radius: 56,
                          backgroundImage: NetworkImage('https://cdn-icons-png.flaticon.com/512/3135/3135715.png'), // รูปตัวอย่าง
                        ),
                      ),
                      CircleAvatar(
                        backgroundColor: Colors.orangeAccent,
                        radius: 18,
                        child: IconButton(
                          icon: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                          onPressed: () {},
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'สมชาย ใจดี',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Text(
                    'somchai.j@example.com',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildProfileItem(Icons.person_outline, 'ชื่อ-นามสกุล', 'สมชาย ใจดี'),
                  _buildProfileItem(Icons.phone_android, 'เบอร์โทรศัพท์', '081-234-5678'),
                  _buildProfileItem(Icons.cake_outlined, 'วันเกิด', '12 มกราคม 2535'),
                  const Divider(height: 40),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.redAccent),
                    title: const Text('ออกจากระบบ', style: TextStyle(color: Colors.redAccent)),
                    onTap: () {
                      // Logic logout เดิมของคุณ
                      Navigator.of(context).pushReplacementNamed('/');
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileItem(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF00796B)),
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }
}

// =========================================================
// 3. HOMEPAGE
// =========================================================
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);
  final NotificationManager _notificationManager = NotificationManager();

  @override
  void initState() {
    super.initState();
    _initNotifications();
  }

  Future<void> _initNotifications() async {
    try {
      await _notificationManager.initialize();
    } catch (e) {
      debugPrint("Notification init failed: $e");
    }
  }

  void _onItemTapped(int index) {
    int targetIndex;
    if (index == 0) targetIndex = 0;
    else if (index == 1) targetIndex = 1;
    else if (index == 3) targetIndex = 2;
    else if (index == 4) targetIndex = 3;
    else return;

    setState(() {
      _selectedIndex = targetIndex;
    });
  }

  // สร้าง WidgetOptions ภายใน Build เพื่อส่ง Callback
  List<Widget> _getWidgetOptions() {
    return [
      const CrudPage(),
      const NotificationListScreen(),
      const BudgetPerMonthScreen(),
      ProfileScreen(onBack: () => setState(() => _selectedIndex = 0)), // ส่ง Callback ให้ปุ่ม Back
    ];
  }

  String? _getAppBarTitle(int index) {
    switch(index) {
      case 0: return 'Dashboard';
      case 1: return 'การแจ้งเตือน';
      case 2: return 'งบประมาณต่อเดือน';
      case 3: return null; // หน้า Profile ใช้ AppBar ตัวเอง
      default: return 'Finance Care';
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _getAppBarTitle(_selectedIndex);
    final widgetOptions = _getWidgetOptions();

    return Scaffold(
      appBar: title != null ? AppBar(
        title: Text(title),
        backgroundColor: const Color(0xFF00796B),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              try {
                await LineSDK.instance.logout();
                await _googleSignIn.signOut();
              } catch (e) {
                debugPrint("Logout failed: $e");
              }
              Navigator.of(context).pushReplacementNamed('/');
            },
          ),
        ],
      ) : null,
      body: widgetOptions[_selectedIndex],
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).pushNamed('/simulator'),
        backgroundColor: Colors.redAccent.shade700,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        child: const Icon(Icons.calculate_outlined, size: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 6.0,
        color: const Color(0xFF00796B),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            _buildNavItem(0, Icons.home, 'Home'),
            _buildNavItem(1, Icons.notifications, 'Notify'),
            const SizedBox(width: 48),
            _buildNavItem(3, Icons.account_balance_wallet, 'Budget'),
            _buildNavItem(4, Icons.person, 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    int targetIndex;
    if (index == 0) targetIndex = 0;
    else if (index == 1) targetIndex = 1;
    else if (index == 3) targetIndex = 2;
    else targetIndex = 3;

    final isSelected = _selectedIndex == targetIndex;
    final color = isSelected ? Colors.white : Colors.white60;

    return InkWell(
      onTap: () => _onItemTapped(index),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            Text(label, style: TextStyle(color: color, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}