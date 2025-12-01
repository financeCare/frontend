import 'package:financeCare/models/debtType_response.dart';
import 'package:financeCare/models/debt_request.dart';
import 'package:financeCare/models/debt_response.dart';
import 'package:financeCare/models/repaymentType_response.dart';
import 'package:financeCare/models/transaction_request.dart';
import 'package:financeCare/services/category_service.dart';
import 'package:financeCare/services/debt_service.dart';
import 'package:financeCare/services/transaction_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/finance_item.dart';
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


  final TextEditingController incomeCtrl = TextEditingController();
  List<FinanceItem> incomes = [];

  final TextEditingController debtNameCtrl = TextEditingController();
  final TextEditingController debtAmountCtrl = TextEditingController();
  final TextEditingController debtInterestCtrl = TextEditingController();
  final TextEditingController debtStartDateCtrl = TextEditingController();
  final TextEditingController debtEndDateCtrl = TextEditingController();
  final TextEditingController debtPriorityCtrl = TextEditingController();

  List<DebtTypeResponse> debtTypeList = [];
  List<RepaymentTypeResponse> repaymentTypeList = [];
  List<String> debtType = [];
  List<String> repaymentType = [];
  String? selectedDebtType;
  String? selectedRepaymentType;
  List<FinanceItem> debts = [];
  int selectedRepaymentTypeId = 0;
  int selectedDebtTypeId = 0;

  bool incomeError = false;
  bool debtNameError = false;
  bool debtAmountError = false;
  bool debtInterestError = false;

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
        createdAt: d.startDate, 
      );
    }).toList();
  }

  Future<void> _loadIncomeData() async {
    try {
      final incomeItems = await categoryService
          .mapCategoryIncomeToFinanceItem();
      print("Income Items: $incomeItems");

      if (incomeItems.isEmpty) {
        print("No income categories found.");
      }

      if (mounted) {
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
        })
        .catchError((error) {
          print('Error fetching categories: $error');
        });
    incomeCtrl.clear();
    setState(() {
      currentStep = 2;
    });
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
    }
  }
  void editDebt(int index) async {
    final debt = debts[index];

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
                      fetchDebt();
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

          TextField(
            controller: incomeCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "ระบุหนี้ของคุณ",
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 20),

                TextField(
                  controller: debtNameCtrl,
                  decoration: InputDecoration(
                    labelText: "ชื่อหนี้",
                    border: const OutlineInputBorder(),
                    errorText: debtNameError ? "กรุณากรอกชื่อหนี้" : null,
                  ),
                ),
                const SizedBox(height: 15),

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

                DropdownButtonFormField<String>(
                  value: selectedRepaymentType,
                  decoration: const InputDecoration(
                    labelText: "ประเภทหนี้",
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

                TextField(
                  controller: debtAmountCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: "จำนวนเงิน",
                    border: const OutlineInputBorder(),
                    errorText: debtAmountError ? "กรุณากรอกจำนวนเงิน" : null,
                  ),
                ),
                const SizedBox(height: 15),

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
                ),
                const SizedBox(height: 15),

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


                TextField(
                  controller: debtEndDateCtrl,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: "วันที่สิ้นสุด",
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
                        debtEndDateCtrl.text = picked.toIso8601String().split(
                          'T',
                        )[0];
                      });
                    }
                  },
                ),
                const SizedBox(height: 15),


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
