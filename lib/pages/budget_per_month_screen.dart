import 'package:flutter/material.dart';
import '../models/finance_item.dart';

class BudgetPerMonthScreen extends StatelessWidget {
  // 🌟 เพิ่ม Constructor เพื่อรับข้อมูล
  final List<FinanceItem> incomes;
  final List<FinanceItem> debts;

  const BudgetPerMonthScreen({
    super.key,
    required this.incomes,
    required this.debts,
  });

  // 🌟 ฟังก์ชันคำนวณรายได้รวม
  double _calculateTotalIncome() {
    return incomes.fold(0.0, (sum, item) => sum + item.amount);
  }

  // 🌟 ฟังก์ชันคำนวณยอดหนี้รวม
  double _calculateTotalDebt() {
    return debts.fold(0.0, (sum, item) => sum + item.amount);
  }

  @override
  Widget build(BuildContext context) {
    final totalIncome = _calculateTotalIncome();
    final totalDebt = _calculateTotalDebt();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'สรุปงบประมาณและการเงิน',
            style: Theme.of(context).textTheme.headlineMedium!.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          // Card แสดงรายได้รวม
          Card(
            color: Colors.green.shade50,
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('รายรับรวมทั้งหมด / เดือน', style: TextStyle(fontSize: 16, color: Colors.green)),
                  const SizedBox(height: 8),
                  Text(
                    '${totalIncome.toStringAsFixed(2)} บาท',
                    style: Theme.of(context).textTheme.headlineLarge!.copyWith(color: Colors.green.shade700, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 15),

          // Card แสดงหนี้สินรวม
          Card(
            color: Colors.red.shade50,
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ยอดหนี้สินรวม (ทั้งหมด)', style: TextStyle(fontSize: 16, color: Colors.red)),
                  const SizedBox(height: 8),
                  Text(
                    '${totalDebt.toStringAsFixed(2)} บาท',
                    style: Theme.of(context).textTheme.headlineLarge!.copyWith(color: Colors.red.shade700, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),

          // รายละเอียดรายการหนี้ (แสดงเป็น List)
          Text('รายการหนี้สินทั้งหมด (${debts.length} รายการ):', style: Theme.of(context).textTheme.titleLarge),
          const Divider(),
          if (debts.isEmpty)
            const Center(child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Text('ไม่มีรายการหนี้สินที่ถูกบันทึก', style: TextStyle(color: Colors.grey)),
            ))
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: debts.length,
              itemBuilder: (context, index) {
                final debt = debts[index];
                return ListTile(
                  leading: const Icon(Icons.money_off, color: Colors.red),
                  title: Text(debt.name),
                  subtitle: Text('ประเภท: ${debt.type}, ดอกเบี้ย: ${debt.interest}%'),
                  trailing: Text('-${debt.amount.toStringAsFixed(0)}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                );
              },
            ),
        ],
      ),
    );
  }
}