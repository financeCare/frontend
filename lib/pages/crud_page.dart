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

    // รายรับที่ผู้ใช้กรอกเอง
    final TextEditingController incomeCtrl = TextEditingController();
    List<FinanceItem> incomes = [];

    // เอารายรับ API ออก → ไม่ใช้แล้ว
    // List<FinanceItem> apiIncomes = [];

    // หนี้สิน
    final TextEditingController debtNameCtrl = TextEditingController();
    final TextEditingController debtAmountCtrl = TextEditingController();
    final TextEditingController debtInterestCtrl = TextEditingController();
    String selectedDebtType = debtTypes[0];
    List<FinanceItem> debts = [];

    bool incomeError = false;
    bool debtNameError = false;
    bool debtAmountError = false;
    bool debtInterestError = false;

    @override
    void initState() {
      super.initState();
    }

    void addIncome() {
      setState(() {
        incomeError = incomeCtrl.text.isEmpty;
      });

      if (incomeError) return;

      incomes.add(FinanceItem(
        name: "Manual Income",
        amount: double.tryParse(incomeCtrl.text) ?? 0,
        createdAt: DateTime.now(),
      ));

      incomeCtrl.clear();
      setState(() {
        currentStep = 2;
      });
    }

    void addDebt() {
      setState(() {
        debtNameError = debtNameCtrl.text.isEmpty;
        debtAmountError = debtAmountCtrl.text.isEmpty;
        debtInterestError = debtInterestCtrl.text.isEmpty;
      });

      if (debtNameError || debtAmountError || debtInterestError) return;

      if (double.tryParse(debtAmountCtrl.text) == null ||
          double.tryParse(debtInterestCtrl.text) == null) {
        return;
      }

      debts.add(FinanceItem(
        name: debtNameCtrl.text,
        amount: double.tryParse(debtAmountCtrl.text) ?? 0,
        interest: double.tryParse(debtInterestCtrl.text) ?? 0,
        type: selectedDebtType,
        createdAt: DateTime.now(),
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
                      if (double.tryParse(amountCtrl.text) == null ||
                          double.tryParse(interestCtrl.text) == null) {
                        return;
                      }
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
        appBar: AppBar(
          toolbarHeight: 80.0,
          title: Padding(
            padding: const EdgeInsets.only(top: 15.0),
            child: Image.asset(
              'assets/logo_finance_care.png',
              height: 80,
              errorBuilder: (context, error, stackTrace) {
                return Text(
                  'Finance Care',
                  style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                );
              },
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: Theme.of(context).primaryColor),
        ),

        body: Padding(
          padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20, top: 10),
          child: currentStep == 1 ? buildIncomeStep() : buildDebtStep(),
        ),
      );
    }

    Widget buildIncomeStep() {
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("กรุณาใส่รายรับ", style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 20),

            TextField(
              controller: incomeCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              decoration: InputDecoration(
                labelText: "รายรับ / เดือน",
                errorText: incomeError ? "กรุณากรอกจำนวนเงิน" : null,
              ),
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: addIncome,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text("Next"),
            ),
          ],
        ),
      );
    }

    Widget buildDebtStep() {
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
                    decoration: InputDecoration(
                      labelText: "ชื่อหนี้",
                      errorText: debtNameError ? "กรุณากรอกชื่อหนี้" : null,
                    ),
                  ),
                  const SizedBox(height: 10),

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

                  TextField(
                    controller: debtAmountCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: "จำนวนเงิน",
                      errorText: debtAmountError ? "กรุณากรอกจำนวนเงิน" : null,
                    ),
                  ),
                  const SizedBox(height: 10),

      TextField(
      controller: debtInterestCtrl,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
      labelText: "ดอกเบี้ย (%)",
      errorText: debtInterestError ? "กรุณากรอกดอกเบี้ย" : null,
      ),
      ),

      const SizedBox(height: 20), // 👈 เพิ่มระยะห่าง


                  ElevatedButton(
                    onPressed: addDebt,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                    ),
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
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          title: Text(debt.name, style: Theme.of(context).textTheme.titleMedium),
                          subtitle: Text(
                            "ประเภท: ${debt.type} | ยอดหนี้: ${debt.amount.toStringAsFixed(0)} | ดอกเบี้ย: ${debt.interest}%",
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit, color: Colors.blue.shade600),
                                onPressed: () => editDebt(index),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red.shade600),
                                onPressed: () {
                                  deleteDebt(index);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: () => setState(() => currentStep = 1),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade300,
                    foregroundColor: Colors.black87,
                  ),
                  child: const Text("ย้อนกลับ"),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => DashboardPage(incomes: incomes, debts: debts)),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("ไปหน้าสรุป"),
                ),
              ],
            ),
          ),
        ],
      );
    }
  }
