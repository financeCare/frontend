// lib/models/budget_summary.dart

class BudgetSummary {
  final String currentMonth;
  final double totalBudget;
  final double totalSpent;

  BudgetSummary({
    required this.currentMonth,
    required this.totalBudget,
    required this.totalSpent,
  });

  // เมธอดสำหรับแปลงจาก JSON ที่มาจาก Backend
  // (จำเป็นสำหรับการจัดการข้อมูลที่ถูกดึงมาจาก API จริงๆ)
  factory BudgetSummary.fromJson(Map<String, dynamic> json) {
    return BudgetSummary(
      currentMonth: json['current_month'] ?? 'N/A',
      totalBudget: (json['total_budget'] as num?)?.toDouble() ?? 0.0,
      totalSpent: (json['total_spent'] as num?)?.toDouble() ?? 0.0,
    );
  }
}