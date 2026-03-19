import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../data/services/transaction_service.dart';
import '../../domain/models/transaction_response.dart';
import '../../data/services/category_service.dart';
import '../../domain/models/category.dart';

class TransactionListScreen extends StatefulWidget {
  const TransactionListScreen({super.key});

  @override
  State<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends State<TransactionListScreen> {
  final TransactionService _transactionService = TransactionService();
  final CategoryService _categoryService = CategoryService();
  
  bool _isLoading = true;
  List<TransactionResponse> _transactions = [];
  Map<int, Categories> _categoriesMap = {};
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final categories = await _categoryService.getCategories();
      final transactions = await _transactionService.getOwnTransactions();
      
      if (mounted) {
        setState(() {
          _categoriesMap = {for (var c in categories) c.categoryId: c};
          _transactions = transactions;
          _transactions.sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'รายการธุรกรรมทั้งหมด',
          style: GoogleFonts.kanit(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF2D955F)),
            )
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(
                      _errorMessage!,
                      style: GoogleFonts.kanit(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : _transactions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.receipt_long_outlined,
                            size: 64,
                            color: Colors.black12,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'ไม่พบรายการธุรกรรม',
                            style: GoogleFonts.kanit(
                              color: Colors.black45,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(24),
                      itemCount: _transactions.length,
                      itemBuilder: (context, index) {
                        final tx = _transactions[index];
                        final category = _categoriesMap[tx.categoryId];
                        return _buildTransactionItem(tx, category);
                      },
                    ),
    );
  }

  Widget _buildTransactionItem(TransactionResponse tx, Categories? category) {
    final categoryName = category?.categoryName ?? '';
    final color = _getCategoryColor(categoryName);
    final icon = _getCategoryIcon(categoryName);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.description.isNotEmpty ? tx.description : (categoryName.isNotEmpty ? categoryName : 'ไม่มีคำอธิบาย'),
                  style: GoogleFonts.kanit(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('dd MMM yyyy, HH:mm').format(tx.transactionDate),
                  style: GoogleFonts.kanit(fontSize: 12, color: Colors.black45),
                ),
              ],
            ),
          ),
          Text(
            '฿${NumberFormat('#,###.##').format(tx.amount)}',
            style: GoogleFonts.kanit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFEB5757),
            ),
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
