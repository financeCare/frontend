import 'package:flutter/material.dart';

class BudgetPerMonthScreen extends StatefulWidget {
  const BudgetPerMonthScreen({super.key});

  @override
  State<BudgetPerMonthScreen> createState() => _BudgetPerMonthScreenState();
}

// Model data structure for a single budget item
class BudgetSummary {
  final int categoryId;
  final String categoryName;
  final IconData icon;
  final double budgetedAmount;
  final double actualSpent;

  BudgetSummary({
    required this.categoryId,
    required this.categoryName,
    required this.icon,
    required this.budgetedAmount,
    required this.actualSpent,
  });

  // Calculate remaining budget
  double get remainingBudget => budgetedAmount - actualSpent;

  // Calculate spending percentage
  double get spendingPercentage => budgetedAmount > 0 ? (actualSpent / budgetedAmount).clamp(0.0, 1.0) : 0.0;
}

class _BudgetPerMonthScreenState extends State<BudgetPerMonthScreen> {
  // Mock Category Data (ตรงกับที่ใช้ใน expense_entry_screen)
  final List<Map<String, dynamic>> _categories = [
    {'name': 'ค่าอาหาร', 'icon': Icons.fastfood, 'id': 1},
    {'name': 'ค่าเดินทาง', 'icon': Icons.directions_bus, 'id': 2},
    {'name': 'ค่าวัสดุ', 'icon': Icons.business_center, 'id': 3},
    {'name': 'ค่าอื่น ๆ', 'icon': Icons.more_horiz, 'id': 4},
    {'name': 'ค่าเช่า', 'icon': Icons.home, 'id': 5},
  ];

  // Mock Budget Data (จำลองข้อมูลจากตาราง budget_per_month)
  // key: category_id, value: budgeted_amount
  final Map<int, double> _mockMonthlyBudget = {
    1: 5000.0, // ค่าอาหาร
    2: 2500.0, // ค่าเดินทาง
    3: 1000.0, // ค่าวัสดุ
    5: 12000.0, // ค่าเช่า
  };

  // Mock Transaction Data (จำลองข้อมูลจากตาราง transactions ในเดือนปัจจุบัน)
  // structure: category_id, amount
  final List<Map<String, dynamic>> _mockMonthlyTransactions = [
    {'category_id': 1, 'amount': 1200.0}, // ค่าอาหาร
    {'category_id': 1, 'amount': 800.0},  // ค่าอาหาร
    {'category_id': 2, 'amount': 150.0},  // ค่าเดินทาง
    {'category_id': 4, 'amount': 300.0},  // ค่าอื่น ๆ (ไม่มีงบตั้งไว้)
    {'category_id': 5, 'amount': 12000.0},// ค่าเช่า (เต็มงบ)
  ];

  List<BudgetSummary> _budgetSummaries = [];

  @override
  void initState() {
    super.initState();
    _loadBudgetSummary();
  }

  // Function to simulate loading and calculating budget summary
  void _loadBudgetSummary() {
    // 1. Calculate actual spending per category from transactions
    final Map<int, double> actualSpending = {};
    for (var tx in _mockMonthlyTransactions) {
      final id = tx['category_id'] as int;
      final amount = tx['amount'] as double;
      actualSpending.update(id, (existing) => existing + amount, ifAbsent: () => amount);
    }

    // 2. Combine Budgeted amount and Actual spending
    final List<BudgetSummary> summaries = [];

    // Iterate over mock budget data
    for (var entry in _mockMonthlyBudget.entries) {
      final categoryId = entry.key;
      final budgetedAmount = entry.value;
      final actualSpent = actualSpending[categoryId] ?? 0.0;

      final categoryInfo = _categories.firstWhere(
            (cat) => cat['id'] == categoryId,
        orElse: () => {'name': 'Unknown', 'icon': Icons.help_outline},
      );

      summaries.add(BudgetSummary(
        categoryId: categoryId,
        categoryName: categoryInfo['name'] as String,
        icon: categoryInfo['icon'] as IconData,
        budgetedAmount: budgetedAmount,
        actualSpent: actualSpent,
      ));
    }

    // 3. Add categories with spending but no budget (for completeness)
    for (var entry in actualSpending.entries) {
      final categoryId = entry.key;
      if (!_mockMonthlyBudget.containsKey(categoryId)) {
        final categoryInfo = _categories.firstWhere(
              (cat) => cat['id'] == categoryId,
          orElse: () => {'name': 'หมวดหมู่ ID:$categoryId', 'icon': Icons.help_outline},
        );

        summaries.add(BudgetSummary(
          categoryId: categoryId,
          categoryName: categoryInfo['name'] as String,
          icon: categoryInfo['icon'] as IconData,
          budgetedAmount: 0.0, // Budget is zero
          actualSpent: entry.value,
        ));
      }
    }

    // Sort the summaries (e.g., by percentage spent or budgeted amount)
    summaries.sort((a, b) => b.budgetedAmount.compareTo(a.budgetedAmount));

    setState(() {
      _budgetSummaries = summaries;
    });
  }

  // Utility function to format currency
  String _formatCurrency(double amount) {
    // For simplicity, use a basic format. In a real app, use the intl package.
    return amount.toStringAsFixed(2).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
    );
  }

  // Determines the color of the progress bar based on spending
  Color _getProgressBarColor(double percentage) {
    if (percentage >= 1.0) {
      return Colors.red.shade600; // Over budget
    } else if (percentage >= 0.8) {
      return Colors.amber.shade600; // Close to budget
    }
    return Colors.teal.shade400; // Safe
  }

  @override
  Widget build(BuildContext context) {
    // Calculate total overview
    final double totalBudget = _budgetSummaries.fold(0.0, (sum, item) => sum + item.budgetedAmount);
    final double totalSpent = _budgetSummaries.fold(0.0, (sum, item) => sum + item.actualSpent);
    final double totalRemaining = totalBudget - totalSpent;
    final double overallPercentage = totalBudget > 0 ? (totalSpent / totalBudget).clamp(0.0, 1.0) : 0.0;


    return Scaffold(
      body: Column(
        children: [
          // --- 1. Overview Card ---
          Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ภาพรวมงบประมาณเดือนนี้', style: TextStyle(color: Colors.white70, fontSize: 16)),
                const SizedBox(height: 5),
                Text(
                  'เหลือ: ${_formatCurrency(totalRemaining)} บาท',
                  style: TextStyle(
                      color: totalRemaining >= 0 ? Colors.white : Colors.red.shade300,
                      fontSize: 28,
                      fontWeight: FontWeight.bold
                  ),
                ),
                const SizedBox(height: 15),
                LinearProgressIndicator(
                  value: overallPercentage,
                  backgroundColor: Colors.white38,
                  valueColor: AlwaysStoppedAnimation<Color>(
                      _getProgressBarColor(overallPercentage)
                  ),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'งบประมาณรวม: ${_formatCurrency(totalBudget)}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    Text(
                      'ใช้ไปแล้ว: ${_formatCurrency(totalSpent)}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // --- 2. List of Budget Items ---
          Expanded(
            child: totalBudget == 0
                ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text(
                    'คุณยังไม่ได้ตั้งงบประมาณสำหรับเดือนนี้',
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                    textAlign: TextAlign.center,
                  ),
                )
            )
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              itemCount: _budgetSummaries.length,
              itemBuilder: (context, index) {
                final item = _budgetSummaries[index];

                // Determine if they are over budget
                final isOverBudget = item.remainingBudget < 0;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category Name and Icon
                        Row(
                          children: [
                            Icon(item.icon, color: Theme.of(context).primaryColor, size: 28),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Text(
                                item.categoryName,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                            // Remaining/Over Budget Text
                            Text(
                              isOverBudget
                                  ? 'เกินงบ: ${_formatCurrency(item.remainingBudget.abs())}'
                                  : 'เหลือ: ${_formatCurrency(item.remainingBudget)}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isOverBudget ? Colors.red.shade700 : Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Budget vs Spent
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'งบประมาณ: ${_formatCurrency(item.budgetedAmount)}',
                              style: const TextStyle(color: Colors.black54, fontSize: 14),
                            ),
                            Text(
                              'ใช้ไปแล้ว: ${_formatCurrency(item.actualSpent)}',
                              style: const TextStyle(color: Colors.black54, fontSize: 14),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Progress Bar
                        LinearProgressIndicator(
                          value: item.spendingPercentage,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              _getProgressBarColor(item.spendingPercentage)
                          ),
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}