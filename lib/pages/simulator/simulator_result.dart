import 'package:flutter/material.dart';
import '../../models/finance_item.dart';
import '../../models/debt_strategy.dart';

class SimulatorResultScreen extends StatelessWidget {
  final List<FinanceItem> debts;
  final double monthlyBudget;
  final DebtStrategy strategy;

  const SimulatorResultScreen({
    super.key,
    required this.debts,
    required this.monthlyBudget,
    required this.strategy,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    // คำนวณผลลัพธ์
    List<FinanceItem> updatedDebts = strategy.calculate(debts, monthlyBudget);

    double totalDebt = updatedDebts.fold(0, (sum, d) => sum + d.amount);
    int remainingDebts = updatedDebts.where((d) => d.amount > 0).length;

    return Scaffold(
      appBar: AppBar(
        title: Text("ผลลัพธ์: ${strategy.name}"),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("แผนที่เลือก: ${strategy.name}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(strategy.description, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            Text("งบประมาณต่อเดือน: $monthlyBudget", style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 12),
            Text("หนี้คงเหลือทั้งหมด: $totalDebt", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text("จำนวนหนี้ที่เหลือ: $remainingDebts", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text("รายละเอียดหนี้หลังคำนวณ:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: updatedDebts.length,
                itemBuilder: (context, index) {
                  final d = updatedDebts[index];
                  return ListTile(
                    title: Text(d.name),
                    subtitle: Text("ยอดคงเหลือ: ${d.amount.toStringAsFixed(2)} | ดอกเบี้ย: ${d.interest}%"),
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
              ),
              child: const Text("กลับไปเลือกแผน"),
            ),
          ],
        ),
      ),
    );
  }
}
