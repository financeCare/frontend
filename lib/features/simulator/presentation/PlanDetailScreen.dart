import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../debt/domain/models/finance_item.dart';
import '../../debt/data/services/debt_service.dart';
import '../../debt/domain/models/debt_response.dart';

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
  late Future<List<DebtResponse>> _debtsFuture;

  @override
  void initState() {
    super.initState();
    _debtsFuture = DebtService().getAllDebt();
  }

  List<String> getPlanRules(String strategy) {
    switch (strategy.toLowerCase()) {
      case 'snowball method':
      case 'snowball':
        return [
          "เรียงหนี้จากยอดน้อย → มาก",
          "โฟกัสเงินก้อนเล็กก่อนเพื่อสร้างพลังใจ",
          "ปิดหนี้ทีละก้อนเพื่อให้เห็นผลสำเร็จเร็ว",
        ];
      case 'avalanche method':
      case 'avalanche':
        return [
          "เรียงหนี้จากดอกเบี้ยสูง → ต่ำ",
          "โปะก้อนที่ดอกเบี้ยแพงที่สุดก่อน",
          "ช่วยประหยัดเงินค่าดอกเบี้ยได้มากที่สุด",
        ];
      case 'hybrid method':
      case 'hybrid':
        return [
          "ผสมผสานระหว่าง Snowball และ Avalanche",
          "ปิดหนี้ก้อนเล็กควบคู่ไปกับก้อนที่ดอกเบี้ยสูง",
          "สร้างทั้งกำลังใจและประหยัดดอกเบี้ย",
        ];
      case 'highest balance first':
        return [
          "มุ่งเน้นที่หนี้ก้อนใหญ่ที่สุดก่อน",
          "ลดภาระหนี้ก้อนใหญ่ให้เหลือน้อยลงเร็วขึ้น",
          "เหมาะสำหรับการลดความเสี่ยงจากการค้างชำระก้อนใหญ่",
        ];
      default:
        return [
          "ระบบจะคำนวณการจ่ายให้อัตโนมัติ",
          "ปรับตามงบประมาณรายเดือนที่คุณตั้งไว้",
          "พยายามปิดหนี้ให้เร็วที่สุดตามกลยุทธ์ที่เลือก",
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Plan Details',
          style: GoogleFonts.kanit(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      body: FutureBuilder<List<DebtResponse>>(
        future: _debtsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final debts = snapshot.data ?? [];
          final rules = getPlanRules(widget.planName);
          final totalDebtAmount = debts.fold(
            0.0,
            (sum, item) => sum + item.principalAmount,
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPlanHeader(rules),
                const SizedBox(height: 32),
                Text(
                  'Summary',
                  style: GoogleFonts.kanit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A1C1E),
                  ),
                ),
                const SizedBox(height: 16),
                _buildSummaryCard(totalDebtAmount),
                const SizedBox(height: 32),
                _buildDebtSection(debts),
                const SizedBox(height: 100),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: () async {
            try {
              // Placeholder for simulation result navigation
              // final data = await RepaymentSimulatorService().simulate();
              // Navigator.push(...)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Simulation feature coming soon!"),
                ),
              );
            } catch (e) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text("Error: $e")));
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00796B),
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
          child: Text(
            'View Simulation Result',
            style: GoogleFonts.kanit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlanHeader(List<String> rules) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF00796B).withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF00796B).withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.planName,
            style: GoogleFonts.kanit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF00796B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "How this plan works:",
            style: GoogleFonts.kanit(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          ...rules.map(
            (rule) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    size: 20,
                    color: Color(0xFF00796B),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      rule,
                      style: GoogleFonts.kanit(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(double totalDebt) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _summaryRow(
            "Total Debt",
            "฿${totalDebt.toStringAsFixed(0)}",
            Colors.black,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Divider(height: 1),
          ),
          _summaryRow(
            "Monthly Budget",
            "฿${widget.monthlyBudget.toStringAsFixed(0)}",
            const Color(0xFF00796B),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.kanit(fontSize: 16, color: Colors.grey.shade600),
        ),
        Text(
          value,
          style: GoogleFonts.kanit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildDebtSection(List<DebtResponse> debts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => showDebts = !showDebts),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Debts to handle (${debts.length})',
                style: GoogleFonts.kanit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A1C1E),
                ),
              ),
              Icon(
                showDebts ? Icons.expand_less : Icons.expand_more,
                color: Colors.grey,
              ),
            ],
          ),
        ),
        if (showDebts) ...[
          const SizedBox(height: 16),
          ...debts.map(
            (debt) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          debt.debtName,
                          style: GoogleFonts.kanit(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          "${debt.debtType.debtTypeName} • ${debt.interestRate}% Interest",
                          style: GoogleFonts.kanit(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    "฿${debt.principalAmount.toStringAsFixed(0)}",
                    style: GoogleFonts.kanit(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
