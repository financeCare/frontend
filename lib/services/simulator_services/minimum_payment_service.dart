// import '../../models/finance_item.dart';
// import '../../models/debt_strategy.dart';

// class MinimumPaymentStrategy extends DebtStrategy {
//   MinimumPaymentStrategy() : super(
//       "Minimum Payment",
//       "จ่ายขั้นต่ำของแต่ละหนี้เพื่อป้องกันค่าปรับและคงเครดิต"
//   );

//   @override
//   List<FinanceItem> calculate(List<FinanceItem> debts, double monthlyBudget) {
//     List<FinanceItem> updatedDebts = debts.map((d) => FinanceItem(
//       name: d.name,
//       amount: d.amount,
//       interest: d.interest,
//       type: d.type,
//       createdAt: d.createdAt,
//     )).toList();

//     double budgetLeft = monthlyBudget;

//     for (var debt in updatedDebts) {
//       if (budgetLeft <= 0) break;
//       double minPayment = (debt.amount * 0.05); // สมมติขั้นต่ำ 5%
//       double pay = minPayment < budgetLeft ? minPayment : budgetLeft;
//       debt.amount -= pay;
//       budgetLeft -= pay;
//     }

//     return updatedDebts;
//   }
// }
