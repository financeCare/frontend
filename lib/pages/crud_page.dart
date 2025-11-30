import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/finance_item.dart';
import '../models/constants.dart';
import '../pages/dashboard_page.dart';

class CrudPage extends StatefulWidget {
  const CrudPage({super.key});

  @override
  State<CrudPage> createState() => _CrudPageState();
}

class _CrudPageState extends State<CrudPage> {
  int currentStep = 1;

  // รายรับ
  final TextEditingController incomeNameCtrl = TextEditingController();
  final TextEditingController incomeAmountCtrl = TextEditingController();
  List<FinanceItem> incomes = [];

  // หนี้
  final TextEditingController debtNameCtrl = TextEditingController();
  final TextEditingController debtAmountCtrl = TextEditingController();
  final TextEditingController debtInterestCtrl = TextEditingController();
  String selectedDebtType = debtTypes[0];
  List<FinanceItem> debts = [];

  // Errors
  bool incomeNameError = false;
  bool incomeAmountError = false;
  bool debtNameError = false;
  bool debtAmountError = false;
  bool debtInterestError = false;

  // -------------------- รายรับ --------------------
  void confirmAddIncome() {
    setState(() {
      incomeNameError = incomeNameCtrl.text.isEmpty;
      incomeAmountError = incomeAmountCtrl.text.isEmpty;
    });

    if (incomeNameError || incomeAmountError) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("ยืนยันการเพิ่มรายรับ"),
        content: Text("คุณต้องการเพิ่มรายรับ '${incomeNameCtrl.text}' จำนวน ${incomeAmountCtrl.text} บาท หรือไม่?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("ยกเลิก")),
          ElevatedButton(
            onPressed: () {
              double? amount = double.tryParse(incomeAmountCtrl.text);
              if (amount == null) return;

              setState(() {
                incomes.add(FinanceItem(
                  name: incomeNameCtrl.text,
                  amount: amount,
                  createdAt: DateTime.now(),
                ));
                incomeNameCtrl.clear();
                incomeAmountCtrl.clear();
              });

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("เพิ่มรายรับสำเร็จ")),
              );
            },
            child: const Text("ตกลง"),
          ),
        ],
      ),
    );
  }

  void deleteIncome(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("ยืนยันการลบ"),
        content: Text("คุณแน่ใจหรือไม่ว่าต้องการลบ '${incomes[index].name}'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("ยกเลิก")),
          ElevatedButton(
            onPressed: () {
              setState(() {
                incomes.removeAt(index);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("ลบรายรับสำเร็จ")),
              );
            },
            child: const Text("ลบ"),
          ),
        ],
      ),
    );
  }

  void editIncome(int index) {
    final item = incomes[index];
    final nameCtrl = TextEditingController(text: item.name);
    final amountCtrl = TextEditingController(text: item.amount.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("แก้ไขรายรับ"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "ชื่อรายรับ")),
            TextField(controller: amountCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "จำนวนเงิน")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("ยกเลิก")),
          ElevatedButton(
            onPressed: () {
              setState(() {
                item.name = nameCtrl.text;
                item.amount = double.tryParse(amountCtrl.text) ?? item.amount;
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("แก้ไขรายรับสำเร็จ")),
              );
            },
            child: const Text("บันทึก"),
          ),
        ],
      ),
    );
  }

  // -------------------- หนี้ --------------------
  void confirmAddDebt() {
    setState(() {
      debtNameError = debtNameCtrl.text.isEmpty;
      debtAmountError = debtAmountCtrl.text.isEmpty;
      debtInterestError = debtInterestCtrl.text.isEmpty;
    });

    if (debtNameError || debtAmountError || debtInterestError) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("ยืนยันการเพิ่มหนี้"),
        content: Text("คุณต้องการเพิ่มหนี้ '${debtNameCtrl.text}' จำนวน ${debtAmountCtrl.text} บาท ดอกเบี้ย ${debtInterestCtrl.text}% หรือไม่?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("ยกเลิก")),
          ElevatedButton(
            onPressed: () {
              double? amount = double.tryParse(debtAmountCtrl.text);
              double? interest = double.tryParse(debtInterestCtrl.text);
              if (amount == null || interest == null) return;

              setState(() {
                debts.add(FinanceItem(
                  name: debtNameCtrl.text,
                  amount: amount,
                  interest: interest,
                  type: selectedDebtType,
                  createdAt: DateTime.now(),
                ));
                debtNameCtrl.clear();
                debtAmountCtrl.clear();
                debtInterestCtrl.clear();
              });

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("เพิ่มหนี้สำเร็จ")),
              );
            },
            child: const Text("ตกลง"),
          ),
        ],
      ),
    );
  }

  void editDebt(int index) {
    final debt = debts[index];
    final nameCtrl = TextEditingController(text: debt.name);
    final amountCtrl = TextEditingController(text: debt.amount.toString());
    final interestCtrl = TextEditingController(text: debt.interest.toString());
    String tempType = debt.type;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("แก้ไขหนี้"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "ชื่อหนี้")),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: tempType,
                  decoration: const InputDecoration(labelText: "ประเภทหนี้"),
                  items: debtTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
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
                  debt.amount = double.tryParse(amountCtrl.text) ?? debt.amount;
                  debt.interest = double.tryParse(interestCtrl.text) ?? debt.interest;
                  debt.type = tempType;
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("แก้ไขหนี้สำเร็จ")),
                );
              },
              child: const Text("บันทึก"),
            ),
          ],
        ),
      ),
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("ลบหนี้สำเร็จ")),
              );
            },
            child: const Text("ลบ"),
          ),
        ],
      ),
    );
  }

  // -------------------- Build --------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(""),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: currentStep == 1 ? buildIncomeStep() : buildDebtStep(),
      ),
    );
  }

  Widget buildIncomeStep() {
    bool canAddIncome = incomeNameCtrl.text.isNotEmpty && incomeAmountCtrl.text.isNotEmpty;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Image.asset('assets/logo_finance_care.png', width: 150, height: 150, fit: BoxFit.cover),
          ),
          const SizedBox(height: 20),
          Text("กรุณาใส่รายรับ", style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 20),
          TextField(
            controller: incomeNameCtrl,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(labelText: "ชื่อรายรับ", errorText: incomeNameError ? "กรุณากรอกชื่อ" : null),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: incomeAmountCtrl,
            onChanged: (_) => setState(() {}),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(labelText: "จำนวนเงิน", errorText: incomeAmountError ? "กรุณากรอกจำนวนเงิน" : null),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(
                onPressed: canAddIncome ? confirmAddIncome : null,
                child: const Text("เพิ่มรายรับ"),
              ),
              ElevatedButton(
                onPressed: incomes.isNotEmpty ? () => setState(() => currentStep = 2) : null,
                child: const Text("ไปหน้าหนี้"),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text("รายรับของคุณ:", style: TextStyle(fontWeight: FontWeight.bold)),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: incomes.length,
            itemBuilder: (context, index) {
              final item = incomes[index];
              return Card(
                color: Colors.green.shade50,
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("${item.amount.toStringAsFixed(0)} บาท"),
                      IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => editIncome(index)),
                      IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => deleteIncome(index)),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget buildDebtStep() {
    bool canAddDebt = debtNameCtrl.text.isNotEmpty && debtAmountCtrl.text.isNotEmpty && debtInterestCtrl.text.isNotEmpty;
    bool canGoDashboard = incomes.isNotEmpty && debts.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("ระบุหนี้ของคุณ", style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 15),
                TextField(
                  controller: debtNameCtrl,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(labelText: "ชื่อหนี้", errorText: debtNameError ? "กรุณากรอกชื่อหนี้" : null),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: selectedDebtType,
                  decoration: const InputDecoration(labelText: "ประเภทหนี้"),
                  items: debtTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                  onChanged: (val) => setState(() => selectedDebtType = val!),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: debtAmountCtrl,
                  onChanged: (_) => setState(() {}),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(labelText: "จำนวนเงิน", errorText: debtAmountError ? "กรุณากรอกจำนวนเงิน" : null),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: debtInterestCtrl,
                  onChanged: (_) => setState(() {}),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(labelText: "ดอกเบี้ย (%)", errorText: debtInterestError ? "กรุณากรอกดอกเบี้ย" : null),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: canAddDebt ? confirmAddDebt : null,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade600, foregroundColor: Colors.white),
                  child: const Text("เพิ่มหนี้"),
                ),
                const SizedBox(height: 20),
                const Text("รายการหนี้ของคุณ:", style: TextStyle(fontWeight: FontWeight.bold)),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: debts.length,
                  itemBuilder: (context, index) {
                    final debt = debts[index];
                    return Card(
                      color: Colors.orange.shade50,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        title: Text(debt.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("ประเภท: ${debt.type} | ยอด: ${debt.amount.toStringAsFixed(0)} | ดอกเบี้ย: ${debt.interest}%"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => editDebt(index)),
                            IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => deleteDebt(index)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(onPressed: () => setState(() => currentStep = 1), child: const Text("ย้อนกลับ")),
                    ElevatedButton(
                      onPressed: canGoDashboard
                          ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => DashboardPage(incomes: incomes, debts: debts)),
                        );
                      }
                          : null,
                      child: const Text("ไปหน้าสรุป"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
