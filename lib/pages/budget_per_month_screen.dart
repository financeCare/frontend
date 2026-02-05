import '../models/budgetOverview.dart';
import '../services/budget_service.dart';
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
  double _monthlyIncome = 20000; // รายรับรวมเดือนนี้
  double _debtPayment = 5000; // เงินที่แบ่งใช้หนี้
  double _monthlySaving = 3000; // เงินที่เก็บไว้ใช้/ออม

  @override
  void initState() {
    super.initState();
    _loadBudgetData();
  }

  Future<void> _loadBudgetData() async {
    final data = await _fetchApiData();
    setState(() => _budgetItems = data);
  }

  void _showMonthlySummaryDialog() {
    final incomeCtrl = TextEditingController(
      text: _monthlyIncome.toStringAsFixed(2),
    );
    final debtCtrl = TextEditingController(
      text: _debtPayment.toStringAsFixed(2),
    );
    final savingCtrl = TextEditingController(
      text: _monthlySaving.toStringAsFixed(2),
    );

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.green[50],
        title: const Text('ตั้งค่าภาพรวมรายรับ/ใช้หนี้/เก็บไว้'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: incomeCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              decoration: const InputDecoration(labelText: 'รายรับรวมเดือนนี้'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: debtCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              decoration: const InputDecoration(
                labelText: 'เงินที่แบ่งใช้หนี้',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: savingCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              decoration: const InputDecoration(
                labelText: 'เงินที่เก็บไว้ใช้/ออม',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () {
              final income = double.tryParse(incomeCtrl.text) ?? 0.0;
              final debt = double.tryParse(debtCtrl.text) ?? 0.0;
              final saving = double.tryParse(savingCtrl.text) ?? 0.0;

              if (income < 0 || debt < 0 || saving < 0) {
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(
                    content: Text('ตัวเลขต้องมากกว่าหรือเท่ากับ 0'),
                  ),
                );
                return;
              }
              if (debt + saving > income) {
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(
                    content: Text('ใช้หนี้ + เก็บไว้ ต้องไม่เกินรายรับ'),
                  ),
                );
                return;
              }

              setState(() {
                _monthlyIncome = income;
                _debtPayment = debt;
                _monthlySaving = saving;
              });
              Navigator.pop(context);
            },
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );
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
                      ),
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
                        const Icon(
                          Icons.calendar_today,
                          size: 20,
                          color: Colors.green,
                        ),
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
                child: const Text(
                  'ยกเลิก',
                  style: TextStyle(color: Colors.green),
                ),
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
                      const SnackBar(
                        content: Text('กรุณากรอกจำนวนเงินที่ถูกต้อง'),
                      ),
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
    final controller = TextEditingController(
      text: item.limitBudget.toStringAsFixed(2),
    );

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: Colors.green[50],
          title: Text('ปรับวงเงินงบประมาณ: ${item.budgetName}'),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
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

                if (newBudget == null || newBudget < 0) {
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(content: Text('กรุณากรอกวงเงินที่ถูกต้อง')),
                  );
                  return;
                }

                setState(() {
                  _budgetItems[index].limitBudget = newBudget;
                });

                Navigator.pop(context);
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
    final double totalBudget = _budgetItems.fold(
      0.0,
      (sum, item) => sum + item.limitBudget,
    );
    final double usableMoney = (_monthlyIncome - _debtPayment - _monthlySaving)
        .clamp(0.0, double.infinity);

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
                        const Text(
                          'งบประมาณรวมที่ตั้งไว้',
                          style: TextStyle(color: Colors.grey),
                        ),
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

const SizedBox(height: 10),

StackedIncomeBar(
  income: _monthlyIncome,
  debt: _debtPayment,
  saving: _monthlySaving,
  height: 14,
),

const SizedBox(height: 8),

Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Text(
      'หนี้: ${_debtPayment.toStringAsFixed(2)}',
      style: const TextStyle(fontSize: 12, color: Colors.red),
    ),
    Text(
      'เก็บ: ${_monthlySaving.toStringAsFixed(2)}',
      style: const TextStyle(fontSize: 12, color: Colors.blue),
    ),
    Text(
      'เหลือใช้: ${usableMoney.toStringAsFixed(2)}',
      style: const TextStyle(fontSize: 12, color: Colors.green),
    ),
  ],
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

              final budgeted = item.limitBudget;
              final spent = item.amount;
              final remaining = budgeted - spent;
              final percentage = budgeted > 0
                  ? (spent / budgeted).clamp(0.0, 1.0)
                  : 0.0;

              final progressColor = remaining < 0
                  ? Colors.red
                  : (remaining < budgeted * 0.2
                        ? Colors.orange
                        : Colors.lightGreen);

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
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),

                          /// 👉 ปุ่มเพิ่มรายจ่าย (กดได้แค่ตรงนี้)
                          IconButton(
                            icon: const Icon(
                              Icons.add_circle,
                              size: 24,
                              color: Colors.green,
                            ),
                            onPressed: () => _onBudgetItemTapped(index),
                          ),

                          /// 👉 ปุ่มแก้ไขงบประมาณ
                          IconButton(
                            icon: const Icon(
                              Icons.edit,
                              size: 20,
                              color: Colors.blue,
                            ),
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

                      StackedBudgetBar(
                        spent: spent,
                        limit: budgeted,
                        height: 10,
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

class _MiniInfoBox extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _MiniInfoBox({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.green, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class StackedBudgetBar extends StatelessWidget {
  final double spent;
  final double limit;
  final double height;

  const StackedBudgetBar({
    super.key,
    required this.spent,
    required this.limit,
    this.height = 10,
  });

  @override
  Widget build(BuildContext context) {
    final double usedRatio = limit > 0 ? (spent / limit).clamp(0.0, 1.0) : 0.0;
    final double remainingRatio = 1.0 - usedRatio;

    Color usedColor;
    Color remainingColor;

    if (spent > limit) {
      usedColor = Colors.red;
      remainingColor = Colors.red.shade200;
    } else if (spent > limit * 0.8) {
      usedColor = Colors.orange;
      remainingColor = Colors.orange.shade200;
    } else {
      usedColor = Colors.green;
      remainingColor = Colors.green.shade200;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Row(
        children: [
          /// 🟥 ใช้ไป
          Expanded(
            flex: (usedRatio * 1000).toInt(),
            child: Container(height: height, color: usedColor),
          ),

          /// 🟩 เหลือ
          Expanded(
            flex: (remainingRatio * 1000).toInt(),
            child: Container(height: height, color: remainingColor),
          ),
        ],
      ),
    );
  }
}


class StackedIncomeBar extends StatelessWidget {
  final double income;   // รายรับรวม
  final double debt;     // ใช้หนี้
  final double saving;   // เก็บไว้/ออม
  final double height;

  const StackedIncomeBar({
    super.key,
    required this.income,
    required this.debt,
    required this.saving,
    this.height = 12,
  });

  @override
  Widget build(BuildContext context) {
    if (income <= 0) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: height,
          color: Colors.grey.shade300,
        ),
      );
    }

    final double usable = (income - debt - saving).clamp(0.0, double.infinity);

    // normalize เป็นสัดส่วน
    final debtRatio = (debt / income).clamp(0.0, 1.0);
    final savingRatio = (saving / income).clamp(0.0, 1.0);
    final usableRatio = (usable / income).clamp(0.0, 1.0);

    // ถ้ารวมเกิน 1 (กรณี debt+saving > income) ให้ตัด usable เป็น 0 แล้ว scale debt/saving
    double total = debtRatio + savingRatio + usableRatio;
    double d = debtRatio, s = savingRatio, u = usableRatio;

    if (total > 1.0) {
      u = 0.0;
      final ds = (debtRatio + savingRatio);
      if (ds > 0) {
        d = debtRatio / ds;
        s = savingRatio / ds;
      }
      total = d + s; // = 1
    }

    int flexDebt = (d * 1000).round();
    int flexSaving = (s * 1000).round();
    int flexUsable = (u * 1000).round();

    // กัน flex = 0 แล้ว Row error/มองไม่เห็น
    flexDebt = flexDebt == 0 && debt > 0 ? 1 : flexDebt;
    flexSaving = flexSaving == 0 && saving > 0 ? 1 : flexSaving;
    flexUsable = flexUsable == 0 && usable > 0 ? 1 : flexUsable;

    // ถ้าทุกอันเป็น 0 (เช่น income>0 แต่ debt/saving/usable เป็น 0) ให้โชว์แท่ง usable
    if (flexDebt + flexSaving + flexUsable == 0) {
      flexUsable = 1000;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Row(
        children: [
          if (flexDebt > 0)
            Expanded(
              flex: flexDebt,
              child: Container(height: height, color: Colors.red),
            ),
          if (flexSaving > 0)
            Expanded(
              flex: flexSaving,
              child: Container(height: height, color: Colors.blue),
            ),
          if (flexUsable > 0)
            Expanded(
              flex: flexUsable,
              child: Container(height: height, color: Colors.green),
            ),
        ],
      ),
    );
  }
}
