import 'package:flutter/material.dart';
import 'package:flutter_line_sdk/flutter_line_sdk.dart';
import 'main.dart'; // Import main.dart สำหรับ Theme และ LogoHeader

// =========================================================
// 3. HOME PAGE: หน้าหลักหลัง Login สำเร็จ
// =========================================================

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  // ฟังก์ชัน Logout และกลับไปหน้า Welcome
  Future<void> _logout(BuildContext context) async {
    try {
      // พยายาม Logout จาก LINE ก่อน
      await LineSDK.instance.logout();
    } catch (e) {
      // ไม่ต้องทำอะไรมากถ้า logout ล้มเหลว อาจเพราะไม่ได้ Login ด้วย LINE
    }

    // กลับไปหน้า Welcome (/) และล้าง Stack ทั้งหมด
    // สมมติว่า '/' คือหน้า Welcome หรือ Dashboard
    Navigator.of(context).pushNamedAndRemoveUntil('/', (Route<dynamic> route) => false);
  }

  @override
  Widget build(BuildContext context) {
    // เพิ่มช่องว่างระหว่างปุ่มด้วย SizedBox
    const double buttonSpacing = 20;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home (Logged In)'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
            tooltip: 'ออกจากระบบ',
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.green, size: 80),
              const SizedBox(height: 20),
              const Text(
                'Login Successful!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),

              // ปุ่มที่ 1: บันทึกค่าใช้จ่ายใหม่ (CRUD Entry Screen)
              ElevatedButton.icon(
                // Route เดิม: '/expense_entry'
                onPressed: () => Navigator.of(context).pushNamed('/expense_entry'),
                icon: const Icon(Icons.add_circle, size: 30),
                label: const Text(
                  'บันทึกค่าใช้จ่ายใหม่ (CRUD Entry)',
                  style: TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  backgroundColor: Colors.teal.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),

              // เพิ่มช่องว่าง
              const SizedBox(height: buttonSpacing),

              // ปุ่มที่ 2: งบประมาณรายเดือน (Budget Per Month Screen)
              ElevatedButton.icon(
                // *** แก้ไข: เปลี่ยน Named Route เป็น '/budget_per_month' ***
                onPressed: () => Navigator.of(context).pushNamed('/budget_per_month'),
                // *** แก้ไข: ใช้ Icon ที่สื่อถึงงบประมาณ ***
                icon: const Icon(Icons.account_balance_wallet, size: 30),
                // *** แก้ไข: อัปเดต Label ให้ชัดเจน ***
                label: const Text(
                  'งบประมาณรายเดือน',
                  style: TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  backgroundColor: Colors.teal.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}