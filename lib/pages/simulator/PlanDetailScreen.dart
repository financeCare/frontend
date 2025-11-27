import 'package:flutter/material.dart';
import '../../models/debt_plan_model.dart';
import '../../models/finance_item.dart';
import 'simulator_result.dart';
import 'simulator_screen.dart';

class PlanDetailScreen extends StatelessWidget {
  final DebtPlan plan;
  final List<FinanceItem> incomes;
  final List<FinanceItem> debts;
  final double monthlyBudget;

  const PlanDetailScreen({
    super.key,
    required this.plan,
    required this.incomes,
    required this.debts,
    required this.monthlyBudget,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    Widget buildSection(String title, List<String>? items) {
      if (items == null || items.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            ...items.map((i) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text("• $i", style: const TextStyle(fontSize: 14)),
            )),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(plan.name),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text(plan.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(plan.description, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            buildSection("ข้อดี", plan.pros),
            buildSection("ข้อเสีย", plan.cons),
            buildSection("เคล็ดลับการใช้งาน", plan.tips),
            if (plan.exampleUsage != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  const Text("ตัวอย่างการใช้งาน",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(plan.exampleUsage!, style: const TextStyle(fontSize: 14)),
                ],
              ),
            buildSection("คำเตือน/ข้อควรระวัง", plan.warnings),
            buildSection("ผลลัพธ์ที่คาดหวัง", plan.expectedResults),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (plan.simulate != null) {
                  final result = plan.simulate!(incomes, debts); // ส่งค่าไปคำนวณ

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SimulatorResultScreen(
                        debts: debts,
                        monthlyBudget: monthlyBudget,
                       strategy: plan.strategy!
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('ไม่มีสูตร simulation สำหรับแผนนี้')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                foregroundColor: Colors.white,
              ),
              child: const Text("ต่อไป"),
            ),
          ],
        ),
      ),
    );
  }
}
