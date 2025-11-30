import 'package:flutter/material.dart';

class ExpenseEntryScreen extends StatefulWidget {
  const ExpenseEntryScreen({super.key});

  @override
  State<ExpenseEntryScreen> createState() => _ExpenseEntryScreenState();
}

class _ExpenseEntryScreenState extends State<ExpenseEntryScreen> {
  final _formKey = GlobalKey<FormState>();

  // Database Field Mappings based on 'transactions' table
  String? _transactionType; // Maps to 'type' (e.g., 'expense', 'income')
  String? _selectedCategory; // Will be mapped to 'category_id' (integer)

  final TextEditingController _amountController = TextEditingController(); // Maps to 'amount' (double precision)
  final TextEditingController _descriptionController = TextEditingController(); // Maps to 'description' (character varying)
  DateTime _selectedDate = DateTime.now(); // Maps to 'transaction_date' (date)

  bool _isSaving = false;

  // Available Transaction Types
  final List<String> _transactionTypes = ['รายจ่าย', 'รายรับ'];

  // Available Categories (Mock data to be used for category_id)
  final List<Map<String, dynamic>> _categoriesWithIcon = [
    {'name': 'ค่าอาหาร', 'icon': Icons.fastfood, 'id': 1},
    {'name': 'ค่าเดินทาง', 'icon': Icons.directions_bus, 'id': 2},
    {'name': 'ค่าวัสดุ', 'icon': Icons.business_center, 'id': 3},
    {'name': 'ค่าอื่น ๆ', 'icon': Icons.more_horiz, 'id': 4}
  ];

  @override
  void initState() {
    super.initState();
    // Set default transaction type
    _transactionType = _transactionTypes.first;
  }

  // Utility function for formatting date
  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  Future<void> pickDate() async {
    DateTime? newDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'เลือกวันที่ทำรายการ',
    );

    if (newDate != null) {
      setState(() {
        _selectedDate = newDate;
      });
    }
  }

  void saveExpense() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);

      // Find the actual category ID for database mapping
      final selectedCategoryObject = _categoriesWithIcon.firstWhere(
            (cat) => cat['name'] == _selectedCategory,
        orElse: () => {'id': null},
      );

      // Simulate API call or database save
      await Future.delayed(const Duration(seconds: 2));

      final transactionDataForDB = {
        // Essential DB fields
        'type': _transactionType,
        'category_id': selectedCategoryObject['id'], // Mapped to integer
        'amount': double.tryParse(_amountController.text) ?? 0.0,
        'description': _descriptionController.text,
        'transaction_date': _selectedDate.toIso8601String().substring(0, 10), // Format for Date type
      };

      print('Transaction Data Prepared for DB: $transactionDataForDB');

      if (mounted) {
        // 1. Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("บันทึกรายการสำเร็จ!")),
        );

        // 2. Reset saving state and clear form (optional, since we are navigating away)
        // setState(() {
        //   _isSaving = false;
        //   _amountController.clear();
        //   _descriptionController.clear();
        //   _selectedCategory = null;
        // });

        // 3. Navigate back to the previous screen (Homepage/Dashboard)
        Navigator.pop(context);
      }
    }
    // Only set _isSaving to false if validation failed or if mounted check failed before navigation
    if(mounted) {
      setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('บันทึกรายการ'), // Updated title to be general
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 1. ประเภทรายการ (Type) ---
              const Text("ประเภทรายการ", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  hintText: "เลือกประเภทรายการ",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.swap_horiz),
                ),
                items: _transactionTypes.map((type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                value: _transactionType,
                onChanged: (value) {
                  setState(() => _transactionType = value);
                },
                validator: (value) => value == null ? "กรุณาเลือกประเภทรายการ" : null,
              ),
              const SizedBox(height: 20),

              // --- 2. หมวดหมู่ (Category ID) ---
              const Text("หมวดหมู่", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  hintText: "เลือกหมวดหมู่",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.category),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: _categoriesWithIcon.map((item) {
                  return DropdownMenuItem<String>(
                    value: item['name'] as String,
                    child: Row(
                      children: [
                        Icon(item['icon'] as IconData, size: 20, color: Theme.of(context).primaryColor),
                        const SizedBox(width: 10),
                        Text(item['name'] as String),
                      ],
                    ),
                  );
                }).toList(),
                value: _selectedCategory,
                onChanged: (value) {
                  setState(() => _selectedCategory = value);
                },
                validator: (value) => value == null ? "กรุณาเลือกหมวดหมู่" : null,
              ),
              const SizedBox(height: 20),

              // --- 3. จำนวนเงิน (Amount) ---
              const Text("จำนวนเงิน", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: "เช่น 120.00",
                  prefixIcon: const Icon(Icons.attach_money),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return "กรุณากรอกจำนวนเงิน";
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) return "จำนวนเงินไม่ถูกต้อง";
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // --- 4. รายละเอียดเพิ่มเติม (Description) ---
              const Text("รายละเอียดเพิ่มเติม", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: "ระบุรายละเอียดเพิ่มเติม (ถ้ามี)",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),

              // --- 5. วันที่ (Transaction Date) ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "วันที่: ${_formatDate(_selectedDate)}",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  ElevatedButton.icon(
                    onPressed: pickDate,
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: const Text("เลือกวันที่"),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                    ),
                  )
                ],
              ),

              const SizedBox(height: 30),

              // --- ปุ่มบันทึก ---
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : saveExpense,
                  icon: _isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                      : const Icon(Icons.save),
                  label: Text(_isSaving ? "กำลังบันทึก..." : "บันทึกรายการ"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              // ปุ่มยกเลิก
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Reset fields on cancel
                    setState(() {
                      _amountController.clear();
                      _descriptionController.clear();
                      _selectedCategory = null;
                      _transactionType = _transactionTypes.first;
                      _selectedDate = DateTime.now();
                    });
                  },
                  icon: const Icon(Icons.close),
                  label: const Text("ล้างข้อมูล"),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: BorderSide(color: Theme.of(context).primaryColor),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}