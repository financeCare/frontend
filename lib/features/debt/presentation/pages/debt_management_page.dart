import 'package:flutter_application_1/features/debt/domain/models/debt_type_response.dart';
import 'package:flutter_application_1/features/debt/domain/models/debt_dto.dart';
import 'package:flutter_application_1/features/debt/domain/models/debt_request.dart';
import 'package:flutter_application_1/features/debt/domain/models/debt_response.dart';
import 'package:flutter_application_1/features/debt/domain/models/repayment_type_response.dart';
import 'package:flutter_application_1/features/budget/data/services/category_service.dart';
import 'package:flutter_application_1/features/debt/data/services/debt_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AddDebtPage extends StatefulWidget {
  const AddDebtPage({super.key});

  @override
  State<AddDebtPage> createState() => _AddDebtPageState();
}

class _AddDebtPageState extends State<AddDebtPage> {
  final debtService = DebtService();
  final categoryService = CategoryService();

  List<DebtDto> debts = [];
  List<DebtDto> incomes =
      []; // Keep for compatibility if needed, though we won't use it much here

  List<String> debtType = [];
  List<DebtTypeResponse> debtTypeList = [];
  List<String> repaymentType = [];
  List<RepaymentTypeResponse> repaymentTypeList = [];

  final TextEditingController debtNameCtrl = TextEditingController();
  final TextEditingController debtAmountCtrl = TextEditingController();
  final TextEditingController debtInterestCtrl = TextEditingController();
  final TextEditingController debtStartDateCtrl = TextEditingController();
  final TextEditingController debtEndDateCtrl = TextEditingController();
  final TextEditingController debtPriorityCtrl = TextEditingController();
  final TextEditingController debtMinpaymentCtrl = TextEditingController();
  final TextEditingController debtDueDateCtrl = TextEditingController();

  String? selectedDebtType;
  String? selectedRepaymentType;
  int selectedDebtTypeId = 0;
  int selectedRepaymentTypeId = 0;
  int selectedDueDate = 0;

  bool debtNameError = false;
  bool debtAmountError = false;
  bool debtInterestError = false;

  bool get isDebtFormValid {
    return debtNameCtrl.text.isNotEmpty &&
        debtAmountCtrl.text.isNotEmpty &&
        debtInterestCtrl.text.isNotEmpty &&
        selectedDebtType != null &&
        selectedRepaymentType != null;
  }

  @override
  void initState() {
    super.initState();
    loadDebtTypeAndRepaymentType();
    fetchDebt();
  }

  Future<void> loadDebtTypeAndRepaymentType() async {
    try {
      debtTypeList = await debtService.getDebtType();
      repaymentTypeList = await debtService.getRepaymentType();
      setState(() {
        debtType = debtTypeList.map((e) => e.debtTypeName).toList();
        repaymentType = repaymentTypeList.map((e) => e.typeName).toList();
        if (debtType.isNotEmpty) selectedDebtType = debtType[0];
        if (repaymentType.isNotEmpty) selectedRepaymentType = repaymentType[0];
      });
    } catch (e) {
      if (mounted) Navigator.of(context).pushReplacementNamed('/');
    }
  }

  Future<void> fetchDebt() async {
    final List<DebtResponse> responses = await debtService.getAllDebt();
    setState(() {
      debts = mapDebtToDebtDto(responses);
    });
  }

  List<DebtDto> mapDebtToDebtDto(List<DebtResponse> debts) {
    return debts
        .map(
          (d) => DebtDto(
            id: d.debtId,
            name: d.debtName,
            amount: d.principalAmount,
            interest: d.interestRate,
            type: d.debtType.debtTypeName,
          ),
        )
        .toList();
  }

  void addDebt() async {
    setState(() {
      debtNameError = debtNameCtrl.text.isEmpty;
      debtAmountError = debtAmountCtrl.text.isEmpty;
      debtInterestError = debtInterestCtrl.text.isEmpty;
    });

    if (debtNameError || debtAmountError || debtInterestError) return;

    final double? amount = double.tryParse(debtAmountCtrl.text);
    final double? interest = double.tryParse(debtInterestCtrl.text);

    if (amount == null || interest == null) return;

    for (RepaymentTypeResponse rt in repaymentTypeList) {
      if (selectedRepaymentType == rt.typeName)
        selectedRepaymentTypeId = rt.typeId;
    }
    for (DebtTypeResponse dt in debtTypeList) {
      if (selectedDebtType == dt.debtTypeName)
        selectedDebtTypeId = dt.debtTypeId;
    }

    final debtRequest = DebtRequest(
      debtName: debtNameCtrl.text,
      principalAmount: amount,
      interestRate: interest,
      startDate: debtStartDateCtrl.text.isNotEmpty
          ? DateTime.parse(debtStartDateCtrl.text)
          : DateTime.now(),
      endDate: debtEndDateCtrl.text.isNotEmpty
          ? DateTime.parse(debtEndDateCtrl.text)
          : DateTime.now().add(const Duration(days: 365)),
      priority: int.tryParse(debtPriorityCtrl.text) ?? 0,
      debtTypeId: selectedDebtTypeId,
      repaymentTypeId: selectedRepaymentTypeId,
      isActive: true,
      minPayment: double.tryParse(debtMinpaymentCtrl.text) ?? 0,
      dueDay: int.tryParse(debtDueDateCtrl.text) ?? 1,
    );

    try {
      await debtService.createDebt(debtRequest);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("เพิ่มหนี้สำเร็จ")));
        Navigator.pop(context); // Go back to overview
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pushReplacementNamed('/');
    }
  }

  void editDebt(int index) async {
    final debt = debts[index];
    DebtResponse debtDetail;
    try {
      debtDetail = await debtService.getDebtDetail(debt.id);
    } catch (e) {
      if (mounted) Navigator.of(context).pushReplacementNamed('/');
      return;
    }

    final nameCtrl = TextEditingController(text: debtDetail.debtName);
    final amountCtrl = TextEditingController(
      text: debtDetail.principalAmount.toString(),
    );
    final interestCtrl = TextEditingController(
      text: debtDetail.interestRate.toString(),
    );
    final startDateCtrl = TextEditingController(
      text: debtDetail.startDate.toIso8601String().split('T')[0],
    );
    final endDateCtrl = TextEditingController(
      text: debtDetail.endDate.toIso8601String().split('T')[0],
    );
    final priorityCtrl = TextEditingController(
      text: debtDetail.priority.toString(),
    );

    String tempDebtType = debtDetail.debtType.debtTypeName;
    String tempRepaymentType = debtDetail.repaymentType.typeName;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("แก้ไขหนี้"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: "ชื่อหนี้"),
                ),
                DropdownButtonFormField<String>(
                  value: tempDebtType,
                  items: debtType
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) => setDialogState(() => tempDebtType = v!),
                  decoration: const InputDecoration(labelText: "ประเภทหนี้"),
                ),
                DropdownButtonFormField<String>(
                  value: tempRepaymentType,
                  items: repaymentType
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) =>
                      setDialogState(() => tempRepaymentType = v!),
                  decoration: const InputDecoration(labelText: "ประเภทการชำระ"),
                ),
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "จำนวนเงิน"),
                ),
                TextField(
                  controller: interestCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "ดอกเบี้ย (%)"),
                ),
                TextField(
                  controller: startDateCtrl,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: "วันที่เริ่มต้น",
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  onTap: () async {
                    DateTime? p = await showDatePicker(
                      context: context,
                      initialDate: debtDetail.startDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (p != null)
                      setDialogState(
                        () => startDateCtrl.text = p.toIso8601String().split(
                          'T',
                        )[0],
                      );
                  },
                ),
                TextField(
                  controller: endDateCtrl,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: "วันที่สิ้นสุด",
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  onTap: () async {
                    DateTime? p = await showDatePicker(
                      context: context,
                      initialDate: debtDetail.endDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (p != null)
                      setDialogState(
                        () => endDateCtrl.text = p.toIso8601String().split(
                          'T',
                        )[0],
                      );
                  },
                ),
                TextField(
                  controller: priorityCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "ลำดับความสำคัญ",
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("ยกเลิก"),
            ),
            ElevatedButton(
              onPressed: () async {
                final dAmount = double.tryParse(amountCtrl.text);
                final dInterest = double.tryParse(interestCtrl.text);
                final dPriority = int.tryParse(priorityCtrl.text);
                if (dAmount == null || dInterest == null || dPriority == null)
                  return;

                int typeId = debtTypeList
                    .firstWhere((e) => e.debtTypeName == tempDebtType)
                    .debtTypeId;
                int rTypeId = repaymentTypeList
                    .firstWhere((e) => e.typeName == tempRepaymentType)
                    .typeId;

                final updated = DebtRequest(
                  debtName: nameCtrl.text,
                  principalAmount: dAmount,
                  interestRate: dInterest,
                  startDate: DateTime.parse(startDateCtrl.text),
                  endDate: DateTime.parse(endDateCtrl.text),
                  priority: dPriority,
                  debtTypeId: typeId,
                  repaymentTypeId: rTypeId,
                  isActive: debtDetail.isActive,
                  minPayment: debtDetail.minPayment,
                  dueDay: debtDetail.dueDate ?? 1,
                );

                try {
                  await debtService.updateDebt(debt.id, updated);
                  fetchDebt();
                  if (mounted) Navigator.pop(context);
                } catch (e) {
                  if (mounted) Navigator.of(context).pushReplacementNamed('/');
                }
              },
              child: const Text("บันทึก"),
            ),
          ],
        ),
      ),
    );
  }

  void deleteDebt(int index) {
    final debt = debts[index];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("ยืนยันการลบ"),
        content: Text("ยืนยันการลบ '${debt.name}'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("ยกเลิก"),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await debtService.deleteDebt(debt.id);
                fetchDebt();
                if (mounted) Navigator.pop(context);
              } catch (e) {
                if (mounted) Navigator.of(context).pushReplacementNamed('/');
              }
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
        title: const Text("เพิ่มหนี้ใหม่"),
        backgroundColor: const Color(0xFF00796B),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "ระบุหนี้ของคุณ",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: debtNameCtrl,
              decoration: const InputDecoration(
                labelText: "ชื่อหนี้",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            DropdownButtonFormField<String>(
              value: selectedDebtType,
              items: debtType
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) => setState(() => selectedDebtType = v!),
              decoration: const InputDecoration(
                labelText: "ประเภทหนี้",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            DropdownButtonFormField<String>(
              value: selectedRepaymentType,
              items: repaymentType
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) => setState(() => selectedRepaymentType = v!),
              decoration: const InputDecoration(
                labelText: "ประเภทการชำระ",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: debtAmountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "จำนวนเงิน",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: debtInterestCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "ดอกเบี้ย (%)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: debtStartDateCtrl,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: "วันที่เริ่มต้น",
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.calendar_today),
              ),
              onTap: () async {
                DateTime? p = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (p != null)
                  setState(
                    () => debtStartDateCtrl.text = p.toIso8601String().split(
                      'T',
                    )[0],
                  );
              },
            ),
            const SizedBox(height: 15),
            TextField(
              controller: debtEndDateCtrl,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: "วันที่สิ้นสุด",
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.calendar_today),
              ),
              onTap: () async {
                DateTime? p = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 365)),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (p != null)
                  setState(
                    () => debtEndDateCtrl.text = p.toIso8601String().split(
                      'T',
                    )[0],
                  );
              },
            ),
            const SizedBox(height: 15),
            TextField(
              controller: debtPriorityCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "ลำดับความสำคัญ",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: debtMinpaymentCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "ชำระขั้นต่ำ",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: debtDueDateCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "วันที่ต้องชำระ (1-31)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: isDebtFormValid ? addDebt : null,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: const Color(0xFF00796B),
                foregroundColor: Colors.white,
              ),
              child: const Text("ยืนยันเพิ่มหนี้"),
            ),
            const SizedBox(height: 15),
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text("ยกเลิก"),
            ),
          ],
        ),
      ),
    );
  }
}
