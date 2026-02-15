import '../../../auth/presentation/auth_manager.dart';
import '../../domain/models/transaction_request.dart';
import '../../data/services/transaction_service.dart';

import '../../domain/models/budget_overview.dart';
import '../../data/services/budget_service.dart';
import 'category_transactions_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

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

  Future<void> createTransaction(TransactionRequest transaction) async {
    await TransactionService().createTransaction(transaction);
  }

  List<BudgetOverview> _budgetItems = [];
  double _totalIncome = 42000; // Mocked for now
  double _totalExpense = 0;
  double _totalSavings = 0;

  @override
  void initState() {
    super.initState();
    _loadBudgetData();
  }

  Future<void> _loadBudgetData() async {
    final data = await _fetchApiData();
    data.sort((a, b) => a.budgetName.compareTo(b.budgetName));

    double expense = 0;
    double savings = 0;
    for (var item in data) {
      if (item.budgetName == 'Saving') {
        savings += item.amount;
      } else {
        expense += item.amount;
      }
    }

    final double income = await _budgetService.getIncomeAmount();

    if (!mounted) return;
    setState(() {
      _budgetItems = data;
      _totalExpense = expense;
      _totalSavings = savings;
      _totalIncome = income;
    });
  }

  // --- Task 4 Integration ---
  Future<void> _saveTransaction(TransactionRequest request) async {
    try {
      await TransactionService().createTransaction(request);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('บันทึกรายการสำเร็จ')));
      _loadBudgetData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
    }
  }

  // --- Popups ---

  void _showAddTransactionDialog() {
    final TextEditingController amountCtrl = TextEditingController(
      text: "0.00",
    );
    final TextEditingController descCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now();
    BudgetOverview? selectedCategory = _budgetItems.isNotEmpty
        ? _budgetItems.first
        : null;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            backgroundColor: Colors.white,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Column(
                        children: [
                          Text(
                            'เพิ่มรายการใหม่',
                            style: GoogleFonts.kanit(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'บันทึกรายจ่ายของคุณ',
                            style: TextStyle(
                              color: Colors.black45,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(
                            Icons.close,
                            color: Colors.black45,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // หมวดหมู่
                  Text(
                    'หมวดหมู่',
                    style: GoogleFonts.kanit(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFF2D955F),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<BudgetOverview>(
                        isExpanded: true,
                        value: selectedCategory,
                        icon: const Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.black45,
                        ),
                        items: _budgetItems.map((item) {
                          return DropdownMenuItem(
                            value: item,
                            child: Row(
                              children: [
                                Icon(
                                  _getCategoryIcon(item.budgetName),
                                  size: 20,
                                  color: _getCategoryColor(item.budgetName),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  item.budgetName,
                                  style: GoogleFonts.kanit(fontSize: 15),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) =>
                            setDialogState(() => selectedCategory = val),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // จำนวนเงิน
                  Text(
                    'จำนวนเงิน (฿)',
                    style: GoogleFonts.kanit(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.kanit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(
                        Icons.currency_bitcoin,
                        color: Color(0xFF2D955F),
                        size: 20,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.black12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.black12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // วันที่
                  Text(
                    'วันที่',
                    style: GoogleFonts.kanit(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
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
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            DateFormat(
                              'MM/dd/yyyy HH:mm A',
                            ).format(selectedDate),
                            style: GoogleFonts.kanit(fontSize: 15),
                          ),
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 18,
                            color: Colors.black87,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // คำอธิบาย
                  Text(
                    'คำอธิบาย (ไม่บังคับ)',
                    style: GoogleFonts.kanit(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: descCtrl,
                    maxLength: 128,
                    decoration: InputDecoration(
                      hintText: 'เช่น ค่าอาหารกลางวัน',
                      hintStyle: GoogleFonts.kanit(
                        color: Colors.black26,
                        fontSize: 14,
                      ),
                      counterText: '${descCtrl.text.length}/128',
                      counterStyle: const TextStyle(
                        color: Colors.black26,
                        fontSize: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.black12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.black12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    onChanged: (text) => setDialogState(() {}),
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2D955F),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        final amt = double.tryParse(amountCtrl.text);
                        if (amt != null &&
                            amt > 0 &&
                            selectedCategory != null) {
                          final req = TransactionRequest(
                            categoryId: int.parse(selectedCategory!.categoryId),
                            amount: amt,
                            transactionDate: selectedDate,
                            description: descCtrl.text,
                            budgetId: selectedCategory!.budgetId,
                          );
                          _saveTransaction(req);
                          Navigator.pop(context);
                        }
                      },
                      child: Text(
                        'บันทึกรายการ',
                        style: GoogleFonts.kanit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAdjustBudgetDialog(int index) {
    final item = _budgetItems[index];
    final TextEditingController controller = TextEditingController(
      text: item.limitBudget.toInt().toString(),
    );

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final currentInput = double.tryParse(controller.text) ?? 0;
          final remaining = currentInput - item.amount;
          final isOver = remaining < 0;

          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            backgroundColor: Colors.white,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(
                          'ปรับงบประมาณ',
                          style: GoogleFonts.kanit(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: const Icon(
                              Icons.close,
                              color: Colors.black45,
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'กำหนดงบประมาณสำหรับหมวดหมู่นี้',
                      style: TextStyle(color: Colors.black45, fontSize: 13),
                    ),
                    const SizedBox(height: 32),

                    // Item Info
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _getCategoryColor(
                              item.budgetName,
                            ).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _getCategoryIcon(item.budgetName),
                            color: _getCategoryColor(item.budgetName),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.budgetName,
                              style: GoogleFonts.kanit(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'ใช้ไปแล้ว ฿${NumberFormat('#,###').format(item.amount)}',
                              style: const TextStyle(
                                color: Colors.black45,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'งบประมาณ (฿)',
                        style: GoogleFonts.kanit(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildRoundBtn(Icons.remove, () {
                          final current = double.tryParse(controller.text) ?? 0;
                          if (current >= 1000) {
                            setDialogState(
                              () => controller.text = (current - 1000)
                                  .toInt()
                                  .toString(),
                            );
                          }
                        }),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            height: 56,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.black12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: TextField(
                                controller: controller,
                                textAlign: TextAlign.center,
                                keyboardType: TextInputType.number,
                                style: GoogleFonts.kanit(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                                onChanged: (_) => setDialogState(() {}),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  prefixIcon: Icon(
                                    Icons.currency_bitcoin,
                                    color: Color(0xFF2D955F),
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        _buildRoundBtn(Icons.add, () {
                          final current = double.tryParse(controller.text) ?? 0;
                          setDialogState(
                            () => controller.text = (current + 1000)
                                .toInt()
                                .toString(),
                          );
                        }),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Quick selection
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'เลือกจำนวนด่วน',
                        style: GoogleFonts.kanit(
                          fontSize: 13,
                          color: Colors.black45,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [1000, 5000, 10000, 20000, 50000].map((val) {
                          final isSelected = currentInput == val;
                          return GestureDetector(
                            onTap: () => setDialogState(
                              () => controller.text = val.toString(),
                            ),
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF2D955F)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.transparent
                                      : Colors.black12,
                                ),
                              ),
                              child: Text(
                                '฿${NumberFormat('#,###').format(val)}',
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black54,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Status
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'สถานะ',
                          style: TextStyle(color: Colors.black45, fontSize: 13),
                        ),
                        Text(
                          isOver
                              ? 'เกินงบ ฿${NumberFormat('#,###').format(remaining.abs())}'
                              : 'เหลือ ฿${NumberFormat('#,###').format(remaining)}',
                          style: GoogleFonts.kanit(
                            fontSize: 13,
                            color: isOver
                                ? const Color(0xFFEB5757)
                                : const Color(0xFF2D955F),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: currentInput > 0
                            ? (item.amount / currentInput).clamp(0, 1)
                            : 0,
                        minHeight: 8,
                        backgroundColor: const Color(0xFFF1F3F4),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isOver
                              ? const Color(0xFFEB5757)
                              : const Color(0xFF2D955F),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF8F9FA),
                              foregroundColor: Colors.black87,
                              elevation: 0,
                              padding: const EdgeInsets.all(16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: const BorderSide(color: Colors.black12),
                              ),
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              'ยกเลิก',
                              style: GoogleFonts.kanit(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2D955F),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.all(16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () {
                              final newLimit = double.tryParse(controller.text);
                              if (newLimit != null) {
                                _budgetService
                                    .updateBudgetLimit(
                                      item.budgetId ?? item.categoryId,
                                      newLimit,
                                    )
                                    .then((_) {
                                      _loadBudgetData();
                                      Navigator.pop(context);
                                    });
                              }
                            },
                            child: Text(
                              'บันทึก',
                              style: GoogleFonts.kanit(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRoundBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black12),
        ),
        child: Icon(icon, size: 20, color: Colors.black54),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double totalBudget = _budgetItems.fold(
      0.0,
      (sum, item) => sum + item.limitBudget,
    );
    final double remainingTotal = totalBudget - _totalExpense;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopHeader(),
              const SizedBox(height: 24),
              _buildSummaryCard(totalBudget, _totalExpense, remainingTotal),
              const SizedBox(height: 24),
              _buildHorizontalStats(),
              const SizedBox(height: 32),
              _buildCategoryListHeader(),
              const SizedBox(height: 16),
              ..._budgetItems.asMap().entries.map(
                (entry) => _buildCategoryItem(entry.value, entry.key),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTransactionDialog,
        backgroundColor: const Color(0xFF2D955F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, color: Colors.white, size: 32),
      ),
    );
  }

  Widget _buildTopHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'งบประมาณต่อเดือน',
          style: GoogleFonts.kanit(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1A1A1A),
          ),
        ),
        GestureDetector(
          onTap: () async {
            await AuthManager.clearToken();
            if (mounted) {
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil('/', (route) => false);
            }
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.logout, size: 24, color: Colors.black87),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(double total, double spent, double remaining) {
    final bool isOverBudget = remaining < 0;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'งบประมาณรวมที่ตั้งไว้',
                      style: GoogleFonts.kanit(
                        color: Colors.black45,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '฿',
                          style: GoogleFonts.kanit(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          NumberFormat('#,###').format(total),
                          style: GoogleFonts.kanit(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          '.00',
                          style: TextStyle(color: Colors.black26, fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isOverBudget
                                ? const Color(0xFFFF5252).withOpacity(0.1)
                                : const Color(0xFF2D955F).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isOverBudget ? 'เกินงบ' : 'ในงบ',
                            style: GoogleFonts.kanit(
                              color: isOverBudget
                                  ? const Color(0xFFFF5252)
                                  : const Color(0xFF2D955F),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'เหลือ ฿${NumberFormat('#,###').format(remaining.abs())}',
                          style: GoogleFonts.kanit(
                            color: isOverBudget
                                ? const Color(0xFFFF5252)
                                : Colors.black45,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _buildDonutChart(total, spent),
            ],
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: _budgetItems
                .map(
                  (item) => _buildSummaryLegend(
                    _getCategoryColor(item.budgetName),
                    item.budgetName,
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDonutChart(double total, double spent) {
    final double percent = total > 0 ? (spent / total).clamp(0, 1) : 0;
    return Container(
      width: 100,
      height: 100,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 100,
            height: 100,
            child: CircularProgressIndicator(
              value: percent,
              strokeWidth: 12,
              backgroundColor: const Color(0xFFF1F3F4),
              valueColor: AlwaysStoppedAnimation<Color>(
                percent > 1.0
                    ? const Color(0xFFEB5757)
                    : const Color(0xFF00E676),
              ),
            ),
          ),
          Text(
            '${(percent * 100).toInt()}%',
            style: GoogleFonts.kanit(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryLegend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.kanit(color: Colors.black54, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildHorizontalStats() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildStatCard(
            'รายรับ',
            '฿${NumberFormat('#,###').format(_totalIncome)}',
            '',
            const Color(0xFFE8F5E9),
            const Color(0xFF2D955F),
            Icons.trending_up,
            showTrend: false,
          ),
          const SizedBox(width: 16),
          _buildStatCard(
            'รายจ่าย',
            '฿${NumberFormat('#,###').format(_totalExpense)}',
            '+8% จากเดือนก่อน',
            const Color(0xFFFFEBEE),
            const Color(0xFFEB5757),
            Icons.trending_down,
          ),
          const SizedBox(width: 16),
          _buildStatCard(
            'เงินออม',
            '฿${NumberFormat('#,###').format(_totalSavings)}',
            '-3% จากเดือนก่อน',
            const Color(0xFFE3F2FD),
            const Color(0xFF1565C0),
            Icons.savings_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String amount,
    String trend,
    Color bgColor,
    Color textColor,
    IconData icon, {
    bool showTrend = true,
  }) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.kanit(color: Colors.black45, fontSize: 12),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: textColor),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            amount,
            style: GoogleFonts.kanit(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          if (showTrend)
            Text(
              trend,
              style: GoogleFonts.kanit(
                fontSize: 10,
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryListHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'รายละเอียดหมวดหมู่',
          style: GoogleFonts.kanit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        Text(
          'ดูทั้งหมด',
          style: GoogleFonts.kanit(
            fontSize: 14,
            color: Colors.black45,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryItem(BudgetOverview item, int index) {
    final budgeted = item.limitBudget;
    final spent = item.amount;
    final remaining = budgeted - spent;
    final isOverBudget = remaining < 0;
    final percentage = budgeted > 0 ? (spent / budgeted).clamp(0.0, 1.0) : 0.0;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CategoryTransactionsScreen(
              categoryId: int.parse(item.categoryId),
              categoryName: item.budgetName,
              categoryColor: _getCategoryColor(item.budgetName),
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black.withOpacity(0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(item.budgetName).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getCategoryIcon(item.budgetName),
                    color: _getCategoryColor(item.budgetName),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.budgetName,
                        style: GoogleFonts.kanit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'ใช้ไป ฿${NumberFormat('#,###').format(spent)}',
                        style: const TextStyle(
                          color: Colors.black45,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => _showAdjustBudgetDialog(index),
                  child: Text(
                    'แก้ไข',
                    style: GoogleFonts.kanit(color: Colors.black45),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: percentage,
                minHeight: 8,
                backgroundColor: const Color(0xFFF1F3F4),
                valueColor: AlwaysStoppedAnimation<Color>(
                  isOverBudget
                      ? const Color(0xFFEB5757)
                      : _getCategoryColor(item.budgetName),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isOverBudget
                      ? 'เกินงบ ฿${NumberFormat('#,###').format(remaining.abs())}'
                      : 'เหลือ ฿${NumberFormat('#,###').format(remaining)}',
                  style: GoogleFonts.kanit(
                    fontSize: 13,
                    color: isOverBudget
                        ? const Color(0xFFEB5757)
                        : const Color(0xFF2D955F),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'จาก ฿${NumberFormat('#,###').format(budgeted)}',
                  style: const TextStyle(fontSize: 13, color: Colors.black26),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String name) {
    switch (name) {
      case 'Shopping':
        return const Color(0xFFFF9100);
      case 'Food':
        return const Color(0xFFEB5757);
      case 'Transport':
        return const Color(0xFF00B0FF);
      case 'Bills':
        return const Color(0xFF2979FF);
      case 'Entertainment':
        return const Color(0xFFFF9100);
      case 'Health':
        return const Color(0xFF00BFA5);
      case 'Saving':
        return const Color(0xFF2D955F);
      default:
        return const Color(0xFF546E7A);
    }
  }

  IconData _getCategoryIcon(String name) {
    switch (name) {
      case 'Shopping':
        return Icons.shopping_bag_outlined;
      case 'Food':
        return Icons.restaurant_outlined;
      case 'Transport':
        return Icons.directions_car_outlined;
      case 'Bills':
        return Icons.receipt_long_outlined;
      case 'Entertainment':
        return Icons.videogame_asset_outlined;
      case 'Health':
        return Icons.medical_services_outlined;
      case 'Saving':
        return Icons.savings_outlined;
      default:
        return Icons.category_outlined;
    }
  }
}
