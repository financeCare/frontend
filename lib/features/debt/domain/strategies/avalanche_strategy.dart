import '../models/finance_item.dart';
import '../models/debt_strategy.dart';
class AvalancheStrategy extends DebtStrategy {
  AvalancheStrategy()
      : super(
    "Avalanche Plan",
    "จัดการหนี้ดอกเบี้ยสูงก่อน เพื่อลดดอกเบี้ยรวม",
  );

  @override
  List<FinanceItem> calculate(List<FinanceItem> debts, double monthlyBudget) {
    final sorted = List<FinanceItem>.from(debts)
      ..sort((a, b) => b.interest.compareTo(a.interest));

    return sorted;
  }
}
