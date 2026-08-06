import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../data/services/transaction_service.dart';
import '../../domain/models/transaction_detail.dart';
import '../../../../core/config/config.dart' as Config;
import '../../../auth/data/services/access_token_service.dart';

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
  bool _isDataChanged = false;
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

  Future<bool?> _showConfirmDelete(TransactionDetail tx) {
    return showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEB5757).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_outline,
                    size: 32, color: Color(0xFFEB5757)),
              ),
              const SizedBox(height: 24),
              Text(
                'ยืนยันการลบรายการ',
                style:
                    GoogleFonts.kanit(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              if (tx.description.isNotEmpty) ...[
                Text(
                  tx.description,
                  style: GoogleFonts.kanit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A1A1A),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
              ],
              Text(
                (tx.transactionDate.hour == 0 && tx.transactionDate.minute == 0)
                    ? DateFormat('dd MMM yyyy').format(tx.transactionDate)
                    : DateFormat('dd MMM yyyy, HH:mm').format(tx.transactionDate),
                style: GoogleFonts.kanit(fontSize: 14, color: Colors.black45),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.pop(context, false),
                      child: Text('ยกเลิก',
                          style: GoogleFonts.kanit(color: Colors.black54)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEB5757),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.pop(context, true),
                      child: Text('ลบรายการ',
                          style: GoogleFonts.kanit(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteTransaction(TransactionDetail tx) async {
    final confirmed = await _showConfirmDelete(tx);
    if (confirmed == true) {
      if (!mounted) return;
      setState(() => _isLoading = true);
      try {
        await _transactionService.deleteTransaction(tx.transactionId);
        if (mounted) {
          setState(() => _isDataChanged = true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'ลบรายการเรียบร้อยแล้ว',
                style: GoogleFonts.kanit(),
              ),
              backgroundColor: const Color(0xFF2D955F),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
        _fetchTransactions();
      } catch (e) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('ลบรายการไม่สำเร็จ: $e', style: GoogleFonts.kanit()),
          backgroundColor: const Color(0xFFEB5757),
        ));
      }
    }
  }

  void _showSlipDialog(int slipId) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: FutureBuilder<String?>(
          future: AccesstokenService().getAccessToken(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Container(
                height: 200,
                child: const Center(
                  child: CircularProgressIndicator(color: Color(0xFF2D955F)),
                ),
              );
            }
            if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
              return Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text('ไม่สามารถโหลดข้อมูลสลิปได้', style: GoogleFonts.kanit()),
                  ],
                ),
              );
            }

            final token = snapshot.data!;
            final url = '${Config.baseUrl}/api/slips/$slipId/image';

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppBar(
                  title: Text('รูปภาพสลิป', style: GoogleFonts.kanit(fontSize: 16, fontWeight: FontWeight.bold)),
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                  elevation: 0,
                  automaticallyImplyLeading: false,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                Flexible(
                  child: Container(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.7,
                    ),
                    child: InteractiveViewer(
                      child: Image.network(
                        url,
                        headers: {'Authorization': 'Bearer $token'},
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            padding: const EdgeInsets.all(40),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.broken_image_outlined, color: Colors.grey, size: 64),
                                const SizedBox(height: 16),
                                Text('โหลดรูปภาพสลิปไม่สำเร็จ', style: GoogleFonts.kanit(color: Colors.black54)),
                              ],
                            ),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            height: 300,
                            child: const Center(
                              child: CircularProgressIndicator(color: Color(0xFF2D955F)),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupTransactions(_transactions);

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _isDataChanged);
        return false;
      },
      child: Scaffold(
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
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            onPressed: () => Navigator.pop(context, _isDataChanged),
          ),
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
                    ...items.map((tx) => _buildTransactionItem(tx)),
                  ],
                );
              },
            ),
      ),
    );
  }

  Widget _buildTransactionItem(TransactionDetail tx) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
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
                            tx.description.isNotEmpty
                                ? tx.description
                                : 'ไม่มีคำอธิบาย',
                            style: GoogleFonts.kanit(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            (tx.transactionDate.hour == 0 && tx.transactionDate.minute == 0)
                                ? DateFormat('dd MMM yyyy').format(tx.transactionDate)
                                : DateFormat('dd MMM yyyy, HH:mm').format(tx.transactionDate),
                            style: GoogleFonts.kanit(
                                fontSize: 12, color: Colors.black45),
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
                            color: const Color(0xFFEB5757),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (tx.slipId != null) ...[
                              GestureDetector(
                                onTap: () => _showSlipDialog(tx.slipId!),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2D955F).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.receipt_long_outlined,
                                        size: 14,
                                        color: Color(0xFF2D955F),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'ดูสลิป',
                                        style: GoogleFonts.kanit(
                                          fontSize: 11,
                                          color: const Color(0xFF2D955F),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            GestureDetector(
                              onTap: () => _deleteTransaction(tx),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEB5757).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.delete_outline,
                                      size: 14,
                                      color: Color(0xFFEB5757),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'ลบรายการ',
                                      style: GoogleFonts.kanit(
                                        fontSize: 11,
                                        color: const Color(0xFFEB5757),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
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
}
