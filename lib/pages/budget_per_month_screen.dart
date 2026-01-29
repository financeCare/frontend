import 'package:flutter/material.dart';

class BudgetPerMonthScreen extends StatefulWidget {
  const BudgetPerMonthScreen({super.key});

  @override
  State<BudgetPerMonthScreen> createState() => _BudgetPerMonthScreenState();
}

class _BudgetPerMonthScreenState extends State<BudgetPerMonthScreen> {
<<<<<<< Updated upstream
  // ข้อมูลจำลองของงบประมาณ (Category, Amount, Color)
  final List<Map<String, dynamic>> budgetItems = [
    {'category': 'ค่าอาหาร', 'budgeted': 10000.0, 'spent': 7500.0, 'icon': Icons.fastfood, 'color': Colors.orange},
    {'category': 'ค่าเช่า', 'budgeted': 5000.0, 'spent': 5000.0, 'icon': Icons.home, 'color': Colors.blue},
    {'category': 'การเดินทาง', 'budgeted': 3000.0, 'spent': 1200.0, 'icon': Icons.directions_car, 'color': Colors.green},
    {'category': 'ช้อปปิ้ง', 'budgeted': 2000.0, 'spent': 3500.0, 'icon': Icons.shopping_bag, 'color': Colors.red},
  ];

  // ฟังก์ชันจัดการเมื่อคลิกที่รายการงบประมาณ
  void _onBudgetItemTapped(String category) {
    // นำทางไปยัง Expense Entry Screen พร้อมส่ง 'category' เป็น arguments
    // เพื่อให้หน้า ExpenseEntryScreen สามารถเลือกหมวดหมู่นี้เป็นค่าเริ่มต้นได้
=======
  // 1. ข้อมูลงบประมาณ (เพิ่มข้อมูล ID และสถานะแจ้งเตือน)
  final List<Map<String, dynamic>> _budgetItems = [
    {'id': 1, 'category': 'ค่าอาหาร', 'budgeted': 10000.0, 'spent': 7500.0, 'icon': Icons.fastfood, 'color': Colors.orange},
    {'id': 2, 'category': 'ค่าเช่า', 'budgeted': 5000.0, 'spent': 5000.0, 'icon': Icons.home, 'color': Colors.blue},
    {'id': 3, 'category': 'การเดินทาง', 'budgeted': 3000.0, 'spent': 1200.0, 'icon': Icons.directions_car, 'color': Colors.green},
    {'id': 4, 'category': 'ช้อปปิ้ง', 'budgeted': 2000.0, 'spent': 3500.0, 'icon': Icons.shopping_bag, 'color': Colors.red},
  ];

  // 2. ฟังก์ชันตรวจสอบการแจ้งเตือน (Logic แจ้งเตือนเมื่อใกล้หมดหรือเกิน)
  void _checkBudgetAlert(int index) {
    final item = _budgetItems[index];
    final remaining = item['budgeted'] - item['spent'];

    String title = "";
    String message = "";
    Color alertColor = Colors.grey;

    if (remaining < 0) {
      title = "งบประมาณเกินกำหนด!";
      message = "หมวด ${item['category']} ใช้เกินไปแล้ว ${remaining.abs().toStringAsFixed(2)} บาท";
      alertColor = Colors.red;
    } else if (remaining < (item['budgeted'] * 0.2)) {
      title = "งบประมาณใกล้หมด";
      message = "หมวด ${item['category']} เหลือเงินไม่ถึง 20%";
      alertColor = Colors.orange;
    } else {
      return; // ไม่ต้องแจ้งเตือนถ้ายังเหลือเยอะ
    }

    // แสดง SnackBar แจ้งเตือน (ในแอปจริงอาจส่ง Notification)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: alertColor,
        behavior: SnackBarBehavior.floating,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(message, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  void _onBudgetItemTapped(String category) {
>>>>>>> Stashed changes
    Navigator.of(context).pushNamed(
      '/expense_entry',
      arguments: {'initialCategory': category},
    );
  }

<<<<<<< Updated upstream
  @override
  Widget build(BuildContext context) {
=======
  // 3. Dialog สำหรับแก้ไขวงเงิน (โครงเดิมที่คุณต้องการ)
  void _showEditBudgetDialog(int index) {
    final item = _budgetItems[index];
    final TextEditingController controller = TextEditingController(text: item['budgeted'].toString());

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('ปรับวงเงิน: ${item['category']}'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'วงเงินใหม่ (บาท)',
              border: OutlineInputBorder(),
              prefixText: '฿ ',
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('ยกเลิก'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
              child: const Text('บันทึก'),
              onPressed: () {
                final newBudget = double.tryParse(controller.text);
                if (newBudget != null && newBudget >= 0) {
                  setState(() {
                    _budgetItems[index]['budgeted'] = newBudget;
                  });
                  Navigator.of(context).pop();
                  // ตรวจสอบแจ้งเตือนทันทีหลังเปลี่ยนค่า
                  _checkBudgetAlert(index);
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final double totalBudget = _budgetItems.fold(0.0, (sum, item) => sum + item['budgeted']);
    final double totalSpent = _budgetItems.fold(0.0, (sum, item) => sum + item['spent']);

>>>>>>> Stashed changes
    return Scaffold(
      appBar: AppBar(
        title: const Text('จัดการงบประมาณ', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF00796B), // สีเขียวเข้มตามรูปที่คุณส่งมา
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
<<<<<<< Updated upstream
            Text(
              'ภาพรวมงบประมาณเดือนนี้',
              style: Theme.of(context).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            // Card สรุปงบประมาณรวม (Placeholder)
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: const Padding(
                padding: EdgeInsets.all(20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('งบประมาณรวม', style: TextStyle(fontSize: 16, color: Colors.grey)),
                        Text('20,000.00 บาท', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                      ],
                    ),
                    Icon(Icons.pie_chart, size: 40, color: Colors.deepPurple),
                  ],
                ),
=======
            // ส่วนบน: ภาพรวม (Dashboard)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF00796B), Color(0xFF004D40)]),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('งบประมาณทั้งหมด', style: TextStyle(color: Colors.white70, fontSize: 14)),
                      Text('${totalBudget.toStringAsFixed(0)} ฿',
                          style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 5),
                      Text('ใช้ไปแล้ว: ${totalSpent.toStringAsFixed(0)} ฿',
                          style: const TextStyle(color: Colors.white60, fontSize: 12)),
                    ],
                  ),
                  const Icon(Icons.account_balance_wallet, color: Colors.white, size: 50),
                ],
>>>>>>> Stashed changes
              ),
            ),

            const SizedBox(height: 24),
            const Text(
              'รายหมวดหมู่',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 12),

            // รายการงบประมาณ
<<<<<<< Updated upstream
            ...budgetItems.map((item) {
              final double remaining = item['budgeted'] - item['spent'];
              final double percentage = (item['spent'] / item['budgeted']) * 100;
              final Color progressColor = remaining < 0 ? Colors.red : (remaining < (item['budgeted'] * 0.2) ? Colors.orange : Colors.lightGreen);

              return Card(
                elevation: 1,
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: InkWell( // **จุดสำคัญ: ใช้ InkWell/GestureDetector เพื่อให้สามารถคลิกได้**
                  onTap: () => _onBudgetItemTapped(item['category']),
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(item['icon'] as IconData, color: item['color'] as Color),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                item['category'] as String,
                                style: Theme.of(context).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),
                            Text(
                              'เหลือ: ${remaining.toStringAsFixed(2)}',
                              style: TextStyle(color: progressColor, fontWeight: FontWeight.bold),
                            ),
                            const Icon(Icons.chevron_right, color: Colors.grey),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Progress Bar
                        LinearProgressIndicator(
                          value: item['spent'] / item['budgeted'],
                          backgroundColor: Colors.grey.shade300,
                          valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('ใช้ไป: ${item['spent'].toStringAsFixed(2)} บาท', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            Text('งบที่ตั้ง: ${item['budgeted'].toStringAsFixed(2)} บาท', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        )
                      ],
                    ),
=======
            ..._budgetItems.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;

              final double budgeted = item['budgeted'];
              final double spent = item['spent'];
              final double remaining = budgeted - spent;
              final double percentage = budgeted > 0 ? (spent / budgeted).clamp(0.0, 1.0) : 0.0;

              final Color progressColor = remaining < 0 ? Colors.red : (remaining < (budgeted * 0.2) ? Colors.orange : Colors.green);

              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: (item['color'] as Color).withOpacity(0.1),
                            child: Icon(item['icon'] as IconData, color: item['color'] as Color),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item['category'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                Text('ตั้งไว้: ${budgeted.toStringAsFixed(0)} ฿', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_note, color: Colors.blue),
                            onPressed: () => _showEditBudgetDialog(index),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: percentage,
                          minHeight: 8,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () => _onBudgetItemTapped(item['category']),
                            child: Text(
                              'ใช้ไป: ${spent.toStringAsFixed(0)} ฿',
                              style: const TextStyle(fontSize: 13, decoration: TextDecoration.underline),
                            ),
                          ),
                          Text(
                            remaining < 0 ? 'เกินมา: ${remaining.abs().toStringAsFixed(0)} ฿' : 'เหลือ: ${remaining.toStringAsFixed(0)} ฿',
                            style: TextStyle(color: progressColor, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
>>>>>>> Stashed changes
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}