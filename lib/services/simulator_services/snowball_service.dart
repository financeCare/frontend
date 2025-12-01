// import '../../models/finance_item.dart';
// import '../../models/debt_strategy.dart';

// class SnowballStrategy extends DebtStrategy {
//   SnowballStrategy() : super('Snowball Plan', 'จ่ายหนี้เล็กก่อนเพื่อแรงจูงใจ');

//   @override
//   List<FinanceItem> calculate(List<FinanceItem> debts, double monthlyBudget) {
//     List<FinanceItem> updatedDebts = debts.map((d) => FinanceItem(
//       name: d.name,
//       amount: d.amount,
//       interest: d.interest,
//       type: d.type,
//       createdAt: d.createdAt,
//     )).toList();

//     updatedDebts.sort((a, b) => a.amount.compareTo(b.amount));

//     double remainingBudget = monthlyBudget;
//     for (var debt in updatedDebts) {
//       double pay = remainingBudget >= debt.amount ? debt.amount : remainingBudget;
//       debt.amount -= pay;
//       remainingBudget -= pay;
//       if (remainingBudget <= 0) break;
//     }
//     return updatedDebts;
//   }
// }
