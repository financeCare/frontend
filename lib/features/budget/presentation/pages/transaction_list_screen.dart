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
      List<Categories> categories = await _categoryService.getCategories();
      List<TransactionResponse> transactions = await _transactionService.getOwnTransactions();
      
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
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: Color(0xFF2D955F))),
            )
          else if (_errorMessage != null)
            SliverFillRemaining(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(_errorMessage!, style: GoogleFonts.kanit(color: Colors.red)),
                ),
              ),
            )
          else if (_transactions.isEmpty)
            SliverFillRemaining(
              child: _buildEmptyState(),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final tx = _transactions[index];
                    final category = _categoriesMap[tx.categoryId];
                    return _buildTransactionItem(tx, category);
                  },
                  childCount: _transactions.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    final double totalExpense = _transactions.fold(0, (sum, item) => sum + item.amount);
    
    return SliverAppBar(
      expandedHeight: 200.0,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF2D955F),
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'รายการธุรกรรม',
          style: GoogleFonts.kanit(fontWeight: FontWeight.bold, color: Colors.white),
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Text(
                'รายจ่ายทั้งหมดในเดือนนี้',
                style: GoogleFonts.kanit(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                '฿${NumberFormat('#,###.##').format(totalExpense)}',
                style: GoogleFonts.kanit(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_transactions.length} รายการ',
                style: GoogleFonts.kanit(color: Colors.white60, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
              ),
            ],
          ),
          child: const Icon(
            Icons.receipt_long_rounded,
            size: 64,
            color: Color(0xFFCBD5E1),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'ไม่พบรายการธุรกรรม',
          style: GoogleFonts.kanit(
            color: const Color(0xFF64748B),
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'เริ่มบันทึกรายจ่ายของคุณเพื่อติดตามการเงิน',
          style: GoogleFonts.kanit(color: const Color(0xFF94A3B8), fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildTransactionItem(TransactionResponse tx, Categories? category) {
    final categoryName = category?.categoryName ?? '';
    final color = _getCategoryColor(categoryName);
    final icon = _getCategoryIcon(categoryName);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {}, // Detail view can be added later
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 22,
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
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('dd MMM yyyy • HH:mm').format(tx.transactionDate),
                        style: GoogleFonts.kanit(fontSize: 12, color: const Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '฿${NumberFormat('#,###.##').format(tx.amount)}',
                      style: GoogleFonts.kanit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFEF4444),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        categoryName.isNotEmpty ? categoryName : 'อื่นๆ',
                        style: GoogleFonts.kanit(fontSize: 10, color: const Color(0xFF64748B)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String name) {
    final lowerName = name.toLowerCase();
    if (lowerName.contains('food')) return const Color(0xFFEF4444);
    if (lowerName.contains('shopping')) return const Color(0xFFF59E0B);
    if (lowerName.contains('travel')) return const Color(0xFF3B82F6);
    if (lowerName.contains('bill')) return const Color(0xFF8B5CF6);
    if (lowerName.contains('health')) return const Color(0xFF10B981);
    if (lowerName.contains('saving')) return const Color(0xFF2D955F);
    return const Color(0xFF64748B);
  }

  IconData _getCategoryIcon(String name) {
    final lowerName = name.toLowerCase();
    if (lowerName.contains('food')) return Icons.restaurant_rounded;
    if (lowerName.contains('shopping')) return Icons.shopping_bag_rounded;
    if (lowerName.contains('travel')) return Icons.directions_car_rounded;
    if (lowerName.contains('bill')) return Icons.receipt_long_rounded;
    if (lowerName.contains('health')) return Icons.medical_services_rounded;
    if (lowerName.contains('saving')) return Icons.savings_rounded;
    return Icons.category_rounded;
  }
}
