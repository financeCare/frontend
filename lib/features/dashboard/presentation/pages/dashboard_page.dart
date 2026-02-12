import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/config/config.dart' as config;
import 'package:flutter_application_1/features/budget/domain/models/budgetDto.dart';

import '../../../debt/domain/models/debt_dto.dart';
import '../../data/services/dashboard_service.dart';
import '../../../debt/data/services/debt_service.dart';

class DashboardPage extends StatefulWidget {
  final List<budgetDto> incomes;
  final List<DebtDto> debts;

  const DashboardPage({super.key, required this.incomes, required this.debts});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool showPie = true; // toggle chart type
  final DashboardService service = DashboardService(
    baseUrl: config.baseUrl,
  ); // กำหนด URL API ของคุณ

  List<String> _debtTypeNames = [];
  bool _isLoadingDebtTypes = false;

  @override
  void initState() {
    super.initState();
    _fetchDebtTypes();
  }

  Future<void> _fetchDebtTypes() async {
    setState(() => _isLoadingDebtTypes = true);
    try {
      final types = await DebtService().getDebtType();
      if (mounted) {
        setState(() {
          _debtTypeNames = types.map((e) => e.debtTypeName).toList();
        });
      }
    } catch (e) {
      debugPrint("Error fetching debt types: $e");
    } finally {
      if (mounted) setState(() => _isLoadingDebtTypes = false);
    }
  }

  // ------------------ แก้ไขรายรับ ------------------
  void editIncome(int index) {
    TextEditingController amountCtrl = TextEditingController(
      text: widget.incomes[index].amount.toString(),
    );

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
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("ยกเลิก"),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                widget.incomes[index].amount =
                    double.tryParse(amountCtrl.text) ?? 0;
              });
              Navigator.pop(context);
            },
            child: const Text("บันทึก"),
          ),
        ],
      ),
    );
  }

  // ------------------ แก้ไขหนี้ ------------------
  void editDebt(int index) {
    final debt = widget.debts[index];
    final nameCtrl = TextEditingController(text: debt.name);
    final amountCtrl = TextEditingController(text: debt.amount.toString());
    final interestCtrl = TextEditingController(text: debt.interest.toString());
    String tempType = debt.type;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("แก้ไขหนี้"),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: "ชื่อหนี้"),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: _debtTypeNames.contains(tempType)
                          ? tempType
                          : null,
                      decoration: const InputDecoration(
                        labelText: "ประเภทหนี้",
                      ),
                      items: _debtTypeNames
                          .map(
                            (type) => DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            ),
                          )
                          .toList(),
                      onChanged: (val) => setDialogState(() {
                        if (val != null) tempType = val;
                      }),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: amountCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "จำนวนเงิน"),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: interestCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "ดอกเบี้ย (%)",
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("ยกเลิก"),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      debt.name = nameCtrl.text;
                      debt.amount = double.tryParse(amountCtrl.text) ?? 0;
                      debt.interest = double.tryParse(interestCtrl.text) ?? 0;
                      debt.type = tempType;
                    });
                    Navigator.pop(context);
                  },
                  child: const Text("บันทึก"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ------------------ ลบหนี้ ------------------
  void deleteDebt(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("ยืนยันการลบ"),
        content: Text(
          "คุณแน่ใจหรือไม่ว่าต้องการลบ '${widget.debts[index].name}'?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("ยกเลิก"),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => widget.debts.removeAt(index));
              Navigator.pop(context);
            },
            child: const Text("ลบ"),
          ),
        ],
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
      SnackBar(
        content: Text(success ? "ส่งข้อมูลเรียบร้อย" : "ส่งข้อมูลไม่สำเร็จ"),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double totalIncome = widget.incomes.fold(
      0,
      (sum, item) => sum + item.amount,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard Overview"),
        actions: [
          TextButton(
            onPressed: () => setState(() => showPie = !showPie),
            child: Text(
              showPie ? "Bar Chart" : "Pie Chart",
              style: const TextStyle(color: Colors.white),
            ),
          ),
          TextButton(
            onPressed: sendData, // ปุ่มส่งข้อมูล
            child: const Text("Upload", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ------------------ กราฟ ------------------
            Expanded(
              child: showPie
                  ? _buildPieChart(totalIncome)
                  : _buildBarChart(totalIncome),
            ),
            const SizedBox(height: 20),
            // ------------------ รายการรายรับ ------------------
            _buildIncomeList(),
            const SizedBox(height: 20),
            // ------------------ รายการหนี้ ------------------
            _buildDebtList(),
          ],
        ),
      ),
    );
  }

  // ------------------ Pie Chart ------------------
  Widget _buildPieChart(double totalIncome) {
    List<PieChartSectionData> sections = [
      PieChartSectionData(
        value: totalIncome,
        title: "รายรับ",
        radius: 60,
        color: Colors.green,
        titleStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    ];

    for (var debt in widget.debts) {
      sections.add(
        PieChartSectionData(
          value: debt.amount,
          title: debt.name,
          radius: 60,
          color: Colors.redAccent,
          titleStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      );
    }

    return PieChart(
      PieChartData(centerSpaceRadius: 40, sections: sections, sectionsSpace: 4),
    );
  }

  // ------------------ Bar Chart ------------------
  Widget _buildBarChart(double totalIncome) {
    List<BarChartGroupData> bars = [
      BarChartGroupData(
        x: 0,
        barRods: [
          BarChartRodData(toY: totalIncome, color: Colors.green, width: 20),
        ],
        showingTooltipIndicators: [0],
      ),
    ];

    for (int i = 0; i < widget.debts.length; i++) {
      final debt = widget.debts[i];
      bars.add(
        BarChartGroupData(
          x: i + 1,
          barRods: [
            BarChartRodData(
              toY: debt.amount,
              color: Colors.redAccent,
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
              getTitlesWidget: (value, meta) {
                if (value == 0) return const Text("รายรับ");
                int debtIndex = value.toInt() - 1;
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
          leftTitles: const AxisTitles(),
          topTitles: const AxisTitles(),
        ),
      ),
    );
  }

  // ------------------ รายการรายรับ ------------------
  Widget _buildIncomeList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "รายรับ",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        ...widget.incomes.asMap().entries.map((entry) {
          int index = entry.key;
          final item = entry.value;
          return ListTile(
            title: Text("รายรับ ${index + 1}"),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("${item.amount}"),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => editIncome(index),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ------------------ รายการหนี้ ------------------
  Widget _buildDebtList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "หนี้",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        ...widget.debts.asMap().entries.map((entry) {
          int index = entry.key;
          final debt = entry.value;
          return ListTile(
            title: Text(debt.name),
            subtitle: Text(
              "ประเภท: ${debt.type} | ดอกเบี้ย: ${debt.interest}%",
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => editDebt(index),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => deleteDebt(index),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
