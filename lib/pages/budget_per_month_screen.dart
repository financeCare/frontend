import 'package:financeCare/models/budgetOverview.dart';
import 'package:financeCare/services/budget_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BudgetPerMonthScreen extends StatefulWidget {
  const BudgetPerMonthScreen({super.key});

  @override
  State<BudgetPerMonthScreen> createState() => _BudgetPerMonthScreenState();
}

class _BudgetPerMonthScreenState extends State<BudgetPerMonthScreen> {
  final List<Map<String, dynamic>> _budgetItems = [
    {
      'category': 'ค่าอาหาร',
      'budgeted': 10000.0,
      'spent': 0.0,
      'icon': Icons.fastfood,
      'color': Colors.orange,
      'transactions': []
    },
    {
      'category': 'ค่าเช่า',
      'budgeted': 5000.0,
      'spent': 0.0,
      'icon': Icons.home,
      'color': Colors.blue,
      'transactions': []
    },
    {
      'category': 'การเดินทาง',
      'budgeted': 3000.0,
      'spent': 0.0,
      'icon': Icons.directions_car,
      'color': Colors.green,
      'transactions': []
    },
    {
      'category': 'ช้อปปิ้ง',
      'budgeted': 2000.0,
      'spent': 0.0,
      'icon': Icons.shopping_bag,
      'color': Colors.red,
      'transactions': []
    },
  ];

  void _onBudgetItemTapped(int index) {
    final TextEditingController amountCtrl = TextEditingController();
    final TextEditingController detailCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setDialogState) {
        return AlertDialog(
          backgroundColor: Colors.green[50], // พื้นหลังอ่อนเขียว
          title: Text(
            'บันทึกรายจ่าย: ${_budgetItems[index]['category']}',
            style: const TextStyle(color: Colors.green),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))
                    ],
                    decoration: InputDecoration(
                      labelText: 'จำนวนเงิน',
                      labelStyle: const TextStyle(color: Colors.green),
                      contentPadding:
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.green.shade700),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.green.shade700),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: detailCtrl,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline, // กด Enter ลงบรรทัดใหม่
                    maxLines: 6,
                    decoration: InputDecoration(
                      labelText: 'รายละเอียดเพิ่มเติม',
                      alignLabelWithHint: true,
                      labelStyle: const TextStyle(color: Colors.green),
                      contentPadding:
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.green.shade700),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.green.shade700),
                      ),
                    ),
                  )
                  ,
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: ColorScheme.light(
                                  primary: Colors.green, // header background
                                  onPrimary: Colors.white, // header text
                                  onSurface: Colors.green, // body text
                                ),
                                textButtonTheme: TextButtonThemeData(
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.green,
                                  ),
                                ),
                              ),
                              child: child!,
                            );
                          });
                      if (picked != null) {
                        setDialogState(() => selectedDate = picked);
                      }
                    },
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 20, color: Colors.green),
                        const SizedBox(width: 10),
                        Text(
                          'วันที่: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                          style: const TextStyle(color: Colors.green),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ยกเลิก', style: TextStyle(color: Colors.green)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green, // ปุ่มสีเขียว
              ),
              onPressed: () {
                final amount = double.tryParse(amountCtrl.text);
                if (amount != null && amount > 0) {
                  setState(() {
                    _budgetItems[index]['spent'] += amount;
                    _budgetItems[index]['transactions'].add({
                      'amount': amount,
                      'detail': detailCtrl.text,
                      'date': selectedDate
                    });
                  });
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('กรุณากรอกจำนวนเงินที่ถูกต้อง')),
                  );
                }
              },
              child: const Text('บันทึก'),
            ),
          ],
        );
      }),
    );
  // ข้อมูลงบประมาณ (Stateful)

  final BudgetService _budgetService = BudgetService();
  Future<List<BudgetOverview>> _fetchApiData() async {
    try {
      final List<BudgetOverview> budget = await _budgetService
          .getAmountInBudget();
      return budget;
    } catch (e) {
      print('API Error: $e');
      return [];
    }
  }

  List<BudgetOverview> _budgetItems = [];
  @override
  void initState() {
    super.initState();
    _loadBudgetData();
  }

  Future<void> _loadBudgetData() async {
    final data = await _fetchApiData();
    setState(() {
      _budgetItems = data;
    });
  }

  // final List<Map<String, dynamic>> _budgetItems = [
  //   {'category': 'ค่าอาหาร', 'budgeted': 10000.0, 'spent': 7500.0, 'icon': Icons.fastfood, 'color': Colors.orange},
  //   {'category': 'ค่าเช่า', 'budgeted': 5000.0, 'spent': 5000.0, 'icon': Icons.home, 'color': Colors.blue},
  //   {'category': 'การเดินทาง', 'budgeted': 3000.0, 'spent': 1200.0, 'icon': Icons.directions_car, 'color': Colors.green},
  //   {'category': 'ช้อปปิ้ง', 'budgeted': 2000.0, 'spent': 3500.0, 'icon': Icons.shopping_bag, 'color': Colors.red},
  // ];

  // ฟังก์ชันจัดการเมื่อคลิกที่รายการงบประมาณ (ไปหน้าบันทึกค่าใช้จ่าย)
  void _onBudgetItemTapped(String category) {
    // นำทางไปยัง Expense Entry Screen พร้อมส่ง 'category' เป็น arguments
    Navigator.of(
      context,
    ).pushNamed('/expense_entry', arguments: {'initialCategory': category});
  }




  void _showEditBudgetDialog(int index) {
    // final item = _budgetItems[index];
    final item = _budgetItems[index];
    final TextEditingController controller =
    TextEditingController(text: item['budgeted'].toString());

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.green[50], // พื้นหลังอ่อนเขียว
          title: Text(
            'ปรับวงเงินงบประมาณ: ${item['category']}',
            style: const TextStyle(color: Colors.green),
          ),
          title: Text('ปรับวงเงินงบประมาณ: ${item.budgetName}'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: 'วงเงินใหม่ (บาท)',
              labelStyle: const TextStyle(color: Colors.green),
              border: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.green.shade700),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.green.shade700),
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('ยกเลิก', style: TextStyle(color: Colors.green)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green, // ปุ่มสีเขียว
              ),
              child: const Text('บันทึก'),
              onPressed: () {
                final newBudget = double.tryParse(controller.text);
                if (newBudget != null && newBudget >= 0) {
                  setState(() {
                    _budgetItems[index].limitBudget = newBudget;
                  });
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('กรุณาป้อนจำนวนเงินที่ถูกต้อง')),
                  );
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
    final double totalBudget =
    _budgetItems.fold(0.0, (sum, item) => sum + item['budgeted']);

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ภาพรวมงบประมาณเดือนนี้',
              style: Theme.of(
                context,
              ).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('งบประมาณรวมที่ตั้งไว้',
                            style: TextStyle(fontSize: 16, color: Colors.grey)),
                        Text('${totalBudget.toStringAsFixed(2)} บาท',
                            style: const TextStyle(
                                fontSize: 24, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                      ],
                    ),
                    const Icon(
                      Icons.pie_chart,
                      size: 40,
                      color: Colors.deepPurple,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'รายละเอียดงบประมาณรายหมวดหมู่ (คลิกเพื่อบันทึกรายการ)',
              style: Theme.of(
                context,
              ).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ..._budgetItems.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;

              final double budgeted = item.limitBudget;
              final double spent = item.amount;
              final double remaining = budgeted - spent;

              // ตรวจสอบเพื่อป้องกันหารด้วยศูนย์
              final double percentage = budgeted > 0
                  ? (spent / budgeted).clamp(0.0, 1.0)
                  : 0.0;
              final Color progressColor = remaining < 0
                  ? Colors.red
                  : (remaining < (budgeted * 0.2)
                        ? Colors.orange
                        : Colors.lightGreen);

              return Card(
                elevation: 1,
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Icon(
                          //   item['icon'] as IconData,
                          //   color: item['color'] as Color,
                          // ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.budgetName,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium!
                                      .copyWith(fontWeight: FontWeight.w600),
                                ),
                                // Text แสดง Budget ที่ตั้งไว้
                                Text(
                                  'งบที่ตั้ง: ${budgeted.toStringAsFixed(2)} บาท',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // ปุ่มแก้ไข Budget Limit
                          IconButton(
                            icon: const Icon(
                              Icons.edit,
                              size: 20,
                              color: Colors.blue,
                            ),
                            onPressed: () => _showEditBudgetDialog(
                              index,
                            ), // **เรียกใช้ฟังก์ชันแก้ไข**
                            tooltip: 'แก้ไขวงเงินงบประมาณ',
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Progress Bar
                      LinearProgressIndicator(
                        value: percentage,
                        backgroundColor: Colors.grey.shade300,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          progressColor,
                        ),
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // InkWell สำหรับการนำทาง (คลิกเพื่อบันทึกรายการ)
                          InkWell(
                            onTap: () => _onBudgetItemTapped(item.budgetName),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 4.0,
                              ),
                              child: Text(
                                'ใช้ไป: ${spent.toStringAsFixed(2)} บาท',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black87,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                            Text(
                              'เหลือ: ${remaining.toStringAsFixed(2)} บาท',
                              style: TextStyle(
                                  color: progressColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        // แสดงรายการ transactions ล่าสุด
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: List<Widget>.from(
                            (item['transactions'] as List<dynamic>)
                                .map((t) => Text(
                                '${t['date'].day}/${t['date'].month}/${t['date'].year} - ${t['detail']} : ${t['amount'].toStringAsFixed(2)} บาท',
                                style: const TextStyle(fontSize: 12))),
                          ),
                          Text(
                            'เหลือ: ${remaining.toStringAsFixed(2)} บาท',
                            style: TextStyle(
                              color: progressColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
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
