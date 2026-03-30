import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/models/transaction_response.dart';
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
  final TransactionResponse? transactionToEdit;

  const TransactionAddScreen({super.key, this.ocrData, this.transactionToEdit});

  @override
  State<TransactionAddScreen> createState() => _TransactionAddScreenState();
}

class _TransactionAddScreenState extends State<TransactionAddScreen> {
  final TransactionService _transactionService = TransactionService();
  final BudgetService _budgetService = BudgetService();
  final CategoryService _categoryService = CategoryService();
  
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _receiverController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  Categories? _selectedCategory;
  List<Categories> _allCategories = [];
  List<BudgetOverview> _budgetItems = [];
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isIncome = false;

  // ฟิลด์ใหม่สำหรับรองรับข้อมูลสลิป/OCR
  String? _senderBank;
  String? _receiverName;
  String? _imagePath;
  int? _slipId;


  @override
  void initState() {
    super.initState();
    _loadData();
    if (widget.transactionToEdit != null) {
      _applyEditData();
    } else if (widget.ocrData != null) {
      _applyOcrData();
    }
  }

  void _applyEditData() {
    final tx = widget.transactionToEdit!;
    _amountController.text = tx.amount.toString();
    _descController.text = tx.description;
    _receiverController.text = tx.receiverName ?? '';
    _selectedDate = tx.transactionDate;
    _senderBank = tx.senderBank;
    _receiverName = tx.receiverName;
    _imagePath = tx.imagePath;
    _slipId = tx.slipId;
    _isIncome = tx.category.type == 'Income';
  }

  void _applyOcrData() {
    final amountStr = widget.ocrData!['amount']?.replaceAll(',', '') ?? '0.00';
    _amountController.text = amountStr;
    
    // ใช้ description จาก OCR ถ้ามี
    final ocrDesc = widget.ocrData!['description'];
    if (ocrDesc != null && ocrDesc.isNotEmpty) {
      _descController.text = ocrDesc;
    }
    
    _receiverController.text = widget.ocrData!['receiver'] ?? '';
    
    // เก็บข้อมูลเพิ่มเติมจาก OCR
    _senderBank = widget.ocrData!['sender_bank'];
    _receiverName = widget.ocrData!['receiver'];
    _imagePath = widget.ocrData!['image_path'];
    _slipId = widget.ocrData!['slip_id'] != null 
        ? int.tryParse(widget.ocrData!['slip_id']!) 
        : null;

    // Parse date if possible
    final dateStr = widget.ocrData!['date'];
    if (dateStr != null) {
      try {
        // คาดหวัง format YYYY-MM-DD หรือ ISO
        _selectedDate = _normalizeDate(DateTime.parse(dateStr));
      } catch (_) {
        // ถ้า parse ไม่ได้ให้ใช้เวลาปัจจุบัน
      }
    }
  }

  DateTime _normalizeDate(DateTime date) {
    if (date.year > 2500) {
      return DateTime(
        date.year - 543,
        date.month,
        date.day,
        date.hour,
        date.minute,
        date.second,
      );
    }
    return date;
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
            if (widget.transactionToEdit != null) {
              _selectedCategory = _allCategories.firstWhere(
                (c) => c.categoryId == widget.transactionToEdit!.category.categoryId,
                orElse: () => _allCategories.first,
              );
            } else if (widget.ocrData != null && widget.ocrData!['category_id'] != null) {
              final ocrCategoryId = int.tryParse(widget.ocrData!['category_id']!);
              _selectedCategory = _allCategories.firstWhere(
                (c) => c.categoryId == ocrCategoryId,
                orElse: () => _allCategories.first,
              );
            } else {
              // Default to first Expense category if available
              _selectedCategory = _allCategories.firstWhere(
                (c) => c.type == 'Expense',
                orElse: () => _allCategories.first,
              );
            }
            _isIncome = _selectedCategory?.type == 'Income';
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
      senderBank: _senderBank,
      receiverName: _receiverController.text.isNotEmpty ? _receiverController.text : _receiverName,
      imagePath: _imagePath,
      slipId: _slipId,
    );
    
    setState(() => _isSaving = true);
    
    try {
      if (widget.transactionToEdit != null) {
        await _transactionService.updateTransaction(widget.transactionToEdit!.transactionId, request);
      } else {
        await _transactionService.createTransaction(request);
      }
      
      if (mounted) {
        _showCustomSuccessSnackBar(widget.transactionToEdit != null ? 'แก้ไขรายการเรียบร้อยแล้ว' : 'บันทึกรายการเรียบร้อยแล้ว');
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

  void _showCustomSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        duration: const Duration(seconds: 2),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF2D955F),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'สำเร็จ!',
                      style: GoogleFonts.kanit(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      message,
                      style: GoogleFonts.kanit(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
                      _buildTypeSelection(),
                      const SizedBox(height: 24),
                      _buildInputLabel('หมวดหมู่'),
                      _buildCategoryGrid(),
                      const SizedBox(height: 32),
                      _buildInputLabel('วันที่ทำรายการ'),
                      _buildDatePicker(),
                      if (_senderBank != null && _senderBank!.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _buildInputLabel('ธนาคารต้นทาง'),
                        _buildSenderBankInfo(),
                      ],
                      const SizedBox(height: 24),
                      _buildInputLabel('ชื่อผู้รับ (ถ้ามี)'),
                      _buildReceiverField(),
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
          widget.transactionToEdit != null ? 'แก้ไขรายการ' : 'บันทึกรายการ',
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
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
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
    return _buildTextField(_descController, 'บันทึกความจำ หรือชื่อร้านค้า...', 3);
  }

  Widget _buildReceiverField() {
    return _buildTextField(_receiverController, 'เช่น ชื่อผู้รับโอน หรือชื่อร้านค้า...', 1);
  }

  Widget _buildTextField(TextEditingController controller, String hint, int maxLines) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: GoogleFonts.kanit(),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        hintText: hint,
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

  Widget _buildSenderBankInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          const Icon(Icons.account_balance, color: Color(0xFF64748B), size: 20),
          const SizedBox(width: 12),
          Text(
            _senderBank!,
            style: GoogleFonts.kanit(
              fontSize: 16,
              color: const Color(0xFF334155),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
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
    IconData iconData;
    Color color;
    
    switch (name) {
      case 'Shopping':
        iconData = Icons.shopping_bag_outlined;
        color = const Color(0xFFFF9100);
        break;
      case 'Food':
        iconData = Icons.restaurant_outlined;
        color = const Color(0xFFEB5757);
        break;
      case 'Transport':
        iconData = Icons.directions_car_outlined;
        color = const Color(0xFF00B0FF);
        break;
      case 'Bills':
        iconData = Icons.receipt_long_outlined;
        color = const Color(0xFF2979FF);
        break;
      case 'Entertainment':
        iconData = Icons.videogame_asset_outlined;
        color = const Color(0xFFFF9100);
        break;
      case 'Health':
        iconData = Icons.medical_services_outlined;
        color = const Color(0xFF00BFA5);
        break;
      case 'Saving':
        iconData = Icons.savings_outlined;
        color = const Color(0xFF2D955F);
        break;
      default:
        iconData = Icons.category_outlined;
        color = const Color(0xFF546E7A);
    }
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(iconData, color: color, size: 24),
    );
  }

  Widget _buildTypeSelection() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isIncome = false;
                  // Auto-select first expense category
                  try {
                    _selectedCategory = _allCategories.firstWhere((c) => c.type == 'Expense');
                  } catch (_) {}
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !_isIncome ? const Color(0xFFEF4444).withOpacity(0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    'รายจ่าย',
                    style: GoogleFonts.kanit(
                      fontWeight: FontWeight.bold,
                      color: !_isIncome ? const Color(0xFFEF4444) : Colors.black45,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isIncome = true;
                  // Auto-select "Extra Income"
                  try {
                    _selectedCategory = _allCategories.firstWhere(
                      (c) => c.categoryName.toLowerCase() == 'extra income'
                    );
                  } catch (_) {
                    try {
                      _selectedCategory = _allCategories.firstWhere((c) => c.type == 'Income');
                    } catch (_) {}
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _isIncome ? const Color(0xFF2D955F).withOpacity(0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    'รายรับ',
                    style: GoogleFonts.kanit(
                      fontWeight: FontWeight.bold,
                      color: _isIncome ? const Color(0xFF2D955F) : Colors.black45,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid() {
    final filteredCategories = _allCategories.where((c) {
      if (_isIncome) {
        return c.categoryName.toLowerCase() == 'extra income';
      } else {
        return c.type == 'Expense';
      }
    }).toList();

    if (filteredCategories.isEmpty) {
      return Center(
        child: Text(
          'ไม่มีหมวดหมู่ที่เหมาะสม',
          style: GoogleFonts.kanit(color: Colors.black45),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        mainAxisExtent: 100,
      ),
      itemCount: filteredCategories.length,
      itemBuilder: (context, index) {
        final cat = filteredCategories[index];
        bool isSelected = _selectedCategory?.categoryId == cat.categoryId;
        
        return GestureDetector(
          onTap: () => setState(() => _selectedCategory = cat),
          child: Column(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF2D955F).withOpacity(0.1) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF2D955F) : const Color(0xFFE2E8F0),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    _getCategoryIcon(cat.categoryName),
                    if (isSelected)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Color(0xFF2D955F),
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
                _getCategoryThaiName(cat.categoryName),
                style: GoogleFonts.kanit(
                  fontSize: 12,
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

  String _getCategoryThaiName(String name) {
    switch (name.toLowerCase()) {
      case 'food':
        return 'อาหาร';
      case 'transport':
        return 'เดินทาง';
      case 'health':
        return 'สุขภาพ';
      case 'shopping':
        return 'ช้อปปิ้ง';
      case 'bills':
        return 'บิล';
      case 'entertainment':
        return 'บันเทิง';
      case 'saving':
        return 'เงินออม';
      case 'extra income':
        return 'รายได้เสริม';
      default:
        return name;
    }
  }
}
