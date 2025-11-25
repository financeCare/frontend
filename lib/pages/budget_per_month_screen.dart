import 'package:flutter/material.dart';

class BudgetPerMonthScreen extends StatefulWidget {
  const BudgetPerMonthScreen({super.key});

  @override
  State<BudgetPerMonthScreen> createState() => _BudgetPerMonthScreenState();
}

class _BudgetPerMonthScreenState extends State<BudgetPerMonthScreen> {
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
    Navigator.of(context).pushNamed(
      '/expense_entry',
      arguments: {'initialCategory': category},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'รายละเอียดงบประมาณรายหมวดหมู่ (คลิกเพื่อบันทึกรายการ)',
              style: Theme.of(context).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // รายการงบประมาณ
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