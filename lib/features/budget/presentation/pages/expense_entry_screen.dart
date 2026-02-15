import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/budget/data/services/budget_service.dart';
import 'package:flutter_application_1/features/budget/data/services/transaction_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../domain/models/budget_overview.dart';
import '../../domain/models/transaction_request.dart';

class ExpenseEntryScreen extends StatefulWidget {
  const ExpenseEntryScreen({super.key});

  @override
  State<ExpenseEntryScreen> createState() => _ExpenseEntryScreenState();
}

class _ExpenseEntryScreenState extends State<ExpenseEntryScreen> {
  final _budgetService = BudgetService();
  final _transactionService = TransactionService();
  final TextEditingController _amountController = TextEditingController(
    text: "0.00",
  );
  final TextEditingController _descriptionController = TextEditingController();

  List<BudgetOverview> _categories = [];
  BudgetOverview? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await _budgetService.getTransactionsOverview();
      if (!mounted) return;
      setState(() {
        _categories = cats;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading categories: $e");
      setState(() => _isLoading = false);
    }
  }

  IconData _getCategoryIcon(String name) {
    switch (name.toLowerCase()) {
      case 'food':
        return Icons.restaurant;
      case 'transport':
        return Icons.directions_bus;
      case 'health':
        return Icons.favorite;
      case 'shopping':
        return Icons.shopping_bag;
      case 'bills':
        return Icons.description;
      case 'entertainment':
        return Icons.electric_bolt;
      case 'saving':
        return Icons.savings;
      case 'other':
        return Icons.more_horiz;
      case 'extra income':
        return Icons.account_balance_wallet;
      default:
        return Icons.category;
    }
  }

  String _getCategoryThaiName(String name) {
    switch (name.toLowerCase()) {
      case 'food':
        return 'อาหาร';
      case 'transport':
        return 'ค่าเดินทาง';
      case 'health':
        return 'สุขภาพ';
      case 'shopping':
        return 'ช้อปปิ้ง';
      case 'bills':
        return 'ค่าบิล';
      case 'entertainment':
        return 'ความบันเทิง';
      case 'saving':
        return 'ออม';
      case 'other':
        return 'อื่น ๆ';
      case 'extra income':
        return 'รายได้เสริม';
      default:
        return name;
    }
  }

  Color _getCategoryColor(String name) {
    switch (name.toLowerCase()) {
      case 'food':
        return const Color(0xFF4285F4);
      case 'transport':
        return const Color(0xFF00CED1);
      case 'health':
        return const Color(0xFFF06292);
      case 'shopping':
        return const Color(0xFFBA68C8);
      case 'bills':
        return const Color(0xFF7986CB);
      case 'entertainment':
        return const Color(0xFFFFA726);
      case 'saving':
        return const Color(0xFF26A69A);
      case 'other':
        return const Color(0xFF78909C);
      case 'extra income':
        return const Color(0xFF8BC34A);
      default:
        return Colors.blueGrey;
    }
  }

  void _addAmount(double value) {
    double current = double.tryParse(_amountController.text) ?? 0;
    setState(() {
      _amountController.text = (current + value).toStringAsFixed(2);
    });
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _onSave() async {
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("กรุณาเลือกหมวดหมู่")));
      return;
    }
    double amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("กรุณาระบุจำนวนเงิน")));
      return;
    }

    setState(() => _isSaving = true);
    try {
      final req = TransactionRequest(
        categoryId: int.parse(_selectedCategory!.categoryId),
        amount: amount,
        transactionDate: _selectedDate,
        description: _descriptionController.text,
        budgetId: _selectedCategory!.budgetId,
      );
      await _transactionService.createTransaction(req);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("บันทึกรายการสำเร็จ")));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("เกิดข้อผิดพลาด: $e")));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "เพิ่มรายการ",
              style: GoogleFonts.kanit(
                color: Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "บันทึกรายจ่ายของคุณ",
              style: GoogleFonts.kanit(color: Colors.black45, fontSize: 13),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionLabel("หมวดหมู่"),
                  const SizedBox(height: 16),
                  _buildCategoryGrid(),
                  const SizedBox(height: 24),
                  _buildSectionLabel("จำนวนเงิน"),
                  const SizedBox(height: 16),
                  _buildAmountInput(),
                  const SizedBox(height: 12),
                  _buildPresetButtons(),
                  const SizedBox(height: 24),
                  _buildSectionLabel("วันที่ทำรายการ"),
                  const SizedBox(height: 16),
                  _buildDatePickerBox(),
                  const SizedBox(height: 24),
                  _buildSectionLabel("หมายเหตุ"),
                  const SizedBox(height: 16),
                  _buildNoteInput(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
      bottomNavigationBar: _buildConfirmButton(),
    );
  }

  Widget _buildSectionLabel(String text) {
    return RichText(
      text: TextSpan(
        text: text,
        style: GoogleFonts.kanit(
          color: Colors.black87,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        children: const [
          TextSpan(
            text: " *",
            style: TextStyle(color: Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        mainAxisExtent: 100,
      ),
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final cat = _categories[index];
        bool isSelected = _selectedCategory?.budgetId == cat.budgetId;
        Color color = _getCategoryColor(cat.budgetName);

        return GestureDetector(
          onTap: () => setState(() => _selectedCategory = cat),
          child: Column(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: isSelected ? color.withOpacity(0.1) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? color : Colors.grey.shade100,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getCategoryIcon(cat.budgetName),
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    if (isSelected)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Color(0xFF2ECC71),
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(2),
                          child: const Icon(
                            Icons.check,
                            size: 10,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _getCategoryThaiName(cat.budgetName),
                style: GoogleFonts.kanit(
                  fontSize: 11,
                  color: isSelected ? Colors.black87 : Colors.black54,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAmountInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Text(
            "฿",
            style: GoogleFonts.kanit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black26,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: GoogleFonts.kanit(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFBDBDBD),
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetButtons() {
    final presets = [100.0, 500.0, 1000.0, 5000.0];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: presets.map((val) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: val == 5000.0 ? 0 : 8),
            child: InkWell(
              onTap: () => _addAmount(val),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "+${val.toInt()}",
                  style: GoogleFonts.kanit(
                    fontSize: 14,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDatePickerBox() {
    return InkWell(
      onTap: _selectDate,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              DateFormat('MM/dd/yyyy').format(_selectedDate),
              style: GoogleFonts.kanit(fontSize: 16, color: Colors.black87),
            ),
            const Icon(Icons.calendar_month_outlined, color: Colors.black54),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: _descriptionController,
        maxLines: 4,
        style: GoogleFonts.kanit(fontSize: 15),
        decoration: InputDecoration(
          hintText: "เพิ่มรายละเอียด (ถ้ามี)",
          hintStyle: GoogleFonts.kanit(color: Colors.black26),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildConfirmButton() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ElevatedButton(
          onPressed: _isSaving ? null : _onSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFEB5757),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _isSaving ? "กำลังบันทึก..." : "ถัดไป",
                style: GoogleFonts.kanit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              if (!_isSaving) const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
