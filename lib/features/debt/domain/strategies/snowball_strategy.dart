import '../models/finance_item.dart';
import '../models/debt_strategy.dart';

class SnowballStrategy extends DebtStrategy {
  SnowballStrategy()
      : super(
    "Snowball Plan",
    "จ่ายหนี้ยอดเล็กก่อน เพื่อสร้างแรงจูงใจ",
  );

  @override
  List<FinanceItem> calculate(List<FinanceItem> debts, double monthlyBudget) {
    final sorted = List<FinanceItem>.from(debts)
      ..sort((a, b) => a.amount.compareTo(b.amount));

    return sorted;
  }
}
