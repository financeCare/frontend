import '../../models/finance_item.dart';
import '../../models/debt_strategy.dart';

class AvalancheStrategy extends DebtStrategy {
  AvalancheStrategy() : super('Avalanche Plan', 'จ่ายหนี้ดอกเบี้ยสูงก่อนเพื่อลดดอกเบี้ยรวม');

  @override
  List<FinanceItem> calculate(List<FinanceItem> debts, double monthlyBudget) {
    // clone debts
    List<FinanceItem> updatedDebts = debts.map((d) => FinanceItem(
      name: d.name,
      amount: d.amount,
      interest: d.interest,
      type: d.type,
      createdAt: d.createdAt,
    )).toList();

    // sort by interest descending
    updatedDebts.sort((a, b) => b.interest.compareTo(a.interest));

    // Logic จ่าย avalanche: จ่ายหนี้ดอกเบี้ยสูงสุดก่อน
    double remainingBudget = monthlyBudget;
    for (var debt in updatedDebts) {
      double pay = remainingBudget >= debt.amount ? debt.amount : remainingBudget;
      debt.amount -= pay;
      remainingBudget -= pay;
      if (remainingBudget <= 0) break;
    }
    return updatedDebts;
  }
}
