import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../domain/models/transaction_request.dart';
import '../../domain/models/budget_overview.dart';
import '../../domain/models/category.dart';
import '../../data/services/transaction_service.dart';
import '../../data/services/budget_service.dart';
import '../../data/services/category_service.dart';

class TransactionAddScreen extends StatefulWidget {
  final Map<String, String>? ocrData;

  const TransactionAddScreen({super.key, this.ocrData});

  @override
  State<TransactionAddScreen> createState() => _TransactionAddScreenState();
}

class _TransactionAddScreenState extends State<TransactionAddScreen> {
  final TransactionService _transactionService = TransactionService();
  final BudgetService _budgetService = BudgetService();
  final CategoryService _categoryService = CategoryService();
  
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  Categories? _selectedCategory;
  List<Categories> _allCategories = [];
  List<BudgetOverview> _budgetItems = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    if (widget.ocrData != null) {
      _applyOcrData();
    }
  }

  void _applyOcrData() {
    final amountStr = widget.ocrData!['amount']?.replaceAll(',', '') ?? '0.00';
    _amountController.text = amountStr;
    _descController.text = 'โอนให้: ${widget.ocrData!['receiver'] ?? '-'}';
    
    // Parse date if possible
    // For now keep current date or try to parse if format matches
  }

  Future<void> _loadData() async {
    try {
      final categories = await _categoryService.getCategories();
      final budgets = await _budgetService.getAmountInBudget();
      
      if (mounted) {
        setState(() {
          _allCategories = categories;
          _budgetItems = budgets;
          if (_allCategories.isNotEmpty) {
            _selectedCategory = _allCategories.first;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      print("DEBUG: Error loading data: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveTransaction() async {
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่มีหมวดหมู่ให้บันทึก (โปรดตรวจสอบข้อมูลบน Server)')),
      );
      return;
    }
    
    final amtText = _amountController.text;
    final amt = double.tryParse(amtText) ?? 0;
    if (amt <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาระบุจำนวนเงินที่มากกว่า 0')),
      );
      return;
    }

    // Try to find a budgetId for the selected category
    String? budgetId;
    try {
      final matchingBudget = _budgetItems.firstWhere(
        (b) => int.tryParse(b.categoryId) == _selectedCategory!.categoryId
      );
      budgetId = matchingBudget.budgetId;
    } catch (_) {
      // No active budget for this category
    }

    final request = TransactionRequest(
      categoryId: _selectedCategory!.categoryId,
      amount: amt,
      transactionDate: _selectedDate,
      description: _descController.text,
      budgetId: budgetId,
    );
    
    setState(() => _isSaving = true);
    
    try {
      await _transactionService.createTransaction(request);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('บันทึกรายการสำเร็จ')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAmountCard(),
                      const SizedBox(height: 32),
                      _buildInputLabel('วันที่ทำรายการ'),
                      _buildDatePicker(),
                      const SizedBox(height: 24),
                      _buildInputLabel('คำอธิบายเพิ่มเติม'),
                      _buildDescriptionField(),
                      const SizedBox(height: 48),
                      _buildSaveButton(),
                      const SizedBox(height: 100),
                    ],
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120.0,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF2D955F),
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'บันทึกรายการ',
          style: GoogleFonts.kanit(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2D955F), Color(0xFF4CB07D)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildAmountCard() {
    return Container(
      width: double.infinity,
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
        children: [
          Text(
            'จำนวนเงิน',
            style: GoogleFonts.kanit(
              color: Colors.black45,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _amountController,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            style: GoogleFonts.kanit(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2D955F),
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: '0.00',
              prefixText: '฿',
              prefixStyle: TextStyle(fontSize: 24, color: Colors.black26),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label,
        style: GoogleFonts.kanit(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF475569),
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (picked != null) {
          setState(() => _selectedDate = picked);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              DateFormat('dd MMMM yyyy').format(_selectedDate),
              style: GoogleFonts.kanit(fontSize: 16),
            ),
            const Icon(Icons.calendar_today, color: Color(0xFF2D955F), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionField() {
    return TextField(
      controller: _descController,
      maxLines: 3,
      style: GoogleFonts.kanit(),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        hintText: 'บันทึกความจำ หรือชื่อร้านค้า...',
        hintStyle: GoogleFonts.kanit(color: Colors.black26),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveTransaction,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2D955F),
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: const Color(0x662D955F),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: _isSaving
          ? const CircularProgressIndicator(color: Colors.white)
          : Text(
              'ยืนยันการบันทึก',
              style: GoogleFonts.kanit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
      ),
    );
  }

  Widget _getCategoryIcon(String name) {
    IconData icon;
    Color color;
    
    final lowerName = name.toLowerCase();
    if (lowerName.contains('food') || lowerName.contains('กิน') || lowerName.contains('อาหาร')) {
      icon = Icons.restaurant;
      color = Colors.orange;
    } else if (lowerName.contains('travel') || lowerName.contains('เดินทาง') || lowerName.contains('รถ')) {
      icon = Icons.directions_car;
      color = Colors.blue;
    } else if (lowerName.contains('saving') || lowerName.contains('ออม')) {
      icon = Icons.savings;
      color = Colors.green;
    } else if (lowerName.contains('bill') || lowerName.contains('น้ำ') || lowerName.contains('ไฟ')) {
      icon = Icons.receipt_long;
      color = Colors.purple;
    } else if (lowerName.contains('health') || lowerName.contains('ยา') || lowerName.contains('หมอ')) {
      icon = Icons.medical_services;
      color = Colors.red;
    } else {
      icon = Icons.category;
      color = Colors.grey;
    }
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }
}
