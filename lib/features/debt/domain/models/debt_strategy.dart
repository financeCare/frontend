import 'finance_item.dart';

abstract class DebtStrategy {
  final String name;
  final String description;

  DebtStrategy(this.name, this.description);

  List<FinanceItem> calculate(List<FinanceItem> debts, double monthlyBudget);
}
