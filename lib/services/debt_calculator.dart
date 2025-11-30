import '../models/finance_item.dart';
import '../models/debt_strategy.dart';

class DebtCalculator {
  final DebtStrategy strategy;

  DebtCalculator(this.strategy);

  List<FinanceItem> run(List<FinanceItem> debts, double budget) {
    return strategy.calculate(debts, budget);
  }
}
