import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';

// 💡 Mock Data: ข้อมูลหมวดหมู่สำหรับ Dropdown
final List<String> _mockCategories = [
  'อาหารและเครื่องดื่ม',
  'ค่าเดินทาง',
  'ช้อปปิ้ง',
  'บิลและค่าใช้จ่าย',
  'บันเทิง',
  'อื่น ๆ',
];

class ExpenseEntryScreen extends StatefulWidget {
  const ExpenseEntryScreen({super.key});

  @override
  State<ExpenseEntryScreen> createState() => _ExpenseEntryScreenState();
}

class _ExpenseEntryScreenState extends State<ExpenseEntryScreen> {
  // 💡 Key สำหรับจัดการสถานะของ Form
  final _formKey = GlobalKey<FormState>();
  // 💡 สร้าง instance ของ ApiService
  final ApiService _apiService = ApiService();

  // State สำหรับเก็บข้อมูลฟอร์ม
  double? _amount;
  String _description = '';
  String? _selectedCategory;
  DateTime _selectedDate = DateTime.now();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // กำหนดค่าเริ่มต้นของหมวดหมู่ให้เป็นค่าแรกในรายการ
    _selectedCategory = _mockCategories.first;
    // ตั้งค่าภาษาไทยสำหรับ DateFormat
    Intl.defaultLocale = 'th';
  }

  // 🚨 เมธอดสำหรับบันทึกค่าใช้จ่ายและเรียก API
  Future<void> _saveExpense() async {
    // ตรวจสอบความถูกต้องของฟอร์ม
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      setState(() {
        _isLoading = true; // เริ่มโหลด
      });

      // เตรียมข้อมูลที่จะส่งไปยัง Backend
      final transactionData = {
        'amount': _amount,
        'description': _description,
        'category': _selectedCategory,
        // แปลงวันที่ให้อยู่ในรูปแบบ 'YYYY-MM-DD' ซึ่งเป็นมาตรฐานที่ Backend มักใช้
        'date': DateFormat('yyyy-MM-dd').format(_selectedDate),
        'type': 'expense',
      };

      try {
        // 🚨 เรียกใช้เมธอด createTransaction
        await _apiService.createTransaction(transactionData);

        // แสดง Popup สำเร็จและกลับหน้าจอ
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('บันทึกค่าใช้จ่ายสำเร็จ!'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context); // ปิดหน้าจอ ExpenseEntryScreen

      } catch (e) {
        // แสดง Popup ข้อผิดพลาด
        print('Error saving expense: $e');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาดในการบันทึก: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      } finally {
        // เสร็จสิ้นการโหลด ไม่ว่าสำเร็จหรือผิดพลาด
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // เมธอดสำหรับเปิด Date Picker
  Future<void> _presentDatePicker() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      locale: const Locale('th', 'TH'), // ใช้ภาษาไทย
      helpText: 'เลือกวันที่ทำรายการ',
      cancelText: 'ยกเลิก',
      confirmText: 'ตกลง',
    );
    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('บันทึกค่าใช้จ่ายใหม่'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // 1. ช่องกรอกจำนวนเงิน
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'จำนวนเงิน (฿)',
                  prefixIcon: const Icon(Icons.monetization_on),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'กรุณาใส่จำนวนเงิน';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'จำนวนเงินไม่ถูกต้อง';
                  }
                  return null;
                },
                onSaved: (value) {
                  _amount = double.tryParse(value!);
                },
              ),
              const SizedBox(height: 20),

              // 2. ช่องกรอกรายละเอียด
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'รายละเอียด (เช่น ค่ากาแฟ, ค่ารถไฟฟ้า)',
                  prefixIcon: const Icon(Icons.description),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                maxLength: 100,
                onSaved: (value) {
                  _description = value ?? '';
                },
              ),
              const SizedBox(height: 10),

              // 3. Dropdown เลือกหมวดหมู่
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'หมวดหมู่',
                  prefixIcon: const Icon(Icons.category),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                value: _selectedCategory,
                items: _mockCategories.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedCategory = newValue;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'กรุณาเลือกหมวดหมู่';
                  }
                  return null;
                },
                onSaved: (value) {
                  _selectedCategory = value;
                },
              ),
              const SizedBox(height: 20),

              // 4. แถวสำหรับเลือกวันที่
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: <Widget>[
                    const Icon(Icons.calendar_today, color: Colors.grey),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'วันที่ทำรายการ: ${DateFormat('EEEE, d MMMM yyyy').format(_selectedDate)}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    OutlinedButton(
                      onPressed: _presentDatePicker,
                      child: const Text('เปลี่ยนวันที่'),
                    ),
                  ],
                ),
              ),
              const Divider(),
              const SizedBox(height: 30),

              // 5. ปุ่มบันทึก
              ElevatedButton(
                onPressed: _isLoading ? null : _saveExpense,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 5,
                ),
                child: _isLoading
                    ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                )
                    : const Text(
                  'บันทึกรายการ',
                  style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}