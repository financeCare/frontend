import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


class ExpenseHistory {
  double amount;
  String detail;
  DateTime date;

  ExpenseHistory({
    required this.amount,
    required this.detail,
    required this.date,
  });
}

class BudgetOverview {
  final String id;
  final String budgetName;
  double limitBudget;
  double amount;
  final List<ExpenseHistory> histories;

  BudgetOverview({
    required this.id,
    required this.budgetName,
    required this.limitBudget,
    required this.amount,
    List<ExpenseHistory>? histories,
  }) : histories = histories ?? [];
}

/// ===============================
/// SCREEN
/// ===============================
class BudgetPerMonthScreen extends StatefulWidget {
  const BudgetPerMonthScreen({super.key});

  @override
  State<BudgetPerMonthScreen> createState() => _BudgetPerMonthScreenState();
}

class _BudgetPerMonthScreenState extends State<BudgetPerMonthScreen> {
  /// 🔹 MOCK DATA (แทน API)
  final List<BudgetOverview> _budgetItems = [
    BudgetOverview(
      id: '1',
      budgetName: 'อาหาร',
      limitBudget: 5000,
      amount: 0,
    ),
    BudgetOverview(
      id: '2',
      budgetName: 'เดินทาง',
      limitBudget: 3000,
      amount: 0,
    ),
    BudgetOverview(
      id: '3',
      budgetName: 'บันเทิง',
      limitBudget: 2000,
      amount: 0,
    ),
  ];
  void _editHistory(BudgetOverview budget, int index) {
    final h = budget.histories[index];
    final amountCtrl =
    TextEditingController(text: h.amount.toString());
    final detailCtrl =
    TextEditingController(text: h.detail);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('แก้ไขรายจ่าย'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'จำนวนเงิน'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: detailCtrl,
              decoration: const InputDecoration(labelText: 'รายละเอียด'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () {
              final newAmount = double.tryParse(amountCtrl.text);
              if (newAmount == null || newAmount <= 0) return;

              setState(() {
                budget.amount -= h.amount;
                h.amount = newAmount;
                h.detail = detailCtrl.text;
                budget.amount += newAmount;
              });

              Navigator.pop(context);
            },
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );
  }
  void _deleteHistory(BudgetOverview budget, int index) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: const Text('ต้องการลบรายการนี้หรือไม่'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              setState(() {
                budget.amount -= budget.histories[index].amount;
                budget.histories.removeAt(index);
              });
              Navigator.pop(context);
            },
            child: const Text('ลบ'),
          ),
        ],
      ),
    );
  }

  /// ===============================
  /// ADD EXPENSE
  /// ===============================
  void _addExpense(BudgetOverview budget) {
    final amountCtrl = TextEditingController();
    final detailCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text('บันทึกรายจ่าย: ${budget.budgetName}'),
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
                    decoration: const InputDecoration(
                      labelText: 'จำนวนเงิน',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: detailCtrl,
                    decoration: const InputDecoration(
                      labelText: 'รายละเอียด',
                      border: OutlineInputBorder(),
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
                        const Icon(Icons.calendar_today, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
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
                child: const Text('ยกเลิก'),
              ),
              ElevatedButton(
                onPressed: () {
                  final amount = double.tryParse(amountCtrl.text);
                  if (amount == null || amount <= 0) return;

                  setState(() {
                    budget.amount += amount;
                    budget.histories.add(
                      ExpenseHistory(
                        amount: amount,
                        detail: detailCtrl.text,
                        date: selectedDate,
                      ),
                    );
                  });

                  Navigator.pop(context);
                },
                child: const Text('บันทึก'),
              ),
            ],
          );
        },
      ),
    );
  }

  /// ===============================
  /// HISTORY
  /// ===============================
  void _showHistory(BudgetOverview budget) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('ประวัติรายจ่าย: ${budget.budgetName}'),
        content: SizedBox(
          width: double.maxFinite,
          child: budget.histories.isEmpty
              ? const Text('ยังไม่มีประวัติรายจ่าย')
              : ListView.builder(
            shrinkWrap: true,
            itemCount: budget.histories.length,
            itemBuilder: (context, index) {
              final h = budget.histories[index];
              return ListTile(
                leading: const Icon(Icons.payments, color: Colors.green),
                title: Text('${h.amount.toStringAsFixed(2)} บาท'),
                subtitle: Text(
                  '${h.detail.isEmpty ? "-" : h.detail}\n'
                      '${h.date.day}/${h.date.month}/${h.date.year}',
                ),
                isThreeLine: true,

                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () {
                        Navigator.pop(context);
                        _editHistory(budget, index);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        Navigator.pop(context);
                        _deleteHistory(budget, index);
                      },
                    ),
                  ],
                ),
              );

            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ปิด'),
          ),
        ],
      ),
    );
  }

  /// ===============================
  /// EDIT BUDGET
  /// ===============================
  void _editBudget(BudgetOverview budget) {
    final ctrl = TextEditingController(text: budget.limitBudget.toString());

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('แก้ไขงบ: ${budget.budgetName}'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            labelText: 'วงเงินใหม่',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = double.tryParse(ctrl.text);
              if (value != null) {
                setState(() => budget.limitBudget = value);
              }
              Navigator.pop(context);
            },
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );
  }

  /// ===============================
  /// UI
  /// ===============================
  @override
  Widget build(BuildContext context) {
    final totalBudget =
    _budgetItems.fold(0.0, (sum, b) => sum + b.limitBudget);

    return Scaffold(

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'งบประมาณรวม: ${totalBudget.toStringAsFixed(2)} บาท',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          ..._budgetItems.map((budget) {
            final remaining = budget.limitBudget - budget.amount;
            final percent = budget.limitBudget > 0
                ? (budget.amount / budget.limitBudget).clamp(0.0, 1.0)
                : 0.0;

            final color = remaining < 0
                ? Colors.red
                : remaining < budget.limitBudget * 0.2
                ? Colors.orange
                : Colors.green;

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            budget.budgetName,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.history,
                              color: Colors.orange),
                          onPressed: () => _showHistory(budget),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle,
                              color: Colors.green),
                          onPressed: () => _addExpense(budget),
                        ),
                        IconButton(
                          icon:
                          const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _editBudget(budget),
                        ),
                      ],
                    ),
                    Text(
                      'เหลือ: ${remaining.toStringAsFixed(2)} บาท',
                      style:
                      TextStyle(color: color, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: percent,
                      minHeight: 8,
                      color: color,
                      backgroundColor: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 6),
                    Text('ใช้ไป: ${budget.amount.toStringAsFixed(2)} บาท'),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
