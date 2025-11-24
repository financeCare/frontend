import 'package:flutter/material.dart';
import '../models/finance_item.dart';
import '../models/constants.dart';
import 'dashboard_page.dart';
import 'package:flutter/services.dart';

class CrudPage extends StatefulWidget {
  const CrudPage({super.key});

  @override
  State<CrudPage> createState() => _CrudPageState();
}

class _CrudPageState extends State<CrudPage> {
  int currentStep = 1;

  final TextEditingController incomeCtrl = TextEditingController();
  List<FinanceItem> incomes = [];

  final TextEditingController debtNameCtrl = TextEditingController();
  final TextEditingController debtAmountCtrl = TextEditingController();
  final TextEditingController debtInterestCtrl = TextEditingController();
  String selectedDebtType = debtTypes[0];
  List<FinanceItem> debts = [];

  bool incomeError = false;
  bool debtNameError = false;
  bool debtAmountError = false;
  bool debtInterestError = false;

  void addIncome() {
    setState(() {
      incomeError = incomeCtrl.text.isEmpty;
    });

    if (incomeError) return;

    incomes.add(FinanceItem(
      name: "Income",
      amount: double.tryParse(incomeCtrl.text) ?? 0,
    ));

    incomeCtrl.clear();
    setState(() {
      currentStep = 2;
    });
  }

  void addDebt() {
    if (debtNameCtrl.text.isEmpty ||
        debtAmountCtrl.text.isEmpty ||
        debtInterestCtrl.text.isEmpty ||
        selectedDebtType.isEmpty) return;

    debts.add(FinanceItem(
      name: debtNameCtrl.text,
      amount: double.tryParse(debtAmountCtrl.text) ?? 0,
      interest: double.tryParse(debtInterestCtrl.text) ?? 0,
      type: selectedDebtType,          // ต้องมีตัวแปร selectedDebtType
      createdAt: DateTime.now(),       // เพิ่มตรงนี้
    ));

    debtNameCtrl.clear();
    debtAmountCtrl.clear();
    debtInterestCtrl.clear();
    setState(() {});
  }


  void editDebt(int index) {
    final debt = debts[index];
    final nameCtrl = TextEditingController(text: debt.name);
    final amountCtrl = TextEditingController(text: debt.amount.toString());
    final interestCtrl = TextEditingController(text: debt.interest.toString());
    String tempType = debt.type;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("แก้ไขหนี้"),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "ชื่อหนี้")),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: tempType,
                      decoration: const InputDecoration(labelText: "ประเภทหนี้"),
                      items: debtTypes.map((type) => DropdownMenuItem(
                        value: type,
                        child: Text(type),
                      )).toList(),
                      onChanged: (val) => setDialogState(() => tempType = val!),
                    ),
                    const SizedBox(height: 10),
                    TextField(controller: amountCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "จำนวนเงิน")),
                    const SizedBox(height: 10),
                    TextField(controller: interestCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "ดอกเบี้ย (%)")),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("ยกเลิก")),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      debt.name = nameCtrl.text;
                      debt.amount = double.tryParse(amountCtrl.text) ?? 0;
                      debt.interest = double.tryParse(interestCtrl.text) ?? 0;
                      debt.type = tempType;
                    });
                    Navigator.pop(context);
                  },
                  child: const Text("บันทึก"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void deleteDebt(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("ยืนยันการลบ"),
        content: Text("คุณแน่ใจหรือไม่ว่าต้องการลบ '${debts[index].name}'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("ยกเลิก")),
          ElevatedButton(
            onPressed: () {
              setState(() => debts.removeAt(index));
              Navigator.pop(context);
            },
            child: const Text("ลบ"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("บลาๆๆๆๆ")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: currentStep == 1 ? buildIncomeStep() : buildDebtStep(),
      ),
    );
  }

  Widget buildIncomeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("กรุณาใส่รายรับของคุณ", style: TextStyle(fontSize: 20)),
        const SizedBox(height: 20),
        TextField(
    controller: incomeCtrl,
    keyboardType: TextInputType.number,
    inputFormatters: [
    FilteringTextInputFormatter.digitsOnly, // รับเฉพาะตัวเลข
    ],
    decoration: InputDecoration(
    labelText: "รายรับ / เดือน",
    errorText: incomeError ? "กรุณากรอกจำนวนเงิน" : null,
    ),
    ),
        const SizedBox(height: 20),
        ElevatedButton(onPressed: addIncome, child: const Text("Next")),
      ],
    );
  }

  Widget buildDebtStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("ระบุหนี้ของคุณ", style: TextStyle(fontSize: 20)),
        const SizedBox(height: 15),

        // ชื่อหนี้
        TextField(
          controller: debtNameCtrl,
          decoration: InputDecoration(
            labelText: "ชื่อหนี้",
            errorText: debtNameError ? "กรุณากรอกชื่อหนี้" : null,
          ),
        ),
        const SizedBox(height: 10),

        // ประเภทหนี้ Dropdown
        DropdownButtonFormField<String>(
          value: selectedDebtType,
          decoration: const InputDecoration(labelText: "ประเภทหนี้"),
          items: debtTypes.map((type) => DropdownMenuItem(
            value: type,
            child: Text(type),
          )).toList(),
          onChanged: (val) => setState(() => selectedDebtType = val!),
        ),
        const SizedBox(height: 10),

        // จำนวนเงิน
        TextField(
          controller: debtAmountCtrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: "จำนวนเงิน",
            errorText: debtAmountError ? "กรุณากรอกจำนวนเงิน" : null,
          ),
        ),
        const SizedBox(height: 10),

        // ดอกเบี้ย
        TextField(
          controller: debtInterestCtrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: "ดอกเบี้ย (%)",
            errorText: debtInterestError ? "กรุณากรอกดอกเบี้ย" : null,
          ),
        ),
        const SizedBox(height: 10),

        ElevatedButton(onPressed: addDebt, child: const Text("เพิ่มหนี้")),
        const SizedBox(height: 20),
        const Text("รายการหนี้ของคุณ:", style: TextStyle(fontWeight: FontWeight.bold)),

        Expanded(
          child: ListView.builder(
            itemCount: debts.length,
            itemBuilder: (context, index) {
              final debt = debts[index];

              return ListTile(
                title: Text(debt.name),
                subtitle: Text(
                  "ประเภท: ${debt.type} | ดอกเบี้ย: ${debt.interest}% | "
                      "สร้างเมื่อ: ${debt.createdAt.day}/${debt.createdAt.month}/${debt.createdAt.year} "
                      "${debt.createdAt.hour}:${debt.createdAt.minute.toString().padLeft(2,'0')}",
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Edit
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => editDebt(index),
                    ),
                    // Delete
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text("ยืนยันการลบ"),
                            content: Text("คุณแน่ใจว่าจะลบหนี้ '${debt.name}' หรือไม่?"),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text("ยกเลิก"),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  setState(() => debts.removeAt(index));
                                  Navigator.pop(context);
                                },
                                child: const Text("ลบ"),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ElevatedButton(
              onPressed: () => setState(() => currentStep = 1),
              child: const Text("ย้อนกลับ"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => DashboardPage(incomes: incomes, debts: debts)),
                );
              },
              child: const Text("ไปหน้าสรุป"),
            ),
          ],
        ),
      ],
    );
  }

}
