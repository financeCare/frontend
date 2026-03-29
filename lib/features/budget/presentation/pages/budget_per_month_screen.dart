import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:flutter_application_1/features/budget/domain/models/transaction_request.dart';
import 'package:flutter_application_1/features/budget/domain/models/transaction_response.dart';
import 'package:flutter_application_1/features/budget/data/services/transaction_service.dart';
import 'package:flutter_application_1/features/budget/domain/models/budget_overview.dart';
import 'package:flutter_application_1/features/budget/data/services/budget_service.dart';
import 'package:flutter_application_1/features/budget/data/services/category_service.dart';
import 'package:flutter_application_1/features/budget/domain/models/category.dart';
import 'package:flutter_application_1/features/budget/presentation/pages/category_transactions_screen.dart';
import 'package:flutter_application_1/features/budget/presentation/widgets/expandable_fab.dart';
import 'package:flutter_application_1/features/budget/presentation/pages/receiver_mapping_screen.dart';
import 'package:flutter_application_1/features/budget/data/services/receiver_mapping_service.dart';
import 'package:flutter_application_1/features/budget/domain/models/mapping_request.dart';
import 'package:flutter_application_1/features/budget/domain/models/receiver_mapping.dart';
import 'package:flutter_application_1/features/debt/data/services/debt_service.dart';
import 'package:flutter_application_1/features/debt/domain/models/monthly_debt_status.dart';


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
  double _totalIncome = 0;
  double _totalExpense = 0;
  double _totalSavings = 0;
  MonthlyDebtStatus? _debtStatus;
  List<TransactionResponse> _pendingTransactions = [];

  List<Categories> _allCategories = [];
  bool _isShowingModal = false;
  List<ReceiverMapping> _receiverMappings = [];


  // แนวโน้มรายเดือน (%)
  String _incomeTrend = "";
  String _expenseTrend = "";
  String _savingsTrend = "";
  bool _isIncomePositive = true;
  bool _isExpensePositive = true;
  bool _isSavingsPositive = true;

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
      final safeAmount = item.amount < 0 ? 0.0 : item.amount; // ป้องกันค่าติดลบ
      if (item.budgetName == 'Saving') {
        savings += safeAmount;
      } else {
        expense += safeAmount;
      }
    }

    final double income = await _budgetService.getIncomeAmount();
    MonthlyDebtStatus? debtStat;
    try {
      debtStat = await DebtService().getMonthlyDebtStatus();
    } catch (e) {
      debugPrint("Error loading debt status: $e");
    }


    // คำนวณแนวโน้มรายเดือนจาก Transactions
    try {
      final transactions = await TransactionService().getOwnTransactions();
      _calculateMonthlyTrends(transactions);
    } catch (e) {
      debugPrint("Error calculating trends: $e");
    }

    if (!mounted) return;
    setState(() {
      _budgetItems = data;
      _totalExpense = expense;
      _totalSavings = savings;
      _totalIncome = income;
      _debtStatus = debtStat;
    });


    // ดึงรายการ Pending และ Category ทั้งหมด
    try {
      final pending = await TransactionService().getPendingTransactions();
      final cats = await CategoryService().getCategories();
      if (mounted) {
        setState(() {
          _pendingTransactions = pending;
          _allCategories = cats;
        });
        if (_pendingTransactions.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showNextPendingTransaction();
          });
        }
      }
    } catch (e) {
      debugPrint("Error loading pending/categories: $e");
    }

    // ดึง Receiver Mappings ทั้งหมด
    try {
      final mappings = await ReceiverMappingService().getAllMappings();
      if (mounted) {
        setState(() {
          _receiverMappings = mappings;
        });
      }
    } catch (e) {
      debugPrint("Error loading receiver mappings: $e");
    }
  }


  void _showNextPendingTransaction() {
    if (_pendingTransactions.isEmpty || _isShowingModal) return;
    final tx = _pendingTransactions.first;
    _showTransactionConfirmationModal(tx);
  }

  void _showTransactionConfirmationModal(TransactionResponse tx) {
    if (!mounted) return;
    setState(() => _isShowingModal = true);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (context) => _TransactionConfirmationContent(
        transaction: tx,
        categories: _allCategories,
        onConfirm: (updatedTx) async {
          try {
            await TransactionService().updateTransaction(tx.transactionId, updatedTx);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('ยืนยันรายการสำเร็จ')),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
              );
            }
          }
          _handleNextAfterAction();
        },
        onReject: () async {
          try {
            await TransactionService().deleteTransaction(tx.transactionId);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('ลบรายการแล้ว')),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('เกิดข้อผิดพลาดในการลบ: $e')),
              );
            }
          }
          _handleNextAfterAction();
        },
        onClose: () {
          setState(() {
            _isShowingModal = false;
            _pendingTransactions.removeAt(0);
          });
          _showNextPendingTransaction();
        },
      ),
    ).then((_) {
      if (mounted) setState(() => _isShowingModal = false);
    });
  }

  void _handleNextAfterAction() {
    if (!mounted) return;
    setState(() {
      _isShowingModal = false;
      _pendingTransactions.removeAt(0);
    });
    // ให้เวลา Modal ปิดตัวลงก่อนเริ่มอันใหม่
    Future.delayed(const Duration(milliseconds: 300), () {
      _showNextPendingTransaction();
    });
  }

  void _calculateMonthlyTrends(List<TransactionResponse> transactions) {
    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;

    final prevMonth = currentMonth == 1 ? 12 : currentMonth - 1;
    final prevYear = currentMonth == 1 ? currentYear - 1 : currentYear;

    double curInc = 0, curExp = 0, curSav = 0;
    double preInc = 0, preExp = 0, preSav = 0;

    for (var tx in transactions) {
      final d = tx.transactionDate;
      final isSaving = tx.category.categoryName == 'Saving';
      final isIncome = tx.category.type == 'Income';

      if (d.month == currentMonth && d.year == currentYear) {
        if (isIncome) curInc += tx.amount;
        else if (isSaving) curSav += tx.amount;
        else curExp += tx.amount;
      } else if (d.month == prevMonth && d.year == prevYear) {
        if (isIncome) preInc += tx.amount;
        else if (isSaving) preSav += tx.amount;
        else preExp += tx.amount;
      }
    }

    setState(() {
      _incomeTrend = _formatTrend(curInc, preInc);
      _isIncomePositive = curInc >= preInc;
      
      _expenseTrend = _formatTrend(curExp, preExp);
      _isExpensePositive = curExp >= preExp;

      _savingsTrend = _formatTrend(curSav, preSav);
      _isSavingsPositive = curSav >= preSav;
    });
  }

  String _formatTrend(double current, double previous) {
    if (previous == 0) return current > 0 ? "+100% จากเดือนก่อน" : "0% จากเดือนก่อน";
    final diff = ((current - previous) / previous) * 100;
    final prefix = diff >= 0 ? "+" : "";
    return "$prefix${diff.toStringAsFixed(0)}% จากเดือนก่อน";
  }

  List<Categories> _getFilteredCategories(String type) {
    return _allCategories.where((c) {
      if (type == 'Income') {
        return c.type == 'Income' && c.categoryName == 'Extra Income';
      }
      return c.type == 'Expense';
    }).toList();
  }

  // --- Task 4 Integration ---
  void _showCategoryPicker(
    BuildContext context, 
    List<Categories> filteredCategories,
    Categories? currentSelected,
    Function(Categories) onSelect,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'เลือกหมวดหมู่',
              style: GoogleFonts.kanit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'เลือกหมวดหมู่ที่เหมาะสมที่สุดสำหรับรายการนี้',
              style: TextStyle(color: Colors.black45, fontSize: 13),
            ),
            const SizedBox(height: 24),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: filteredCategories.length,
                itemBuilder: (context, index) {
                  final cat = filteredCategories[index];
                  final isSelected = currentSelected?.categoryId == cat.categoryId;
                  final catColor = _getCategoryColor(cat.categoryName);
                  
                  return InkWell(
                    onTap: () {
                      onSelect(cat);
                      Navigator.pop(context);
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected ? catColor.withOpacity(0.05) : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? catColor.withOpacity(0.3) : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _getCategoryIcon(cat.categoryName),
                            color: isSelected ? catColor : Colors.black45,
                            size: 24,
                          ),
                          const SizedBox(width: 16),
                          Text(
                            cat.categoryName,
                            style: GoogleFonts.kanit(
                              fontSize: 16,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? catColor : const Color(0xFF1A1A1A),
                            ),
                          ),
                          const Spacer(),
                          if (isSelected)
                            Icon(Icons.check_circle, color: catColor, size: 20),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveTransaction(TransactionRequest request) async {
    try {
      // 1. Create the transaction first
      await TransactionService().createTransaction(request);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                child: const Icon(Icons.check_circle, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('สำเร็จ!', style: GoogleFonts.kanit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    Text('บันทึกรายการเรียบร้อยแล้ว', style: GoogleFonts.kanit(fontSize: 14, color: Colors.white70)),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF2D955F),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.all(16),
          elevation: 6,
          duration: const Duration(seconds: 3),
        ),
      );

      // 2. Auto-save Receiver Mapping AFTER transaction succeeds
      if (request.receiverName != null && request.receiverName!.trim().isNotEmpty) {
        final rName = request.receiverName!.trim();
        try {
          final existing = _receiverMappings.where((m) => m.receiverName.toLowerCase() == rName.toLowerCase()).toList();
          
          if (existing.isNotEmpty) {
            final oldMapping = existing.first;
            if (oldMapping.category.categoryId != request.categoryId) {
              try {
                await ReceiverMappingService().deleteMapping(oldMapping.id);
              } catch (_) {}
              
              await ReceiverMappingService().saveMapping(
                MappingRequest(receiverName: rName, categoryId: request.categoryId),
              );
              print("Auto-mapping updated for: $rName");
            }
          } else {
            await ReceiverMappingService().saveMapping(
              MappingRequest(receiverName: rName, categoryId: request.categoryId),
            );
            print("Auto-mapping saved for: $rName");
          }
        } catch (e) {
          print("Note: Auto-mapping skipped or failed: $e");
        }
      }

      _loadBudgetData();
    } catch (e) {
      if (!mounted) return;
      String errorMsg = e.toString().contains('Exception:') 
          ? e.toString().split('Exception: ').last 
          : e.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                child: const Icon(Icons.error_outline, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('เกิดข้อผิดพลาด!', style: GoogleFonts.kanit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    Text(errorMsg, style: GoogleFonts.kanit(fontSize: 14, color: Colors.white70)),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFEB5757),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.all(16),
          elevation: 6,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  // --- Popups ---

  void _showAddTransactionDialog() {
    final TextEditingController amountCtrl = TextEditingController();
    final TextEditingController descCtrl = TextEditingController();
    final TextEditingController receiverCtrl = TextEditingController(); 
    DateTime now = DateTime.now();
    DateTime selectedDate = DateTime(now.year, now.month, now.day);
    
    // ตั้งค่าเริ่มต้น
    String transactionType = 'Expense'; // 'Expense' หรือ 'Income'
    Categories? selectedCategory;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final filteredCategories = _getFilteredCategories(transactionType);
          
          // ถ้ายังไม่ได้เลือกหมวดหมู่ หรือหมวดหมู่ที่เคยเลือกไม่อยู่ในประเภทที่เปลี่ยนใหม่ ให้เลือกตัวแรก
          if (selectedCategory == null || !filteredCategories.any((c) => c.categoryId == selectedCategory!.categoryId)) {
            selectedCategory = filteredCategories.isNotEmpty ? filteredCategories.first : null;
          }

          final themeColor = selectedCategory != null
              ? _getCategoryColor(selectedCategory!.categoryName)
              : (transactionType == 'Expense' ? const Color(0xFFEB5757) : const Color(0xFF2D955F));

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
                   Center(
                    child: Column(
                      children: [
                        Text(
                          'เพิ่มรายการใหม่',
                          style: GoogleFonts.kanit(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          transactionType == 'Expense' ? 'บันทึกรายจ่ายของคุณ' : 'บันทึกรายรับของคุณ',
                          style: const TextStyle(
                            color: Colors.black45,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ส่วนเลือกประเภท รายจ่าย / รายรับ
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildTypeToggleBtn(
                            'รายจ่าย', 
                            transactionType == 'Expense',
                            const Color(0xFFEB5757),
                            () => setDialogState(() => transactionType = 'Expense'),
                          ),
                        ),
                        Expanded(
                          child: _buildTypeToggleBtn(
                            'รายรับ', 
                            transactionType == 'Income',
                            const Color(0xFF2D955F),
                            () => setDialogState(() => transactionType = 'Income'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ผู้รับเงิน (ย้ายมาไว้บนสุด)
                  Text(
                    transactionType == 'Expense' ? 'ผู้รับเงิน (ไม่บังคับ)' : 'แหล่งที่มา/ผู้จ่าย (ไม่บังคับ)',
                    style: GoogleFonts.kanit(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  LayoutBuilder(
                    builder: (context, constraints) => Autocomplete<ReceiverMapping>(
                      displayStringForOption: (ReceiverMapping option) => option.receiverName,
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        List<ReceiverMapping> baseList;
                        if (textEditingValue.text.isEmpty) {
                          // ดึงรายการล่าสุด (กรองตาม Income/Expense)
                          baseList = _receiverMappings
                              .where((m) => m.category.type.toLowerCase() == transactionType.toLowerCase())
                              .toList();
                          baseList.sort((a, b) => b.createdAt.compareTo(a.createdAt));
                        } else {
                          // ค้นหาตามชื่อ
                          baseList = _receiverMappings
                              .where((m) => m.receiverName.toLowerCase().contains(textEditingValue.text.toLowerCase()))
                              .toList();
                        }

                        // กรองชื่อซ้ำ และเอาอันล่าสุด
                        final Map<String, ReceiverMapping> uniqueMap = {};
                        for (var m in baseList) {
                          if (!uniqueMap.containsKey(m.receiverName.toLowerCase())) {
                            uniqueMap[m.receiverName.toLowerCase()] = m;
                          }
                          if (uniqueMap.length >= 10 && textEditingValue.text.isEmpty) break;
                        }
                        return uniqueMap.values;
                      },
                      onSelected: (ReceiverMapping selection) {
                        receiverCtrl.text = selection.receiverName;
                        setDialogState(() {
                          try {
                            // ค้นหาหมวดหมู่ที่ตรงกัน
                            final matchedCat = _allCategories.cast<Categories?>().firstWhere(
                              (c) => c?.categoryId == selection.category.categoryId,
                              orElse: () => null,
                            );
                            if (matchedCat != null) {
                              selectedCategory = matchedCat;
                            }
                          } catch (_) {}
                        });
                      },
                      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                        if (controller.text.isEmpty && receiverCtrl.text.isNotEmpty) {
                          controller.text = receiverCtrl.text;
                        }
                        
                        return TextField(
                          controller: controller,
                          focusNode: focusNode,
                          onChanged: (text) {
                            receiverCtrl.text = text;
                            final trimmedText = text.trim();
                            if (trimmedText.isNotEmpty) {
                              try {
                                final mapping = _receiverMappings.firstWhere(
                                  (m) => m.receiverName.toLowerCase() == trimmedText.toLowerCase()
                                );
                                setDialogState(() {
                                  // ค้นหาหมวดหมู่ที่ตรงกันอย่างปลอดภัย
                                  final matchedCat = _allCategories.cast<Categories?>().firstWhere(
                                    (c) => c?.categoryId == mapping.category.categoryId,
                                    orElse: () => null,
                                  );
                                  if (matchedCat != null) {
                                    selectedCategory = matchedCat;
                                  }
                                });
                              } catch (_) {}
                            }
                          },
                          decoration: InputDecoration(
                            hintText: transactionType == 'Expense' ? 'เช่น ร้านสะดวกซื้อ' : 'เช่น เงินรางวัล',
                            hintStyle: GoogleFonts.kanit(
                              color: Colors.black26,
                              fontSize: 14,
                            ),
                            suffixIcon: InkWell(
                              onTap: () {
                                // ล้างข้อความเพื่อกระตุ้นให้รายการแนะนำทั้งหมดเด้งขึ้นมา
                                controller.clear();
                                receiverCtrl.clear();
                                focusNode.requestFocus();
                              },
                              child: const Icon(Icons.arrow_drop_down, color: Colors.black26),
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
                        );
                      },
                      optionsViewBuilder: (context, onSelected, options) {
                        return Align(
                          alignment: Alignment.topLeft,
                          child: Material(
                            color: Colors.transparent,
                            child: Container(
                              width: constraints.maxWidth,
                              margin: const EdgeInsets.only(top: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 15,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                                border: Border.all(color: Colors.black.withOpacity(0.05)),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: ListView(
                                  padding: EdgeInsets.zero,
                                  shrinkWrap: true,
                                  children: [
                                    if (receiverCtrl.text.isEmpty)
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                                        child: Text(
                                          'ประวัติผู้รับเงินล่าสุด'.toUpperCase(),
                                          style: GoogleFonts.kanit(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                            color: Colors.black45,
                                          ),
                                        ),
                                      ),
                                    ...options.map((ReceiverMapping option) {
                                      final catName = option.category.categoryName;
                                      final catColor = _getCategoryColor(catName);
                                      final catIcon = _getCategoryIcon(catName);

                                      return InkWell(
                                        onTap: () => onSelected(option),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                          child: Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: catColor.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: Icon(
                                                  catIcon, 
                                                  size: 16, 
                                                  color: catColor
                                                ),
                                              ),
                                              const SizedBox(width: 14),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      option.receiverName,
                                                      style: GoogleFonts.kanit(
                                                        fontSize: 15,
                                                        fontWeight: FontWeight.w500,
                                                        color: Colors.black.withOpacity(0.8),
                                                      ),
                                                    ),
                                                    Text(
                                                      catName,
                                                      style: GoogleFonts.kanit(
                                                        fontSize: 11,
                                                        color: catColor,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Icon(
                                                Icons.arrow_forward_ios,
                                                size: 12,
                                                color: Colors.black26,
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ), // Autocomplete
                  ), // LayoutBuilder
                  const SizedBox(height: 24),

                  // --- Category Selection ---
                  Text(
                    'หมวดหมู่',
                    style: GoogleFonts.kanit(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_allCategories.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        'ไม่พบข้อมูลหมวดหมู่ กรุณารอสักครู่...',
                        style: TextStyle(color: Colors.black45),
                      ),
                    )
                  else
                    InkWell(
                      onTap: () {
                        _showCategoryPicker(context, _getFilteredCategories(transactionType), selectedCategory, (cat) {
                          setDialogState(() {
                            selectedCategory = cat;
                          });
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          border: Border.all(color: themeColor.withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              selectedCategory != null ? _getCategoryIcon(selectedCategory!.categoryName) : Icons.category_outlined,
                              color: themeColor,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              selectedCategory?.categoryName ?? 'เลือกหมวดหมู่',
                              style: GoogleFonts.kanit(
                                fontSize: 15,
                                color: selectedCategory != null ? Colors.black87 : Colors.black26,
                              ),
                            ),
                            const Spacer(),
                            const Icon(Icons.expand_more, color: Colors.black26),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),

                  // --- Amount ---
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
                    style: GoogleFonts.kanit(fontSize: 18, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      hintText: '0.00',
                      hintStyle: GoogleFonts.kanit(color: Colors.black26),
                      prefixIcon: Icon(Icons.attach_money, color: themeColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: themeColor.withOpacity(0.3)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: themeColor.withOpacity(0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: themeColor, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // --- Date ---
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
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: ColorScheme.light(
                                primary: themeColor,
                                onPrimary: Colors.white,
                                onSurface: Colors.black87,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setDialogState(() => selectedDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border.all(color: themeColor.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today_outlined, color: themeColor, size: 20),
                          const SizedBox(width: 12),
                          Text(
                            DateFormat('dd MMM yyyy').format(selectedDate),
                            style: GoogleFonts.kanit(fontSize: 15, color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // --- Description ---
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
                      hintText: 'รายละเอียดเพิ่มเติม...',
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

                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF8F9FA),
                            foregroundColor: Colors.black87,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: Colors.black12),
                            ),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'ยกเลิก',
                            style: GoogleFonts.kanit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: themeColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            final amt = double.tryParse(amountCtrl.text);
                            if (amt != null && amt > 0 && selectedCategory != null) {
                              
                              // หา budgetId ถ้าเป็นรายจ่าย
                              String? budgetId;
                              if (transactionType == 'Expense') {
                                try {
                                  final matchingBudget = _budgetItems.firstWhere(
                                    (b) => int.tryParse(b.categoryId) == selectedCategory!.categoryId
                                  );
                                  budgetId = matchingBudget.budgetId;
                                } catch (_) {}
                              }

                              final req = TransactionRequest(
                                categoryId: selectedCategory!.categoryId,
                                amount: amt,
                                transactionDate: selectedDate,
                                description: descCtrl.text,
                                receiverName: receiverCtrl.text,
                                budgetId: budgetId,
                              );
                              _saveTransaction(req);
                              Navigator.pop(context);
                            }
                          },
                          child: Text(
                            'บันทึก',
                            style: GoogleFonts.kanit(
                              fontSize: 16,
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
          );
        },
      ),
    );
  }

  Widget _buildTypeToggleBtn(String label, bool isSelected, Color activeColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ] : [],
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.kanit(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? activeColor : Colors.black45,
          ),
        ),
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
                    Center(
                      child: Text(
                        'ปรับงบประมาณ',
                        style: GoogleFonts.kanit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
      floatingActionButton: ExpandableFab(
        distance: 70.0,
        children: [
          ActionButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ReceiverMappingScreen()),
            ),
            icon: const Icon(Icons.sync_alt, size: 22),
            tooltip: 'จับคู่ผู้รับ-หมวดหมู่',
            color: const Color(0xFF64748B), // Slate blue-grey
          ),
          ActionButton(
            onPressed: () => Navigator.pushNamed(context, '/transactions'),
            icon: const Icon(Icons.receipt_long, size: 22),
            tooltip: 'ดูรายการทั้งหมด',
            color: const Color(0xFF1E293B), // Dark Slate
          ),
          ActionButton(
            onPressed: _showAddTransactionDialog,
            icon: const Icon(Icons.add, size: 28),
            tooltip: 'เพิ่มรายการใหม่',
            color: const Color(0xFF2D955F), // App Green
          ),
        ],
      ),
    );
  }

  Widget _buildTopHeader() {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Image.asset(
            'assets/logo_finance_care.png',
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'งบประมาณต่อเดือน',
          style: GoogleFonts.kanit(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1A1A1A),
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

  Widget _buildDonutChart(double totalLimit, double totalSpent) {
    // เตรียมข้อมูลสำหรับวงกลมแยกสี (รวมทุกหมวดหมู่ที่มีการใช้จ่ายจริง)
    final List<ChartSegment> segments = _budgetItems
      .where((item) => item.amount > 0)
      .map((item) => ChartSegment(
        value: item.amount,
        color: _getCategoryColor(item.budgetName),
      ))
      .toList();

    // คำนวณยอดรวมที่นำมาวาดจริงในแผนภูมิ
    final double chartTotal = segments.fold(0, (sum, seg) => sum + seg.value);
    final double percent = totalLimit > 0 ? (totalSpent / totalLimit).clamp(0, 1) : 0;

    return Container(
      width: 110,
      height: 110,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(110, 110),
            painter: DonutChartPainter(
              segments: segments,
              totalSpent: totalLimit > chartTotal ? totalLimit : (chartTotal > 0 ? chartTotal : 1),
              backgroundColor: const Color(0xFFF1F3F4),
              strokeWidth: 12,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${(percent * 100).toInt()}%',
                style: GoogleFonts.kanit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
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
            _incomeTrend,
            _isIncomePositive ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
            _isIncomePositive ? const Color(0xFF2D955F) : const Color(0xFFEB5757),
            Icons.trending_up,
            showTrend: _incomeTrend.isNotEmpty,
          ),
          const SizedBox(width: 16),
          _buildStatCard(
            'รายจ่าย',
            '฿${NumberFormat('#,###').format(_totalExpense)}',
            _expenseTrend,
            !_isExpensePositive ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
            !_isExpensePositive ? const Color(0xFF2D955F) : const Color(0xFFEB5757),
            Icons.trending_down,
            showTrend: _expenseTrend.isNotEmpty,
          ),
          const SizedBox(width: 16),
          _buildStatCard(
            'เงินออม',
            '฿${NumberFormat('#,###').format(_totalSavings)}',
            _savingsTrend,
            _isSavingsPositive ? const Color(0xFFE3F2FD) : const Color(0xFFFFEBEE),
            _isSavingsPositive ? const Color(0xFF1565C0) : const Color(0xFFEB5757),
            Icons.savings_outlined,
            showTrend: _savingsTrend.isNotEmpty,
          ),
          const SizedBox(width: 16),
          _buildDebtStatCard(),
        ],
      ),
    );
  }

  Widget _buildDebtStatCard() {
    final status = _debtStatus;
    if (status == null) return const SizedBox();

    final remaining = status.remainingAmount;
    final paid = status.paidAmount;
    final total = status.totalAmount;

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
                'ชำระหนี้',
                style: GoogleFonts.kanit(color: Colors.black45, fontSize: 12),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.priority_high,
                  size: 16,
                  color: Color(0xFFEB5757),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '฿${NumberFormat('#,###').format(remaining)}',
            style: GoogleFonts.kanit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'จ่ายแล้ว ฿${NumberFormat('#,###').format(paid)} / ฿${NumberFormat('#,###').format(total)}',
            style: GoogleFonts.kanit(
              fontSize: 10,
              color: Colors.black38,
              fontWeight: FontWeight.w500,
            ),
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
    final spent = item.amount < 0 ? 0.0 : item.amount; // ป้องกันค่าติดลบจาก API
    final remaining = budgeted - spent;
    final isOverBudget = remaining < 0;
    final percentage = budgeted > 0 ? (spent / budgeted).clamp(0.0, 1.0) : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
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
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CategoryTransactionsScreen(
                            categoryId: int.tryParse(item.categoryId) ?? 0,
                            categoryName: item.budgetName,
                            categoryColor: _getCategoryColor(item.budgetName),
                          ),
                        ),
                      );
                      if (result == true) {
                        _loadBudgetData();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F3F4),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.history_rounded,
                        size: 18,
                        color: Colors.black45,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () => _showAdjustBudgetDialog(index),
                    child: Text(
                      'แก้ไข',
                      style: GoogleFonts.kanit(
                        color: Colors.black45,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
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

class ChartSegment {
  final double value;
  final Color color;
  ChartSegment({required this.value, required this.color});
}

class DonutChartPainter extends CustomPainter {
  final List<ChartSegment> segments;
  final double totalSpent;
  final Color backgroundColor;
  final double strokeWidth;

  DonutChartPainter({
    required this.segments,
    required this.totalSpent,
    required this.backgroundColor,
    this.strokeWidth = 12,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // วาดพื้นหลัง (วงกลมสีเทา)
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    if (totalSpent <= 0 || segments.isEmpty) return;

    double startAngle = -1.5708; // เริ่มที่ 12 นาฬิกา (-PI/2)
    
    for (var segment in segments) {
      final sweepAngle = (segment.value / totalSpent) * 6.28318; // (value/total) * 2PI
      
      final paint = Paint()
        ..color = segment.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = segments.length == 1 ? StrokeCap.round : StrokeCap.butt;

      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
      startAngle += sweepAngle;
    }

    // ถ้าต้องการให้รอยต่อดูเนียนขึ้นในกรณีที่มีหลายสี และหัวท้ายชนกัน
    // ในที่นี้ใช้ StrokeCap.butt เพื่อให้สีไม่ทับกัน
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _TransactionConfirmationContent extends StatefulWidget {
  final TransactionResponse transaction;
  final List<Categories> categories;
  final Function(TransactionRequest) onConfirm;
  final VoidCallback onReject;
  final VoidCallback onClose;

  const _TransactionConfirmationContent({
    required this.transaction,
    required this.categories,
    required this.onConfirm,
    required this.onReject,
    required this.onClose,
  });

  @override
  State<_TransactionConfirmationContent> createState() =>
      _TransactionConfirmationContentState();
}

class _TransactionConfirmationContentState
    extends State<_TransactionConfirmationContent> {
  late TextEditingController _descController;
  late TextEditingController _receiverController;
  late Categories _selectedCategory;

  @override
  void initState() {
    super.initState();
    _descController =
        TextEditingController(text: widget.transaction.description);
    _receiverController =
        TextEditingController(text: widget.transaction.receiverName ?? '');
    _selectedCategory = widget.transaction.category;
  }

  @override
  void dispose() {
    _descController.dispose();
    _receiverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ตรวจสอบรายการใหม่',
                style: GoogleFonts.kanit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () {
                  Navigator.pop(context);
                  widget.onClose();
                },
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Amount Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Text(
                  '฿${NumberFormat('#,###.00').format(widget.transaction.amount)}',
                  style: GoogleFonts.kanit(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D955F).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    widget.transaction.category.categoryName,
                    style: GoogleFonts.kanit(
                      fontSize: 12,
                      color: const Color(0xFF2D955F),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Form Fields
          _buildLabel('หมวดหมู่'),
          _buildCategoryDropdown(),
          const SizedBox(height: 16),
          _buildLabel('รายละเอียด'),
          _buildTextField(_descController, 'เช่น ค่าอาหาร'),
          const SizedBox(height: 16),
          _buildLabel('ผู้รับเงิน'),
          _buildTextField(_receiverController, 'ระบุชื่อผู้รับ'),

          // Slip Preview
          if (widget.transaction.imagePath != null) ...[
            const SizedBox(height: 20),
            _buildSlipPreview(),
          ],

          const SizedBox(height: 32),
          // Actions
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onReject();
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.red.withOpacity(0.05),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'ปฏิเสธ',
                    style: GoogleFonts.kanit(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    final updatedTx = TransactionRequest(
                      categoryId: _selectedCategory.categoryId,
                      amount: widget.transaction.amount,
                      transactionDate: widget.transaction.transactionDate,
                      description: _descController.text,
                      receiverName: _receiverController.text,
                      budgetId: _selectedCategory.budgetId,
                      imagePath: widget.transaction.imagePath,
                      slipId: widget.transaction.slipId,
                    );
                    Navigator.pop(context);
                    widget.onConfirm(updatedTx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2D955F),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'ยืนยันข้อมูล',
                    style: GoogleFonts.kanit(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: GoogleFonts.kanit(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.black54,
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint) {
    return TextFormField(
      controller: controller,
      style: GoogleFonts.kanit(fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF1F3F5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Categories>(
          value: widget.categories.any((c) => c.categoryId == _selectedCategory.categoryId)
              ? widget.categories.firstWhere((c) => c.categoryId == _selectedCategory.categoryId)
              : null,
          isExpanded: true,
          hint: const Text('เลือกหมวดหมู่'),
          items: widget.categories.map((cat) {
            return DropdownMenuItem(
              value: cat,
              child: Text(cat.categoryName, style: GoogleFonts.kanit()),
            );
          }).toList(),
          onChanged: (cat) {
            if (cat != null) {
              setState(() => _selectedCategory = cat);
            }
          },
        ),
      ),
    );
  }

  Widget _buildSlipPreview() {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => Dialog(
            backgroundColor: Colors.transparent,
            child: InteractiveViewer(
              child: Image.file(File(widget.transaction.imagePath!)),
            ),
          ),
        );
      },
      child: Container(
        height: 80,
        width: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black12),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(
              File(widget.transaction.imagePath!),
              fit: BoxFit.cover,
            ),
            const Center(
              child: Icon(Icons.zoom_in, color: Colors.white, size: 32),
            ),
          ],
        ),
      ),
    );
  }
}
