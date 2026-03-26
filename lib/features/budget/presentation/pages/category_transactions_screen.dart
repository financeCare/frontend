import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../data/services/transaction_service.dart';
import '../../domain/models/transaction_detail.dart';

class CategoryTransactionsScreen extends StatefulWidget {
  final int categoryId;
  final String categoryName;
  final Color categoryColor;

  const CategoryTransactionsScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
    required this.categoryColor,
  });

  @override
  State<CategoryTransactionsScreen> createState() =>
      _CategoryTransactionsScreenState();
}

class _CategoryTransactionsScreenState
    extends State<CategoryTransactionsScreen> {
  final TransactionService _transactionService = TransactionService();
  bool _isLoading = true;
  List<TransactionDetail> _transactions = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  Future<void> _fetchTransactions() async {
    try {
      final data = await _transactionService.getTransactionsByCategory(
        widget.categoryId,
      );
      if (mounted) {
        setState(() {
          _transactions = data;
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

  Map<String, List<TransactionDetail>> _groupTransactions(List<TransactionDetail> txs) {
    final groups = <String, List<TransactionDetail>>{};
    for (var tx in txs) {
      final label = DateFormat('MMMM yyyy').format(tx.transactionDate);
      groups.putIfAbsent(label, () => []).add(tx);
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupTransactions(_transactions);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          widget.categoryName,
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
              child: Text(
                _errorMessage!,
                style: GoogleFonts.kanit(color: Colors.red),
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              itemCount: grouped.length,
              itemBuilder: (context, groupIndex) {
                final month = grouped.keys.elementAt(groupIndex);
                final items = grouped[month]!;
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        month,
                        style: GoogleFonts.kanit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                    ...items.map((tx) => _buildTransactionItem(tx)).toList(),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildTransactionItem(TransactionDetail tx) {
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
              color: widget.categoryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_outlined,
              color: widget.categoryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.description.isNotEmpty ? tx.description : 'ไม่มีคำอธิบาย',
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
}
