import '../../domain/models/finance_item.dart';
import '../../domain/models/debt_strategy.dart';

class FastTrackStrategy extends DebtStrategy {
  FastTrackStrategy() : super(
      "Fast Track",
      "จ่ายหนี้ให้เร็วที่สุดเท่าที่งบประมาณอนุญาต โดยไม่สนลำดับหนี้"
  );

  @override
  List<FinanceItem> calculate(List<FinanceItem> debts, double monthlyBudget) {
    List<FinanceItem> updatedDebts = debts.map((d) => FinanceItem(
      name: d.name,
      amount: d.amount,
      interest: d.interest,
      type: d.type,
      createdAt: d.createdAt,
    )).toList();

    double budgetLeft = monthlyBudget;
    for (var debt in updatedDebts) {
      if (budgetLeft <= 0) break;
      double pay = debt.amount < budgetLeft ? debt.amount : budgetLeft;
      debt.amount -= pay;
      budgetLeft -= pay;
    }

    return updatedDebts;
  }
}
