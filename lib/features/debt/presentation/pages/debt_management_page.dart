import 'package:flutter_application_1/features/debt/domain/models/debt_type_response.dart';
import 'package:flutter_application_1/features/debt/domain/models/debt_dto.dart';
import 'package:flutter_application_1/features/debt/domain/models/debt_request.dart';
import 'package:flutter_application_1/features/debt/domain/models/debt_response.dart';
import 'package:flutter_application_1/features/debt/domain/models/repayment_type_response.dart';
import 'package:flutter_application_1/features/budget/data/services/category_service.dart';
import 'package:flutter_application_1/features/debt/data/services/debt_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class MaxValueFormatter extends TextInputFormatter {
  final double max;
  MaxValueFormatter(this.max);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;
    final double? value = double.tryParse(newValue.text);
    if (value == null) return oldValue;
    if (value > max) {
      return TextEditingValue(
        text: max.toStringAsFixed(max == max.toInt() ? 0 : 2),
        selection: TextSelection.collapsed(offset: max.toString().length),
      );
    }
    return newValue;
  }
}

class AddDebtPage extends StatefulWidget {
  final DebtResponse? debtToEdit;
  const AddDebtPage({super.key, this.debtToEdit});

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
  List<DebtTypeResponse> filteredDebtTypeList = [];
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
  final TextEditingController searchDebtTypeCtrl = TextEditingController();

  int _currentStep = 1;
  String? selectedDebtType;
  String? selectedRepaymentType;
  int selectedDebtTypeId = 0;
  int selectedRepaymentTypeId = 0;

  bool debtNameError = false;
  bool debtAmountError = false;
  bool debtInterestError = false;
  bool debtStartDateError = false;
  bool debtEndDateError = false;
  bool debtDueDateError = false;

  Color get primaryColor => widget.debtToEdit != null
      ? const Color(0xFF2196F3)
      : const Color(0xFFEB5757);
  Color get lightPrimaryColor => widget.debtToEdit != null
      ? const Color(0xFFE3F2FD)
      : const Color(0xFFFFEBEE);
  Color get fadePrimaryColor => widget.debtToEdit != null
      ? const Color(0xFFE3F2FD).withOpacity(0.3)
      : const Color(0xFFFFEBEE).withOpacity(0.3);
  Color get successColor => widget.debtToEdit != null
      ? const Color(0xFF2196F3)
      : const Color(0xFFEB5757);

  bool get isDebtFormValid {
    return debtNameCtrl.text.isNotEmpty &&
        selectedDebtTypeId != 0 &&
        selectedRepaymentTypeId != 0;
  }

  bool get isAmountValid {
    return debtAmountCtrl.text.isNotEmpty && debtInterestCtrl.text.isNotEmpty;
  }

  bool get isTimelineValid {
    return debtStartDateCtrl.text.isNotEmpty &&
        debtEndDateCtrl.text.isNotEmpty &&
        debtDueDateCtrl.text.isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    loadDebtTypeAndRepaymentType();
    fetchDebt();
    if (widget.debtToEdit != null) {
      _fillEditData(widget.debtToEdit!);
    }
  }

  void _fillEditData(DebtResponse d) {
    debtNameCtrl.text = d.debtName;
    debtAmountCtrl.text = d.principalAmount.toString();
    debtInterestCtrl.text = d.interestRate.toString();
    debtStartDateCtrl.text = d.startDate.toIso8601String().split('T')[0];
    debtEndDateCtrl.text = d.endDate.toIso8601String().split('T')[0];
    debtPriorityCtrl.text = d.priority.toString();
    debtMinpaymentCtrl.text = d.minPayment.toString();
    debtDueDateCtrl.text = (d.dueDate ?? 1).toString();
    selectedDebtTypeId = d.debtType.debtTypeId;
    selectedRepaymentTypeId = d.repaymentType.typeId;
  }

  Future<void> loadDebtTypeAndRepaymentType() async {
    try {
      debtTypeList = await debtService.getDebtType();
      repaymentTypeList = await debtService.getRepaymentType();
      if (!mounted) return;
      setState(() {
        filteredDebtTypeList = debtTypeList;
        debtType = debtTypeList.map((e) => e.debtTypeName).toList();
        repaymentType = repaymentTypeList.map((e) => e.typeName).toList();
        if (debtTypeList.isNotEmpty)
          selectedDebtTypeId = debtTypeList[0].debtTypeId;
        if (repaymentTypeList.isNotEmpty) {
          selectedRepaymentTypeId = repaymentTypeList[0].typeId;
        }
      });
    } catch (e) {
      if (mounted) Navigator.of(context).pushReplacementNamed('/');
    }
  }

  Future<void> fetchDebt() async {
    final List<DebtResponse> responses = await debtService.getAllDebt();
    if (!mounted) return;
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

  void filterDebtTypes(String query) {
    setState(() {
      filteredDebtTypeList = debtTypeList
          .where(
            (type) =>
                type.debtTypeName.toLowerCase().contains(query.toLowerCase()),
          )
          .toList();
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

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกจำนวนเงินให้ถูกต้อง')),
      );
      return;
    }
    if (interest == null || interest < 0 || interest > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('อัตราดอกเบี้ยต้องอยู่ระหว่าง 0-100%')),
      );
      return;
    }

    final startDate = debtStartDateCtrl.text.isNotEmpty
        ? DateTime.parse(debtStartDateCtrl.text)
        : DateTime.now();
    final endDate = debtEndDateCtrl.text.isNotEmpty
        ? DateTime.parse(debtEndDateCtrl.text)
        : DateTime.now().add(const Duration(days: 365));

    if (endDate.isBefore(startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('วันที่สิ้นสุดต้องไม่มาก่อนวันที่เริ่มต้น')),
      );
      return;
    }

    final minPayment = double.tryParse(debtMinpaymentCtrl.text) ?? 0;
    if (minPayment > amount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ยอดชำระขั้นต่ำไม่ควรเกินเงินต้น')),
      );
      return;
    }

    final dueDay = int.tryParse(debtDueDateCtrl.text) ?? 1;
    if (dueDay < 1 || dueDay > 31) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('วันที่ครบกำหนดชำระต้องอยู่ระหว่าง 1-31')),
      );
      return;
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
      if (widget.debtToEdit != null) {
        await debtService.updateDebt(widget.debtToEdit!.debtId, debtRequest);
      } else {
        await debtService.createDebt(debtRequest);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.debtToEdit != null ? "แก้ไขหนี้สำเร็จ" : "เพิ่มหนี้สำเร็จ",
            ),
          ),
        );
        Navigator.pop(context, true); // Go back to overview
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
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    MaxValueFormatter(100),
                  ],
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
                    DateTime initial = DateTime.tryParse(startDateCtrl.text) ??
                        debtDetail.startDate;
                    DateTime? p = await showDatePicker(
                      context: context,
                      initialDate: initial,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (p != null) {
                      setDialogState(
                        () => startDateCtrl.text =
                            p.toIso8601String().split('T')[0],
                      );
                      // Adjust end date if needed
                      final end = DateTime.tryParse(endDateCtrl.text);
                      if (end != null && end.isBefore(p)) {
                        setDialogState(() => endDateCtrl.text = "");
                      }
                    }
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
                    DateTime start = DateTime.tryParse(startDateCtrl.text) ??
                        debtDetail.startDate;
                    DateTime initial = DateTime.tryParse(endDateCtrl.text) ??
                        debtDetail.endDate;
                    if (initial.isBefore(start)) initial = start;

                    DateTime? p = await showDatePicker(
                      context: context,
                      initialDate: initial,
                      firstDate: start,
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
      backgroundColor: const Color(0xFFF5F5F5), // Light grey background
      body: Stack(
        children: [
          // Header Background
          Container(
            height: 250,
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
          ),
          Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_currentStep == 1) _buildStep1(),
                          if (_currentStep == 2) _buildStep2(),
                          if (_currentStep == 3) _buildStep3(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              _buildBottomNav(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        bottom: 30,
      ),
      width: double.infinity,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  widget.debtToEdit != null ? 'แก้ไขหนี้' : 'เพิ่มหนี้ใหม่',
                  style: GoogleFonts.kanit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildStepper(),
        ],
      ),
    );
  }

  Widget _buildStepper() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          Row(
            children: [
              _stepNode(1, _currentStep >= 1),
              _stepLine(_currentStep >= 2),
              _stepNode(2, _currentStep >= 2),
              _stepLine(_currentStep >= 3),
              _stepNode(3, _currentStep >= 3),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _stepLabel("ข้อมูลหนี้", _currentStep == 1),
              _stepLabel("จำนวนเงิน", _currentStep == 2),
              _stepLabel("กำหนดเวลา", _currentStep == 3),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stepNode(int step, bool active) {
    bool done = _currentStep > step;
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: active ? Colors.white : Colors.white.withOpacity(0.3),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: done
            ? Icon(Icons.check, size: 16, color: primaryColor)
            : Text(
                step.toString(),
                style: GoogleFonts.kanit(
                  color: active ? primaryColor : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
      ),
    );
  }

  Widget _stepLine(bool active) {
    return Expanded(
      child: Container(
        height: 1,
        color: active ? Colors.white : Colors.white.withOpacity(0.3),
      ),
    );
  }

  Widget _stepLabel(String label, bool active) {
    return Text(
      label,
      style: GoogleFonts.kanit(
        fontSize: 12,
        color: active ? Colors.white : Colors.white.withOpacity(0.7),
        fontWeight: active ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "ข้อมูลหนี้",
          style: GoogleFonts.kanit(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          "ชื่อและประเภท",
          style: GoogleFonts.kanit(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 24),
        Text("ชื่อหนี้", style: GoogleFonts.kanit(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: debtNameCtrl,
          decoration: InputDecoration(
            hintText: "เช่น บัตรเครดิต SCB",
            prefixIcon: const Icon(Icons.credit_card),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF28af60),
                width: 1.5,
              ),
            ),
            errorText: debtNameError ? "กรุณากรอกชื่อหนี้" : null,
          ),
          onChanged: (value) {
            if (debtNameError && value.isNotEmpty) {
              setState(() => debtNameError = false);
            }
          },
        ),
        const SizedBox(height: 24),
        Text(
          "ประเภทหนี้",
          style: GoogleFonts.kanit(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: searchDebtTypeCtrl,
          onChanged: filterDebtTypes,
          decoration: InputDecoration(
            hintText: "ค้นหาประเภทหนี้...",
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF28af60),
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildDebtTypeGrid(),
        const SizedBox(height: 24),
        Text(
          "ประเภทการชำระ",
          style: GoogleFonts.kanit(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        _buildRepaymentTypeGrid(),
      ],
    );
  }

  Widget _buildDebtTypeGrid() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.antiAlias,
      child: GridView.builder(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 1.0,
          crossAxisSpacing: 0,
          mainAxisSpacing: 0,
        ),
        itemCount: filteredDebtTypeList.length,
        itemBuilder: (context, index) {
          final type = filteredDebtTypeList[index];
          final isSelected = selectedDebtTypeId == type.debtTypeId;
          return GestureDetector(
            onTap: () => setState(() => selectedDebtTypeId = type.debtTypeId),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade100, width: 0.5),
                color: isSelected ? primaryColor : Colors.white,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _getDebtTypeIcon(type.debtTypeName),
                    color: isSelected ? Colors.white : Colors.grey,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    type.debtTypeName,
                    style: GoogleFonts.kanit(
                      fontSize: 10,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _getDebtTypeIcon(String name) {
    name = name.toLowerCase();
    if (name.contains('personal') || name.contains('ส่วนบุคคล')) {
      return Icons.wallet;
    }
    if (name.contains('credit card') || name.contains('บัตรเครดิต')) {
      return Icons.credit_card;
    }
    if (name.contains('car') || name.contains('รถยนต์')) {
      return Icons.directions_car;
    }
    if (name.contains('home') ||
        name.contains('บ้าน') ||
        name.contains('ที่อยู่อาศัย')) {
      return Icons.home;
    }
    if (name.contains('education') || name.contains('การศึกษา')) {
      return Icons.school;
    }
    if (name.contains('medical') || name.contains('รักษาพยาบาล')) {
      return Icons.medical_services;
    }
    if (name.contains('business') || name.contains('ธุรกิจ')) {
      return Icons.business_center;
    }
    if (name.contains('emergency') || name.contains('ฉุกเฉิน')) {
      return Icons.notification_important;
    }
    if (name.contains('line of credit') ||
        name.contains('od') ||
        name.contains('เบิกเกินบัญชี')) {
      return Icons.show_chart;
    }
    if (name.contains('family') || name.contains('ครอบครัว')) {
      return Icons.people;
    }
    if (name.contains('installment') || name.contains('ผ่อนสินค้า')) {
      return Icons.shopping_bag;
    }
    if (name.contains('tax') || name.contains('ภาษี'))
      return Icons.receipt_long;
    if (name.contains('loan shark') || name.contains('นอกระบบ')) {
      return Icons.warning_amber_rounded;
    }
    if (name.contains('student') || name.contains('กยศ')) {
      return Icons.history_edu;
    }
    return Icons.more_horiz;
  }

  Widget _buildRepaymentTypeGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.0,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: repaymentTypeList.length,
      itemBuilder: (context, index) {
        final type = repaymentTypeList[index];
        final isSelected = selectedRepaymentTypeId == type.typeId;
        return GestureDetector(
          onTap: () => setState(() => selectedRepaymentTypeId = type.typeId),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? primaryColor : Colors.grey.shade200,
                width: 2,
              ),
              color: isSelected
                  ? lightPrimaryColor.withOpacity(0.3)
                  : Colors.grey.shade50,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected ? primaryColor : Colors.grey.shade200,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getRepaymentTypeIcon(type.typeName),
                        color: isSelected ? Colors.white : Colors.grey.shade600,
                        size: 20,
                      ),
                    ),
                    Icon(
                      isSelected
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: isSelected ? primaryColor : Colors.grey.shade300,
                      size: 24,
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  _getRepaymentTypeTitle(type.typeName),
                  style: GoogleFonts.kanit(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? primaryColor : Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _getRepaymentTypeDesc(type.typeName),
                  style: GoogleFonts.kanit(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getRepaymentTypeTitle(String name) {
    name = name.toLowerCase();
    if (name.contains('full') || name.contains('จ่ายครั้งเดียว')) {
      return 'จ่ายครั้งเดียว';
    }
    if (name.contains('installment') || name.contains('ผ่อนชำระ')) {
      return 'ผ่อนชำระ';
    }
    if (name.contains('revolving') || name.contains('จ่ายขั้นต่ำ')) {
      return 'จ่ายขั้นต่ำ / หมุนเวียน';
    }
    if (name.contains('bullet') || name.contains('จ่ายดอกเบี้ย')) {
      return 'จ่ายดอกเบี้ย + เงินต้นท้าย';
    }
    return name;
  }

  IconData _getRepaymentTypeIcon(String name) {
    name = name.toLowerCase();
    if (name.contains('full') ||
        name.contains('lump') ||
        name.contains('จ่ายครั้งเดียว')) {
      return Icons.attach_money;
    }
    if (name.contains('installment') ||
        name.contains('emi') ||
        name.contains('ผ่อนชำระ')) {
      return Icons.credit_card_outlined;
    }
    if (name.contains('revolving') ||
        name.contains('credit line') ||
        name.contains('จ่ายขั้นต่ำ')) {
      return Icons.autorenew;
    }
    if (name.contains('bullet') || name.contains('จ่ายดอกเบี้ย')) {
      return Icons.track_changes;
    }
    return Icons.payment;
  }

  String _getRepaymentTypeDesc(String name) {
    name = name.toLowerCase();
    if (name.contains('full') || name.contains('จ่ายครั้งเดียว')) {
      return 'ชำระเต็มจำนวนในครั้งเดียว';
    }
    if (name.contains('installment') || name.contains('ผ่อนชำระ')) {
      return 'แบ่งจ่ายเป็นงวดเท่ากัน';
    }
    if (name.contains('revolving') || name.contains('จ่ายขั้นต่ำ')) {
      return 'จ่ายขั้นต่ำแล้วหมุนยอด';
    }
    if (name.contains('bullet') || name.contains('จ่ายดอกเบี้ย')) {
      return 'จ่ายดอกเบี้ยรายงวด ปิดเงินต้นตอนจบ';
    }
    return '';
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "จำนวนเงิน",
          style: GoogleFonts.kanit(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          "เงินต้นและดอกเบี้ย",
          style: GoogleFonts.kanit(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 24),
        _buildInputField(
          "จำนวนเงินต้น",
          debtAmountCtrl,
          Icons.money,
          "฿",
          errorText: debtAmountError ? "กรุณากรอกจำนวนเงิน" : null,
        ),
        const SizedBox(height: 16),
        _buildInputField(
          "อัตราดอกเบี้ย (ต่อปี)",
          debtInterestCtrl,
          Icons.percent,
          "%",
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            MaxValueFormatter(100),
          ],
        ),
        const SizedBox(height: 16),
        _buildInputField(
          "ชำระขั้นต่ำ / เดือน",
          debtMinpaymentCtrl,
          Icons.payments,
          "฿",
        ),
        const SizedBox(height: 16),
        _buildInputField(
          "ลำดับความสำคัญ",
          debtPriorityCtrl,
          Icons.list,
          "0 = สำคัญที่สุด",
        ),
        const SizedBox(height: 24),
        _buildInterestEstimateBox(),
      ],
    );
  }

  Widget _buildInputField(
    String label,
    TextEditingController ctrl,
    IconData icon,
    String suffix, {
    String? errorText,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.kanit(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            prefixIcon: Icon(icon),
            suffixText: suffix,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: primaryColor, width: 1.5),
            ),
            errorText: errorText ??
                (ctrl == debtInterestCtrl && debtInterestError
                    ? "กรุณากรอกดอกเบี้ย (0-100%)"
                    : ctrl == debtDueDateCtrl && debtDueDateError
                        ? "กรุณากรอกวันที่ 1-31"
                        : null),
          ),
          onChanged: (value) {
            setState(() {
              if (ctrl == debtAmountCtrl && value.isNotEmpty) {
                debtAmountError = false;
              } else if (ctrl == debtInterestCtrl && value.isNotEmpty) {
                double? rate = double.tryParse(value);
                if (rate != null && rate >= 0 && rate <= 100) {
                  debtInterestError = false;
                }
              } else if (ctrl == debtDueDateCtrl && value.isNotEmpty) {
                int? day = int.tryParse(value);
                if (day != null && day >= 1 && day <= 31) {
                  debtDueDateError = false;
                }
              }
            });
          },
        ),
      ],
    );
  }

  Widget _buildInterestEstimateBox() {
    double interest = 0;
    final amount = double.tryParse(debtAmountCtrl.text) ?? 0;
    final rate = double.tryParse(debtInterestCtrl.text) ?? 0;
    interest = (amount * (rate / 100)) / 12;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.help_outline, color: primaryColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "ดอกเบี้ยโดยประมาณ / เดือน",
                  style: GoogleFonts.kanit(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  "฿${interest.toStringAsFixed(2)}",
                  style: GoogleFonts.kanit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "กำหนดเวลา",
          style: GoogleFonts.kanit(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          "วันที่ชำระ",
          style: GoogleFonts.kanit(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 24),
        _buildDatePickerField(
          "วันที่เริ่มต้น",
          debtStartDateCtrl,
          errorText: debtStartDateError ? "กรุณาเลือกวันที่เริ่มต้น" : null,
        ),
        const SizedBox(height: 16),
        _buildDatePickerField(
          "วันที่สิ้นสุด",
          debtEndDateCtrl,
          firstDate: debtStartDateCtrl.text.isNotEmpty
              ? DateTime.tryParse(debtStartDateCtrl.text)
              : null,
          errorText: debtEndDateError ? "กรุณาเลือกวันที่สิ้นสุด" : null,
        ),
        const SizedBox(height: 16),
        _buildInputField(
          "วันที่ต้องชำระ (1-31)",
          debtDueDateCtrl,
          Icons.calendar_month,
          "",
          errorText: debtDueDateError ? "กรุณากรอกวันที่ต้องชำระ" : null,
        ),
        const SizedBox(height: 24),
        _buildDurationBox(),
        const SizedBox(height: 24),
        _buildSummaryBox(),
      ],
    );
  }

  Widget _buildDatePickerField(String label, TextEditingController ctrl,
      {DateTime? firstDate, String? errorText}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.kanit(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          readOnly: true,
          onTap: () => _selectDate(context, ctrl, firstDate: firstDate),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.calendar_today),
            suffixIcon: const Icon(Icons.event),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: primaryColor, width: 1.5),
            ),
            errorText: errorText,
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate(
    BuildContext context,
    TextEditingController ctrl, {
    DateTime? firstDate,
  }) async {
    DateTime initial = DateTime.now();
    if (ctrl.text.isNotEmpty) {
      initial = DateTime.tryParse(ctrl.text) ?? DateTime.now();
    }

    // Ensure initialDate is within range
    if (firstDate != null && initial.isBefore(firstDate)) {
      initial = firstDate;
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate ?? DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      if (!mounted) return;
      setState(() {
        ctrl.text = picked.toIso8601String().split('T')[0];
        if (ctrl == debtStartDateCtrl) {
          debtStartDateError = false;
          // If end date is now invalid, clear it
          final end = DateTime.tryParse(debtEndDateCtrl.text);
          if (end != null && end.isBefore(picked)) {
            debtEndDateCtrl.clear();
          }
        } else if (ctrl == debtEndDateCtrl) {
          debtEndDateError = false;
        }
      });
    }
  }

  Widget _buildDurationBox() {
    int months = 0;
    if (debtStartDateCtrl.text.isNotEmpty && debtEndDateCtrl.text.isNotEmpty) {
      final start = DateTime.parse(debtStartDateCtrl.text);
      final end = DateTime.parse(debtEndDateCtrl.text);
      months = ((end.year - start.year) * 12) + end.month - start.month;
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: lightPrimaryColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.calendar_month, color: primaryColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "ระยะเวลา",
                  style: GoogleFonts.kanit(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  "$months เดือน ($months งวด)",
                  style: GoogleFonts.kanit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBox() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: primaryColor.withOpacity(0.1)),
        borderRadius: BorderRadius.circular(24),
        color: lightPrimaryColor.withOpacity(0.3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: lightPrimaryColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check, color: primaryColor, size: 14),
              ),
              const SizedBox(width: 8),
              Text(
                "สรุปข้อมูลหนี้",
                style: GoogleFonts.kanit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _summaryItem("ชื่อหนี้", debtNameCtrl.text)),
              Expanded(
                child: _summaryItem(
                  "ประเภท",
                  debtTypeList.any((e) => e.debtTypeId == selectedDebtTypeId)
                      ? debtTypeList
                            .firstWhere(
                              (e) => e.debtTypeId == selectedDebtTypeId,
                            )
                            .debtTypeName
                      : "",
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _summaryItem("จำนวนเงิน", "฿${debtAmountCtrl.text}"),
              ),
              Expanded(
                child: _summaryItem("ดอกเบี้ย", "${debtInterestCtrl.text}%"),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _summaryItem(
                  "การชำระ",
                  repaymentTypeList.any(
                        (e) => e.typeId == selectedRepaymentTypeId,
                      )
                      ? repaymentTypeList
                            .firstWhere(
                              (e) => e.typeId == selectedRepaymentTypeId,
                            )
                            .typeName
                      : "",
                ),
              ),
              Expanded(
                child: _summaryItem(
                  "ขั้นต่ำ/เดือน",
                  "฿${debtMinpaymentCtrl.text}",
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.kanit(fontSize: 12, color: Colors.grey)),
        Text(
          value,
          style: GoogleFonts.kanit(fontSize: 14, fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          if (_currentStep > 1)
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: OutlinedButton(
                  onPressed: () => setState(() => _currentStep--),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: primaryColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chevron_left, color: primaryColor),
                      Text(
                        "ย้อนกลับ",
                        style: GoogleFonts.kanit(color: primaryColor),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  if (_currentStep == 1) {
                    debtNameError = debtNameCtrl.text.isEmpty;
                    if (!debtNameError) _currentStep++;
                  } else if (_currentStep == 2) {
                    debtAmountError = debtAmountCtrl.text.isEmpty;
                    debtInterestError = debtInterestCtrl.text.isEmpty;
                    if (!debtAmountError && !debtInterestError) _currentStep++;
                  } else if (_currentStep == 3) {
                    debtStartDateError = debtStartDateCtrl.text.isEmpty;
                    debtEndDateError = debtEndDateCtrl.text.isEmpty;
                    debtDueDateError = debtDueDateCtrl.text.isEmpty;
                    if (!debtStartDateError &&
                        !debtEndDateError &&
                        !debtDueDateError) {
                      addDebt();
                    }
                  }
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _currentStep == 3
                        ? (widget.debtToEdit != null
                              ? "บันทึกการแก้ไข"
                              : "สร้างรายการหนี้")
                        : "ถัดไป",
                    style: GoogleFonts.kanit(fontWeight: FontWeight.bold),
                  ),
                  if (_currentStep < 3) const Icon(Icons.chevron_right),
                  if (_currentStep == 3) const SizedBox(width: 8),
                  if (_currentStep == 3) const Icon(Icons.check, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
