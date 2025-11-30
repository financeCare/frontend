import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/finance_item.dart';
import '../models/constants.dart';
import '../services/dashboard_service.dart';

class DashboardPage extends StatefulWidget {
  final List<FinanceItem> incomes;
  final List<FinanceItem> debts;

  const DashboardPage({super.key, required this.incomes, required this.debts});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final DashboardService service = DashboardService(baseUrl: "https://your-api.com");

  // ------------------ เพิ่มรายรับ ------------------
  void addIncome() {
    final amountCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("เพิ่มรายรับ"),
        content: TextField(
          controller: amountCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: "จำนวนเงิน"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("ยกเลิก")),
          ElevatedButton(
            onPressed: () {
              setState(() {
                double amount = double.tryParse(amountCtrl.text) ?? 0;
                if (amount > 0) {
                  widget.incomes.add(FinanceItem(name: "รายรับใหม่", amount: amount));
                }
              });
              Navigator.pop(context);
            },
            child: const Text("บันทึก"),
          ),
        ],
      ),
    );
  }

  // ------------------ แก้ไขรายรับ ------------------
  void editIncome(int index) {
    final amountCtrl = TextEditingController(text: widget.incomes[index].amount.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("แก้ไขรายรับ"),
        content: TextField(
          controller: amountCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: "จำนวนเงิน"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("ยกเลิก")),
          ElevatedButton(
            onPressed: () {
              setState(() {
                widget.incomes[index].amount = double.tryParse(amountCtrl.text) ?? 0;
              });
              Navigator.pop(context);
            },
            child: const Text("บันทึก"),
          ),
        ],
      ),
    );
  }

  // ------------------ Pie Chart ------------------
  Widget _buildPieChart() {
    List<PieChartSectionData> sections = [];

    // รายรับ
    double totalIncome = widget.incomes.fold(0, (sum, item) => sum + item.amount);
    if (totalIncome > 0) {
      sections.add(PieChartSectionData(
        value: totalIncome,
        title: "รายรับ\n${totalIncome.toStringAsFixed(0)}",
        color: Colors.green,
        radius: 60,
        titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
      ));
    }

    // หนี้
    for (var debt in widget.debts) {
      sections.add(PieChartSectionData(
        value: debt.amount,
        title: "${debt.name}\n${debt.amount.toStringAsFixed(0)}",
        color: Colors.redAccent,
        radius: 60,
        titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
      ));
    }

    return PieChart(
      PieChartData(
        centerSpaceRadius: 40,
        sections: sections,
        sectionsSpace: 4,
      ),
    );
  }

  // ------------------ ส่งข้อมูลไป API ------------------
  Future<void> sendData() async {
    bool success = await service.sendDashboardData(
      incomes: widget.incomes,
      debts: widget.debts,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? "ส่งข้อมูลเรียบร้อย" : "ส่งข้อมูลไม่สำเร็จ")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard Overview"),
        actions: [
          TextButton(
            onPressed: sendData,
            child: const Text("Upload", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Pie Chart
            Expanded(child: _buildPieChart()),
            const SizedBox(height: 20),

            // ปุ่มเพิ่มรายรับ
            ElevatedButton(
              onPressed: addIncome,
              child: const Text("เพิ่มรายรับ"),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),

            const SizedBox(height: 20),
            // รายรับ
            _buildIncomeList(),
            const SizedBox(height: 20),
            // รายการหนี้
            _buildDebtList(),
          ],
        ),
      ),
    );
  }

  Widget _buildIncomeList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("รายรับ", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ...widget.incomes.asMap().entries.map((entry) {
          int index = entry.key;
          final item = entry.value;
          return ListTile(
            title: Text(item.name),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("${item.amount}"),
                IconButton(icon: const Icon(Icons.edit), onPressed: () => editIncome(index)),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildDebtList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("หนี้", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ...widget.debts.asMap().entries.map((entry) {
          int index = entry.key;
          final debt = entry.value;
          return ListTile(
            title: Text(debt.name),
            subtitle: Text("ประเภท: ${debt.type} | ดอกเบี้ย: ${debt.interest}%"),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,

            ),
          );
        }),
      ],
    );
  }
}
