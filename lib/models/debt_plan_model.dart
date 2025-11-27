import '../models/finance_item.dart';
import '../models/debt_strategy.dart';


typedef SimulationFunction = Map<String, dynamic> Function(
    List<FinanceItem> incomes, List<FinanceItem> debts);

class DebtPlan {
  final String id;
  final String name;
  final String description;
  final List<String> pros;
  final List<String> cons;
  final List<String>? tips;
  final String? exampleUsage;
  final List<String>? warnings;
  final List<String>? expectedResults;

  final SimulationFunction? simulate;
  final DebtStrategy? strategy;

  DebtPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.pros,
    required this.cons,
    this.tips,
    this.exampleUsage,
    this.warnings,
    this.expectedResults,
    this.simulate,
    this.strategy,
  });
}
