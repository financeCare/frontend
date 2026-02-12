import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../data/services/debt_service.dart';
import '../../domain/models/debt_dto.dart';
import '../../domain/models/debt_response.dart';

class DebtOverviewPage extends StatefulWidget {
  const DebtOverviewPage({super.key});

  @override
  State<DebtOverviewPage> createState() => _DebtOverviewPageState();
}

class _DebtOverviewPageState extends State<DebtOverviewPage> {
  final DebtService _debtService = DebtService();
  List<DebtDto> _debts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final List<DebtResponse> responses = await _debtService.getAllDebt();
      setState(() {
        _debts = responses
            .map(
              (d) => DebtDto(
                id: d.debtId,
                name: d.debtName,
                amount: d.principalAmount,
                interest: d.interestRate,
                type: d.debtType.debtTypeName,
              ),
            )
            .toList();
      });
    } catch (e) {
      debugPrint("Error loading debts: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _deleteDebt(int index) async {
    final debt = _debts[index];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("ยืนยันการลบ"),
        content: Text("คุณแน่ใจหรือไม่ว่าต้องการลบ '${debt.name}'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("ยกเลิก"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("ลบ"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _debtService.deleteDebt(debt.id);
        _loadData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("ลบไม่สำเร็จ: $e")));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double totalDebt = DebtDto.totalAmount(_debts);

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "ภาพรวมหนี้สิน",
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    _buildSummaryCard(totalDebt),
                    const SizedBox(height: 30),
                    if (_debts.isNotEmpty) ...[
                      SizedBox(height: 200, child: _buildChart()),
                      const SizedBox(height: 30),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "รายการหนี้ของคุณ",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => Navigator.pushNamed(
                            context,
                            '/add_debt',
                          ).then((_) => _loadData()),
                          icon: const Icon(Icons.add),
                          label: const Text("เพิ่มหนี้"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orangeAccent,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (_debts.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40.0),
                          child: Text("ยังไม่มีรายการหนี้"),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _debts.length,
                        itemBuilder: (context, index) {
                          final debt = _debts[index];
                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: ListTile(
                              title: Text(
                                debt.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                "ยอดหนี้: ${debt.amount.toStringAsFixed(2)} บาท\nดอกเบี้ย: ${debt.interest}% | ${debt.type}",
                              ),
                              isThreeLine: true,
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () => _deleteDebt(index),
                              ),
                              onTap: () {
                                // Optional: Detail view
                              },
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSummaryCard(double total) {
    return Card(
      elevation: 4,
      color: Colors.redAccent.shade100,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "ยอดหนี้รวมทั้งหมด",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                Text(
                  "${total.toStringAsFixed(2)} บาท",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Icon(Icons.account_balance, color: Colors.white, size: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildChart() {
    List<PieChartSectionData> sections = _debts.asMap().entries.map((entry) {
      final index = entry.key;
      final debt = entry.value;
      final colors = [
        Colors.redAccent,
        Colors.orangeAccent,
        Colors.pinkAccent,
        Colors.purpleAccent,
      ];
      return PieChartSectionData(
        value: debt.amount,
        title: debt.name,
        color: colors[index % colors.length],
        radius: 50,
        titleStyle: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      );
    }).toList();

    return PieChart(
      PieChartData(sections: sections, centerSpaceRadius: 40, sectionsSpace: 2),
    );
  }
}
