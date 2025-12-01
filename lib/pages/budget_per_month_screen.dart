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
  final BudgetService _budgetService = BudgetService();

  Future<List<BudgetOverview>> _fetchApiData() async {
    try {
      return await _budgetService.getAmountInBudget();
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
    setState(() => _budgetItems = data);
  }

  // เมื่อคลิกหมวดหมู่ -> เปิด dialog บันทึกรายจ่าย
  void _onBudgetItemTapped(int index) {
    final TextEditingController amountCtrl = TextEditingController();
    final TextEditingController detailCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: Colors.green[50],
            title: Text(
              'บันทึกรายจ่าย: ${_budgetItems[index].budgetName}',
              style: const TextStyle(color: Colors.green),
            ),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}'),
                      )
                    ],
                    decoration: InputDecoration(
                      labelText: 'จำนวนเงิน',
                      labelStyle: const TextStyle(color: Colors.green),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.green.shade700),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: detailCtrl,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: 'รายละเอียดเพิ่มเติม',
                      labelStyle: const TextStyle(color: Colors.green),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.green.shade700),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setDialogState(() => selectedDate = picked);
                      }
                    },
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            size: 20, color: Colors.green),
                        const SizedBox(width: 10),
                        Text(
                          "วันที่: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",
                          style: const TextStyle(color: Colors.green),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('ยกเลิก', style: TextStyle(color: Colors.green)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: () {
                  final amount = double.tryParse(amountCtrl.text);

                  if (amount != null && amount > 0) {
                    setState(() {
                      _budgetItems[index].amount += amount;
                    });
                    Navigator.pop(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('กรุณากรอกจำนวนเงินที่ถูกต้อง')),
                    );
                  }
                },
                child: const Text('บันทึก'),
              ),
            ],
          );
        },
      ),
    );
  }

  // dialog สำหรับแก้ limitBudget
  void _showEditBudgetDialog(int index) {
    final item = _budgetItems[index];
    final TextEditingController controller =
    TextEditingController(text: item.limitBudget.toString());

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: Colors.green[50],
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
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () {
                final newBudget = double.tryParse(controller.text);
                if (newBudget != null) {
                  setState(() {
                    _budgetItems[index].limitBudget = newBudget;
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('บันทึก'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final double totalBudget =
    _budgetItems.fold(0.0, (sum, item) => sum + item.limitBudget);

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ภาพรวมงบประมาณเดือนนี้',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge!
                  .copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            /// Summary card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('งบประมาณรวมที่ตั้งไว้',
                            style: TextStyle(color: Colors.grey)),
                        Text(
                          '${totalBudget.toStringAsFixed(2)} บาท',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                      ],
                    ),
                    const Icon(Icons.pie_chart,
                        size: 40, color: Colors.deepPurple),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            Text(
              'รายละเอียดงบประมาณรายหมวดหมู่ (คลิกเพื่อบันทึกรายการ)',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium!
                  .copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

          ..._budgetItems.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;

        final budgeted = item.limitBudget;
        final spent = item.amount;
        final remaining = budgeted - spent;
        final percentage =
        budgeted > 0 ? (spent / budgeted).clamp(0.0, 1.0) : 0.0;

        final progressColor = remaining < 0
            ? Colors.red
            : (remaining < budgeted * 0.2 ? Colors.orange : Colors.lightGreen);

        return Card(
          elevation: 1,
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// 🔹 ชื่อหมวดหมู่ + ปุ่มเพิ่มรายจ่าย + ปุ่มแก้ไขงบ
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.budgetName,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),

                    /// 👉 ปุ่มเพิ่มรายจ่าย (กดได้แค่ตรงนี้)
                    IconButton(
                      icon: const Icon(Icons.add_circle,
                          size: 24, color: Colors.green),
                      onPressed: () => _onBudgetItemTapped(index),
                    ),

                    /// 👉 ปุ่มแก้ไขงบประมาณ
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20, color: Colors.blue),
                      onPressed: () => _showEditBudgetDialog(index),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                /// 🔹 เหลือ: xxx บาท (ย้ายขึ้นมาไว้ด้านบน)
                Text(
                  'เหลือ: ${remaining.toStringAsFixed(2)} บาท',
                  style: TextStyle(
                    fontSize: 13,
                    color: progressColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                LinearProgressIndicator(
                  value: percentage,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                  minHeight: 8,
                ),

                const SizedBox(height: 6),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [

                    Text(
                      'ใช้ไป: ${spent.toStringAsFixed(2)} บาท',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }),
          ],
        ),
      ),
    );
  }
}
