import 'package:flutter/material.dart';
import '../../models/finance_item.dart';
import 'simulatorResult.dart';
import '../../services/simulator/repaymentSimulatorService.dart';

class PlanDetailScreen extends StatefulWidget {
  final String planName;
  final String description;
  final List<FinanceItem> incomes;
  final List<FinanceItem> debts;
  final double monthlyBudget;

  const PlanDetailScreen({
    super.key,
    required this.planName,
    required this.description,
    required this.incomes,
    required this.debts,
    required this.monthlyBudget,
  });

  @override
  State<PlanDetailScreen> createState() => _PlanDetailScreenState();
}

class _PlanDetailScreenState extends State<PlanDetailScreen> {
  bool showDebts = false;

  List<String> getPlanRules(String strategy) {
    switch (strategy.toLowerCase()) {
      case 'snowball':
        return [
          "เรียงหนี้จากยอดน้อย → มาก",
          "โฟกัสเงินก้อนเล็กก่อน",
          "ปิดหนี้ทีละก้อนเพื่อสร้างกำลังใจ",
        ];
      case 'avalanche':
        return [
          "เรียงหนี้จากดอกเบี้ยสูง → ต่ำ",
          "โปะก้อนที่ดอกแพงที่สุดก่อน",
          "ประหยัดดอกเบี้ยรวมมากที่สุด",
        ];
      case 'balanced':
        return [
          "กระจายเงินโปะหลายก้อนพร้อมกัน",
          "ลดความเสี่ยงระยะยาว",
          "ไม่โฟกัสก้อนใดก้อนหนึ่งเกินไป",
        ];
      default:
        return [
          "ระบบจะคำนวณการจ่ายให้อัตโนมัติ",
          "อิงจากงบต่อเดือนของคุณ",
        ];
    }
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 15)),
          Text(value,
              style:
              const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final rules = getPlanRules(widget.planName);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // TITLE
          Text(widget.planName,
              style:
              const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text("แผนนี้ทำงานอย่างไร",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...rules.map((r) => Row(
                children: [
                  const Text("• "),
                  Expanded(child: Text(r)),
                ],
              )),
            ]),
          ),

          const SizedBox(height: 20),

          // SUMMARY
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, 3))
              ],
            ),
            child:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text("สรุป",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              _infoRow("รายได้ทั้งหมด",
                  "${widget.incomes.length} บาท"),

              GestureDetector(
                onTap: () {
                  setState(() => showDebts = !showDebts);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("จำนวนหนี้", style: TextStyle(fontSize: 15)),
                      Row(
                        children: [
                          Text(
                            "${widget.debts.length} รายการ",
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          AnimatedRotation(
                            turns: showDebts ? 0.5 : 0,
                            duration: const Duration(milliseconds: 200),
                            child: const Icon(Icons.expand_more, size: 20),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: showDebts
                    ? Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Column(
                    children: widget.debts.map((d) {
                      return Card(
                        elevation: 1,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                            title: Text(d.name),
                          subtitle:
                          Text("ดอกเบี้ย ${d.interest}% | ${d.type}"),
                          trailing: Text(
                            "${d.amount.toStringAsFixed(0)} บาท",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                )
                    : const SizedBox(),
              ),
              _infoRow("งบผ่อนต่อเดือน",
                  "${widget.monthlyBudget.toStringAsFixed(0)} บาท"),
            ]),
          ),

          const SizedBox(height: 24),

          // BUTTON
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              minimumSize: const Size(double.infinity, 50),
            ),
            onPressed: () async {
              try {
                final data = await RepaymentSimulatorService().simulate();

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SimulatorResultScreen(resultFromPlan: data),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("เกิดข้อผิดพลาด: $e")),
                );
              }
            },
            child: const Text("ดูผลการจำลอง",
                style: TextStyle(color: Colors.white, fontSize: 16)),
          ),
        ]),
      ),
    );
  }
}
