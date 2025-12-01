import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/finance_item.dart';
import '../models/constants.dart';
import '../services/dashboard_service.dart';
import '../services/debt_service.dart';

class DashboardPage extends StatefulWidget {
  final List<FinanceItem> incomes;
  final List<FinanceItem> debts;

  const DashboardPage({super.key, required this.incomes, required this.debts});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool showPie = true; // toggle chart type
  final DashboardService service = DashboardService(baseUrl: "https://your-api.com");





  // ------------------ ส่งข้อมูลไป API ------------------
  Future<void> sendData() async {
    bool success = await service.sendDashboardData(
      incomes: widget.incomes,
      debts: widget.debts,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? "ส่งข้อมูลเรียบร้อย" : "ส่งข้อมูลไม่สำเร็จ"),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double totalIncome = widget.incomes.fold(0, (sum, item) => sum + item.amount);

    return Scaffold(
        appBar: AppBar(
          title: const Text("Dashboard Overview"),
          actions: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              child: TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: Colors.black87, // สีปุ่มเข้ม
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => setState(() => showPie = !showPie),
                child: Text(
                  showPie ? "Bar Chart" : "Pie Chart",
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),


      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Expanded(
              child: showPie ? _buildPieChart() : _buildBarChart(),
            ),

            const SizedBox(height: 20),
            _buildDebtList(),
          ],
        ),
      ),
    );
  }
  Widget _buildPieChart() {
    double totalIncome = widget.incomes.fold(0, (sum, item) => sum + item.amount);

    List<PieChartSectionData> sections = [
      PieChartSectionData(
        value: totalIncome,
        title: "รายรับ\n$totalIncome",
        radius: 60,
        color: Colors.green,
        titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    ];

    for (int i = 0; i < widget.debts.length; i++) {
      final debt = widget.debts[i];
      sections.add(PieChartSectionData(
        value: debt.amount,
        title: "${debt.name}\n${debt.amount}",
        radius: 60,
        color: chartColors[i % chartColors.length],
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

  // ------------------ Pie Chart ------------------
  Widget _buildBarChart() {
    List<BarChartGroupData> bars = [];

    for (int i = 0; i < widget.debts.length; i++) {
      final debt = widget.debts[i];
      bars.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: debt.amount,
              color: chartColors[i % chartColors.length],
              width: 20,
            ),
          ],
          showingTooltipIndicators: [0],
        ),
      );
    }

    return BarChart(
      BarChartData(
        borderData: FlBorderData(show: false),
        barGroups: bars,
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                int debtIndex = value.toInt();
                if (debtIndex >= 0 && debtIndex < widget.debts.length) {
                  return Text(
                    widget.debts[debtIndex].name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 10),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) =>
                  Text(value.toInt().toString(), style: const TextStyle(fontSize: 8)),
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
      ),
    );
  }





  // ------------------ รายการหนี้ ------------------
  Widget _buildDebtList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("หนี้", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ...widget.debts.asMap().entries.map((entry) {
          int index = entry.key;
          final debt = entry.value;
          Color bgColor = chartColors[index % chartColors.length].withOpacity(0.2);

          return Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListTile(
              title: Text("${debt.name} - ${debt.amount}"),
              subtitle: Text("ประเภท: ${debt.type} | ดอกเบี้ย: ${debt.interest}%"),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
              ),
            ),
          );
        }),
      ],
    );
  }
}
