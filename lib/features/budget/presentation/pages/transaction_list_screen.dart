import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../data/services/transaction_service.dart';
import '../../domain/models/transaction_response.dart';
import 'transaction_add_screen.dart';
import '../widgets/transaction_detail_bottom_sheet.dart';

class TransactionListScreen extends StatefulWidget {
  const TransactionListScreen({super.key});

  @override
  State<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends State<TransactionListScreen> {
  final TransactionService _transactionService = TransactionService();

  bool _isLoading = true;
  List<TransactionResponse> _transactions = [];
  String? _errorMessage;

  String _searchQuery = '';
  String _selectedFilter = 'All';
  DateTime? _filterDate;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      List<TransactionResponse> transactions = await _transactionService
          .getOwnTransactions();

      if (mounted) {
        setState(() {
          _transactions = transactions;
          _transactions.sort(
            (a, b) => b.transactionDate.compareTo(a.transactionDate),
          );
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

  List<TransactionResponse> get _filteredTransactions {
    return _transactions.where((tx) {
      // Search Filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final desc = tx.description.toLowerCase();
        final cat = tx.category.categoryName.toLowerCase();
        if (!desc.contains(query) && !cat.contains(query)) return false;
      }

      // Type Filter
      if (_selectedFilter == 'Income' &&
          tx.category.type.toLowerCase() != 'income')
        return false;
      if (_selectedFilter == 'Expense' &&
          tx.category.type.toLowerCase() != 'expense')
        return false;

      // Date Filter
      if (_filterDate != null) {
        final d1 = DateTime(
          _filterDate!.year,
          _filterDate!.month,
          _filterDate!.day,
        );
        final d2 = DateTime(
          tx.transactionDate.year,
          tx.transactionDate.month,
          tx.transactionDate.day,
        );
        if (d1 != d2) return false;
      }

      return true;
    }).toList();
  }

  Map<String, List<TransactionResponse>> _groupTransactions(
    List<TransactionResponse> txs,
  ) {
    final groups = <String, List<TransactionResponse>>{};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (var tx in txs) {
      final date = DateTime(
        tx.transactionDate.year,
        tx.transactionDate.month,
        tx.transactionDate.day,
      );
      String label;
      if (date == today) {
        label = 'วันนี้';
      } else if (date == yesterday) {
        label = 'เมื่อวาน';
      } else {
        label = DateFormat('dd MMMM yyyy').format(date);
      }
      groups.putIfAbsent(label, () => []).add(tx);
    }
    return groups;
  }

  double _calculateTotalInGroup(List<TransactionResponse> group) {
    return group.fold(0, (sum, tx) => sum + tx.amount);
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredTransactions;
    final grouped = _groupTransactions(filtered);
    final totalExpense = filtered
        .where((tx) => tx.category.type.toLowerCase() == 'expense')
        .fold(0.0, (sum, tx) => sum + tx.amount);
    final todayExpense = filtered
        .where((tx) {
          final now = DateTime.now();
          return tx.transactionDate.year == now.year &&
              tx.transactionDate.month == now.month &&
              tx.transactionDate.day == now.day &&
              tx.category.type.toLowerCase() == 'expense';
        })
        .fold(0.0, (sum, tx) => sum + tx.amount);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF2D955F)),
            )
          : CustomScrollView(
              slivers: [
                _buildAppBar(totalExpense, todayExpense, filtered.length),
                SliverToBoxAdapter(child: _buildControls()),
                if (_errorMessage != null)
                  SliverFillRemaining(
                    child: Center(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  )
                else if (filtered.isEmpty)
                  SliverFillRemaining(child: _buildEmptyState())
                else
                  ...grouped.entries
                      .map(
                        (entry) =>
                            _buildTransactionGroup(entry.key, entry.value),
                      )
                      .toList(),
                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            ),
    );
  }

  Widget _buildAppBar(double totalExpense, double todayExpense, int count) {
    return SliverAppBar(
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFFF8F9FA),
      surfaceTintColor: const Color(0xFFF8F9FA),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
        onPressed: () => Navigator.pop(context),
      ),
      actions: const [],
      title: Text(
        'รายการธุรกรรม',
        style: GoogleFonts.kanit(
          color: Colors.black87,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }


  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          // Search Bar
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'ค้นหารายการ...',
                hintStyle: GoogleFonts.kanit(color: Colors.grey[400]),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Filter Bar
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All'),
                _buildFilterChip('Income'),
                _buildFilterChip('Expense'),
                _buildDateFilterChip(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    bool isSelected = _selectedFilter == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () => setState(() => _selectedFilter = label),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2D955F) : Colors.white,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              if (!isSelected)
                BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 5),
            ],
          ),
          child: Text(
            label,
            style: GoogleFonts.kanit(
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateFilterChip() {
    bool isSelected = _filterDate != null;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: _filterDate ?? DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
            builder: (context, child) {
              return Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: const ColorScheme.light(
                    primary: Color(0xFF2D955F),
                  ),
                ),
                child: child!,
              );
            },
          );
          if (picked != null) setState(() => _filterDate = picked);
        },
        onLongPress: () => setState(() => _filterDate = null),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2D955F) : Colors.white,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              if (!isSelected)
                BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 5),
            ],
          ),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 16,
                color: isSelected ? Colors.white : Colors.black54,
              ),
              const SizedBox(width: 8),
              Text(
                isSelected
                    ? DateFormat('dd MMM').format(_filterDate!)
                    : 'Select Date',
                style: GoogleFonts.kanit(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              if (isSelected)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: InkWell(
                    onTap: () => setState(() => _filterDate = null),
                    child: const Icon(
                      Icons.close,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionGroup(String date, List<TransactionResponse> txs) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      date,
                      style: GoogleFonts.kanit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    if (date == 'วันนี้')
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2D955F),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'TODAY',
                          style: GoogleFonts.kanit(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                Text(
                  'รวม ฿${NumberFormat('#,###.##').format(_calculateTotalInGroup(txs))}',
                  style: GoogleFonts.kanit(color: Colors.black45, fontSize: 12),
                ),
              ],
            ),
          ),
          ...txs.map((tx) => _buildTransactionItem(tx)).toList(),
        ]),
      ),
    );
  }

  Widget _buildTransactionItem(TransactionResponse tx) {
    final bool isIncome = tx.category.type.toLowerCase() == 'income';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => TransactionDetailBottomSheet.show(context, tx, () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    TransactionAddScreen(transactionToEdit: tx),
              ),
            );
            if (result == true) {
              _loadData(); // Reload list after edit
            }
          }),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildCategoryIcon(tx.category.categoryName),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tx.description.isNotEmpty
                            ? tx.description
                            : tx.category.categoryName,
                        style: GoogleFonts.kanit(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (tx.receiverName != null &&
                          tx.receiverName!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          tx.receiverName!,
                          style: GoogleFonts.kanit(
                            color: Colors.orange,
                            fontSize: 11,
                            fontWeight: FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${isIncome ? '+' : ''}฿${NumberFormat('#,###.##').format(tx.amount)}',
                      style: GoogleFonts.kanit(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isIncome
                            ? const Color(0xFF2D955F)
                            : Colors.black87,
                      ),
                    ),
                    Text(
                      DateFormat('HH:mm').format(tx.transactionDate),
                      style: GoogleFonts.kanit(
                        color: Colors.black26,
                        fontSize: 12,
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

  Widget _buildCategoryIcon(String name) {
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
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(iconData, color: color, size: 24),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'ไม่พบรายการที่ค้นหา',
            style: GoogleFonts.kanit(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
