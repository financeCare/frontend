import 'package:financeCare/models/category.dart';
import 'package:financeCare/models/debtType_response.dart';
import 'package:financeCare/models/debt_request.dart';
import 'package:financeCare/models/debt_response.dart';
import 'package:financeCare/models/repaymentType_response.dart';
import 'package:financeCare/models/transaction_request.dart';
import 'package:financeCare/models/transaction_response.dart';
import 'package:financeCare/services/category_service.dart';
import 'package:financeCare/services/debt_service.dart';
import 'package:financeCare/services/transaction_service.dart';
import 'package:financeCare/utils/config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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
  TransactionService transactionService = TransactionService();
  CategoryService categoryService = CategoryService();
  DebtService debtService = DebtService();
  final storage = FlutterSecureStorage();
  String? error;

  // รายรับที่ผู้ใช้กรอกเอง
  final TextEditingController incomeCtrl = TextEditingController();
  List<FinanceItem> debts = [];
  List<FinanceItem> incomes = [];



    // ชื่อหนี้
    final TextEditingController debtNameCtrl = TextEditingController();
    final TextEditingController debtAmountCtrl = TextEditingController();
    final TextEditingController debtInterestCtrl = TextEditingController();
    final TextEditingController debtStartDateCtrl = TextEditingController();
    final TextEditingController debtEndDateCtrl = TextEditingController();
    final TextEditingController debtPriorityCtrl = TextEditingController();
    final TextEditingController incomeNameCtrl = TextEditingController();



    List<DebtTypeResponse> debtTypeList = [];
    List<RepaymentTypeResponse> repaymentTypeList = [];
    List<String> debtType = [];
    List<String> repaymentType = [];
    String? selectedDebtType;
    String? selectedRepaymentType;
    int selectedRepaymentTypeId = 0;
    int selectedDebtTypeId = 0;

    bool incomeError = false;
    bool debtNameError = false;
    bool debtAmountError = false;
    bool debtInterestError = false;
    bool get isDebtFormValid {
      return debtNameCtrl.text.trim().isNotEmpty &&
          debtAmountCtrl.text.trim().isNotEmpty &&
          debtInterestCtrl.text.trim().isNotEmpty;
    }

  bool get isIncomeFormValid {
    return incomeCtrl.text.trim().isNotEmpty;
  }



  @override
  void initState() {
    super.initState();
    loadDebtTypeAndRepaymentType();
    fetchDebt();
  }

  Future<void> loadDebtTypeAndRepaymentType() async {
    try {
      final debt = await DebtService().getDebtType();
      final repayment = await DebtService().getRepaymentType();
      setState(() {
        debtTypeList = debt;
        repaymentTypeList = repayment;
        debtType = debt.map((e) => e.debtTypeName).toList();
        repaymentType = repayment.map((e) => e.typeName).toList();
        print("repayment Type : ${debtType}");
        print("repayment Type : ${repaymentType}");
        if (debtType.isNotEmpty) selectedDebtType = debtType.first;
        if (repaymentType.isNotEmpty)
          selectedRepaymentType = repaymentType.first;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
      });
    }
  }

  late Categories _categoryItems;

  void fetchDebt() async {
    final DebtResponseList = await DebtService().getAllDebt();
    setState(() {
      debts = mapDebtToFinanceItem(DebtResponseList);
    });
  }

  List<FinanceItem> mapDebtToFinanceItem(List<DebtResponse> debts) {
    return debts.map((d) {
      return FinanceItem(
        id: d.debtId,
        name: d.debtName,
        amount: d.principalAmount,
        interest: d.interestRate,
        type: d.debtType.debtTypeName,
        createdAt: d.startDate, // หรือ DateTime.now()
      );
    }).toList();
  }

  Future<void> _loadIncomeData() async {
    try {
      final incomeItems = await categoryService
          .mapCategoryIncomeToFinanceItem();
      print("Income Items: $incomeItems");

      // เช็คว่ามีรายการหรือไม่
      if (incomeItems.isEmpty) {
        print("No income categories found.");
      }

      if (mounted) {
        // ตรวจสอบว่า widget ยังอยู่บน tree
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DashboardPage(incomes: incomeItems, debts: debts),
          ),
        );
      }
    } catch (error) {
      print("Error loading income data: $error");
    }
  }

  void addIncome() async {
    setState(() {
      incomeError = incomeCtrl.text.isEmpty;
    });
    if (incomeError) return;

    final double incomeAmount = double.tryParse(incomeCtrl.text) ?? 0;
    print('income : ${incomeCtrl.text}');
    print('income parse : $incomeAmount');

    // เพิ่มลง list incomes เพื่อให้จำนวนรวมอัปเดต
    setState(() {
      incomes.add(FinanceItem(
        id: DateTime.now().millisecondsSinceEpoch, // id ชั่วคราว
        name: "รายรับที่เพิ่ม", // หรือใช้ incomeNameCtrl.text
        amount: incomeAmount,
        createdAt: DateTime.now(),
      ));
    });

    categoryService
        .getCategories()
        .then((categories) {
      for (var category in categories) {
        if (category.type == 'Income' &&
            category.categoryName == 'Salary') {
          transactionService.createTransaction(
            TransactionRequest(
              categoryId: category.categoryId,
              amount: incomeAmount,
              transactionDate: DateTime.now(),
              description: "Manual Salary Income",
            ),
          );
        }
      }
    }).catchError((error) {
      print('Error fetching categories: $error');
    });

    incomeCtrl.clear();
  }




// ฟังก์ชันแก้ไข
  void editIncome(int index) {
    final income = incomes[index];
    final controller = TextEditingController(text: income.amount.toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("แก้ไขรายรับ"),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: "จำนวนเงิน"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("ยกเลิก"),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  income.amount = double.tryParse(controller.text) ?? income.amount;
                });
                Navigator.pop(context);
              },
              child: const Text("บันทึก"),
            ),
          ],
        );
      },
    );
  }

// ฟังก์ชันลบ
  void deleteIncome(int index) {
    final income = incomes[index];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("ยืนยันการลบ"),
        content: Text("คุณแน่ใจว่าต้องการลบ '${income.name}'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("ยกเลิก"),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                incomes.removeAt(index);
              });
              Navigator.pop(context);
            },
            child: const Text("ลบ"),
          ),
        ],
      ),
    );
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

    if (amount == null || interest == null) {
      print("Invalid amount or interest");
      return;
    }
    for (RepaymentTypeResponse repaymentType in repaymentTypeList) {
      if (selectedRepaymentType == repaymentType.typeName) {
        selectedRepaymentTypeId = repaymentType.typeId;
      }
    }
    for (DebtTypeResponse debtTypeResponse in debtTypeList) {
      if (selectedDebtType == debtTypeResponse.debtTypeName) {
        selectedDebtTypeId = debtTypeResponse.debtTypeId;
      }
    }
    // สร้าง DebtRequest
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
      priority: debtPriorityCtrl.text.isNotEmpty
          ? int.tryParse(debtPriorityCtrl.text) ?? 0
          : 0,
      debtTypeId: selectedDebtTypeId,
      repaymentTypeId: selectedRepaymentTypeId,
      isActive: true,
    );

    try {
      await debtService.createDebt(debtRequest);
      fetchDebt();
      setState(() {
        // debts.add(
        //   FinanceItem(
        //     name: debtRequest.debtName,
        //     amount: debtRequest.principalAmount,
        //     interest: debtRequest.interestRate,
        //     type: selectedDebtType ?? '',
        //     createdAt: DateTime.now(),
        //   ),
        // );

        // ล้าง input fields
        debtNameCtrl.clear();
        debtAmountCtrl.clear();
        debtInterestCtrl.clear();
        debtStartDateCtrl.clear();
        debtEndDateCtrl.clear();
        debtPriorityCtrl.clear();
        selectedDebtTypeId = 0;
        selectedRepaymentTypeId = 0;
      });
    } catch (e) {
      print("Error creating debt: $e");
      // สามารถแสดง SnackBar แจ้งผู้ใช้ได้
    }
  }

  void editDebt(int index) async {
    final debt = debts[index];

    // ดึงรายละเอียดหนี้จาก backend
    DebtResponse debtResponse;
    try {
      debtResponse = await DebtService().getDebtDetail(debt.id);
    } catch (e) {
      print("Error fetching debt detail: $e");
      return;
    }

    final nameCtrl = TextEditingController(text: debtResponse.debtName);
    final amountCtrl = TextEditingController(
      text: debtResponse.principalAmount.toString(),
    );
    final interestCtrl = TextEditingController(
      text: debtResponse.interestRate.toString(),
    );
    final startDateCtrl = TextEditingController(
      text: debtResponse.startDate.toIso8601String().split('T')[0],
    );
    final endDateCtrl = TextEditingController(
      text: debtResponse.endDate.toIso8601String().split('T')[0],
    );
    final priorityCtrl = TextEditingController(
      text: debtResponse.priority.toString(),
    );

    String tempDebtType = debtResponse.debtType.debtTypeName;
    String tempRepaymentType = debtResponse.repaymentType.typeName;

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
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: "ชื่อหนี้"),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: tempDebtType,
                      decoration: const InputDecoration(
                        labelText: "ประเภทหนี้",
                      ),
                      items: debtType
                          .map(
                            (type) => DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        ),
                      )
                          .toList(),
                      onChanged: (val) =>
                          setDialogState(() => tempDebtType = val!),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: tempRepaymentType,
                      decoration: const InputDecoration(
                        labelText: "ประเภทการชำระ",
                      ),
                      items: repaymentType
                          .map(
                            (type) => DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        ),
                      )
                          .toList(),
                      onChanged: (val) =>
                          setDialogState(() => tempRepaymentType = val!),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: amountCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "จำนวนเงิน"),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: interestCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "ดอกเบี้ย (%)",
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: startDateCtrl,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: "วันที่เริ่มต้น",
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      onTap: () async {
                        DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: debtResponse.startDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setDialogState(
                                () => startDateCtrl.text = picked
                                .toIso8601String()
                                .split('T')[0],
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: endDateCtrl,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: "วันที่สิ้นสุด",
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      onTap: () async {
                        DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: debtResponse.endDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setDialogState(
                                () => endDateCtrl.text = picked
                                .toIso8601String()
                                .split('T')[0],
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 10),
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
                    final double? newAmount = double.tryParse(amountCtrl.text);
                    final double? newInterest = double.tryParse(
                      interestCtrl.text,
                    );
                    final int? newPriority = int.tryParse(priorityCtrl.text);

                    if (newAmount == null ||
                        newInterest == null ||
                        newPriority == null) {
                      print("Invalid input");
                      return;
                    }

                    int newDebtTypeId = debtTypeList
                        .firstWhere((e) => e.debtTypeName == tempDebtType)
                        .debtTypeId;
                    int newRepaymentTypeId = repaymentTypeList
                        .firstWhere((e) => e.typeName == tempRepaymentType)
                        .typeId;

                    final updatedDebt = DebtRequest(
                      debtName: nameCtrl.text,
                      principalAmount: newAmount,
                      interestRate: newInterest,
                      startDate: DateTime.parse(startDateCtrl.text),
                      endDate: DateTime.parse(endDateCtrl.text),
                      priority: newPriority,
                      debtTypeId: newDebtTypeId,
                      repaymentTypeId: newRepaymentTypeId,
                      isActive: debtResponse.isActive,
                    );

                    try {
                      await DebtService().updateDebt(debt.id, updatedDebt);
                      fetchDebt(); // refresh list
                      Navigator.pop(context);
                    } catch (e) {
                      print("Error updating debt: $e");
                    }
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

  FinanceItem findDebtById(int id) {
    print(debts);
    for (FinanceItem financeItem in debts) {
      if (financeItem.id == id) {
        return financeItem;
      }
    }
    throw Exception('not found debt id');
  }



  void deleteDebt(int index) {
    FinanceItem financeItem = debts[index];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("ยืนยันการลบ"),
        content: Text("คุณแน่ใจหรือไม่ว่าต้องการลบ '${financeItem.name}'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("ยกเลิก"),
          ),
          ElevatedButton(
            onPressed: () async {
              await DebtService().deleteDebt(financeItem.id);
              fetchDebt();
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
        automaticallyImplyLeading: false,
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
        padding: const EdgeInsets.only(
          left: 20,
          right: 20,
          bottom: 20,
          top: 10,
        ),
        child: currentStep == 1 ? buildIncomeStep() : buildDebtStep(),
      ),
    );
  }

  Widget buildIncomeStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "กรุณาใส่รายรับ",
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 20),

          // Input รายรับ
          TextField(
            controller: incomeCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: "รายรับ / เดือน",
              errorText: incomeError ? "กรุณากรอกจำนวนเงิน" : null,
            ),
            onChanged: (_) => setState(() {}), // อัปเดตปุ่ม
          ),

          const SizedBox(height: 20),


          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: isIncomeFormValid ? addIncome : null,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("เพิ่มรายรับ"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: incomes.fold<double>(0, (sum, item) => sum + item.amount) <= 0
                      ? null
                      : () {
                    setState(() {
                      currentStep = 2;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    backgroundColor: incomes.fold<double>(0, (sum, item) => sum + item.amount) <= 0
                        ? Colors.grey.shade400 // สีปุ่ม disabled
                        : Colors.deepOrange,    // สีปุ่มพร้อมกด (เด่นกว่าเทา)
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("ไปหน้าเพิ่มหนี้"),
                ),
              )
            ],
          )
,

          const SizedBox(height: 8),

          // แสดงจำนวนรายรับทั้งหมด
            Text(
              "รายรับทั้งหมด: ${FinanceItem.totalAmount(incomes).toStringAsFixed(0)} บาท",
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),

          const SizedBox(height: 20),

          // แสดงรายการรายรับที่เพิ่มแล้ว

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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "ระบุหนี้ของคุณ",
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 20),

                // ชื่อหนี้
                TextField(
                  controller: debtNameCtrl,
                  decoration: InputDecoration(
                    labelText: "ชื่อหนี้",
                    border: const OutlineInputBorder(),
                    errorText: debtNameError ? "กรุณากรอกชื่อหนี้" : null,
                  ),
                  onChanged: (_) => setState(() {}), // <-- เพิ่มบรรทัดนี้
                ),
                const SizedBox(height: 15),

                // ประเภทหนี้
                DropdownButtonFormField<String>(
                  value: selectedDebtType,
                  decoration: const InputDecoration(
                    labelText: "ประเภทหนี้",
                    border: OutlineInputBorder(),
                  ),
                  items: debtType
                      .map(
                        (type) =>
                            DropdownMenuItem(value: type, child: Text(type)),
                      )
                      .toList(),
                  onChanged: (val) => setState(() => selectedDebtType = val!),
                ),
                const SizedBox(height: 15),

                // ประเภทการชำระ
                DropdownButtonFormField<String>(
                  value: selectedRepaymentType,
                  decoration: const InputDecoration(
                    labelText: "ประเภทการชำระ",
                    border: OutlineInputBorder(),
                  ),
                  items: repaymentType
                      .map(
                        (type) =>
                            DropdownMenuItem(value: type, child: Text(type)),
                      )
                      .toList(),
                  onChanged: (val) =>
                      setState(() => selectedRepaymentType = val!),
                ),
                const SizedBox(height: 15),

                // จำนวนเงิน
                TextField(
                  controller: debtAmountCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: "จำนวนเงิน",
                    border: const OutlineInputBorder(),
                    errorText: debtAmountError ? "กรุณากรอกจำนวนเงิน" : null,
                  ),
                  onChanged: (_) => setState(() {}), // <-- เพิ่มบรรทัดนี้
                ),
                const SizedBox(height: 15),

                // ดอกเบี้ย
                TextField(
                  controller: debtInterestCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  decoration: InputDecoration(
                    labelText: "ดอกเบี้ย (%)",
                    border: const OutlineInputBorder(),
                    errorText: debtInterestError ? "กรุณากรอกดอกเบี้ย" : null,
                  ),
                  onChanged: (_) => setState(() {}), // <-- เพิ่มบรรทัดนี้
                ),
                const SizedBox(height: 15),

                // วันที่เริ่มต้น
                TextField(
                  controller: debtStartDateCtrl,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: "วันที่เริ่มต้น",
                    border: const OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  onTap: () async {
                    DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() {
                        debtStartDateCtrl.text = picked.toIso8601String().split(
                          'T',
                        )[0];
                      });
                    }
                  },
                ),
                const SizedBox(height: 15),

                // วันที่สิ้นสุด
                TextField(
                  controller: debtEndDateCtrl,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: "วันที่สิ้นสุด",
                    border: const OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  onTap: () async {
                    // ตรวจสอบว่ามีวันที่เริ่มต้นหรือยัง
                    DateTime startDate = DateTime.now();
                    if (debtStartDateCtrl.text.isNotEmpty) {
                      startDate = DateTime.parse(debtStartDateCtrl.text);
                    }

                    // วันสิ้นสุดต้องหลังวันเริ่มต้น 1 วัน
                    DateTime firstEndDate = startDate.add(const Duration(days: 1));

                    DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: firstEndDate, // เริ่มต้นที่วันถัดไป
                      firstDate: firstEndDate,   // ห้ามเลือกวันก่อนวันเริ่มต้น
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() {
                        debtEndDateCtrl.text = picked.toIso8601String().split('T')[0];
                      });
                    }
                  },
                ),


                const SizedBox(height: 15),

                // Priority
                TextField(
                  controller: debtPriorityCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: "ลำดับความสำคัญ",
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),

                // ปุ่มเพิ่มหนี้
                ElevatedButton(
                onPressed: isDebtFormValid ? addDebt : null, // <-- ถ้า false จะ disabled
    style: ElevatedButton.styleFrom(
    minimumSize: const Size(double.infinity, 48),
    backgroundColor: Theme.of(context).primaryColor,
    foregroundColor: Colors.white,
    ),
    child: const Text("เพิ่มหนี้"),
    ),

                const SizedBox(height: 20),

                const Text(
                  "รายการหนี้ของคุณ:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),

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
                        title: Text(
                          debt.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        subtitle: Text(
                          "ประเภท: ${debt.type} | ยอดหนี้: ${debt.amount.toStringAsFixed(0)} | ดอกเบี้ย: ${debt.interest}%",
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.edit,
                                color: Colors.blue.shade600,
                              ),
                              onPressed: () => editDebt(index),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.delete,
                                color: Colors.red.shade600,
                              ),
                              onPressed: () => deleteDebt(index),
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

        // ปุ่มย้อนกลับ / ไปหน้าสรุป
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16),
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
                onPressed: () async {
                  await _loadIncomeData();
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
