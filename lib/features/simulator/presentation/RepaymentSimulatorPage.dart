import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../data/models/repayment_simulation_model.dart';
import '../data/services/repaymentTypeService.dart';

class RepaymentSimulatorPage extends StatefulWidget {
  final double monthlyBudget;
  final String strategy;
  final bool showConfirmButton;

  const RepaymentSimulatorPage({
    super.key,
    required this.monthlyBudget,
    required this.strategy,
    this.showConfirmButton = false,
  });

  @override
  State<RepaymentSimulatorPage> createState() => _RepaymentSimulatorPageState();
}

class _RepaymentSimulatorPageState extends State<RepaymentSimulatorPage> {
  late Future<RepaymentSimulationResponse> _simulationFuture;
  final Set<int> _expandedMonths = {};
  final NumberFormat _currencyFormat = NumberFormat.currency(
    symbol: '฿',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _simulationFuture = RepaymentStrategyService().getSimulationResults(
      widget.monthlyBudget,
      widget.strategy,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF2D955F),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.shield_outlined,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'FinanceCare',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.black,
              ),
            ),
          ],
        ),
        actions: const [SizedBox(width: 16)],
      ),
      body: FutureBuilder<RepaymentSimulationResponse>(
        future: _simulationFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF2D955F)),
            );
          }
          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error!);
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('ไม่พบข้อมูล'));
          }

          final data = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // _buildSimulationCompleteBadge(), removed
                const SizedBox(height: 12),
                Text(
                  'แผนการชำระหนี้ของคุณ',
                  style: GoogleFonts.outfit(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.kanit(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                    children: [
                      const TextSpan(
                        text:
                            'จากกลยุทธ์ที่คุณเลือก นี่คือระยะเวลาที่คาดการณ์ว่าคุณจะหมดหนี้ภายใน ',
                      ),
                      TextSpan(
                        text: '${data.estimatedMonths} เดือน',
                        style: const TextStyle(
                          color: Color(0xFF2D955F),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const TextSpan(text: '.'),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                _buildSummaryCards(data),
                const SizedBox(height: 40),
                _buildChartsSection(data),
                const SizedBox(height: 40),
                _buildMonthlyBreakdownList(data),
                const SizedBox(height: 100),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: widget.showConfirmButton
          ? _buildBottomConfirmFooter()
          : null,
    );
  }

  Widget _buildSummaryCards(RepaymentSimulationResponse data) {
    final principalPaid = data.totalPaid - data.totalInterest;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.2, // Adjust for card proportions
      children: [
        _buildSummaryCard(
          'ระยะเวลาที่คาดการณ์',
          '${data.estimatedMonths} เดือน',
          'จนกว่าจะหมดหนี้',
          Icons.calendar_today_outlined,
          const Color(0xFFE8F5E9),
          const Color(0xFF2D955F),
        ),
        _buildSummaryCard(
          'ยอดชำระทั้งหมด',
          _currencyFormat.format(data.totalPaid),
          'เงินต้น + ดอกเบี้ย',
          Icons.account_balance_wallet_outlined,
          const Color(0xFFE8F5E9),
          const Color(0xFF2D955F),
        ),
        _buildSummaryCard(
          'ดอกเบี้ยรวม',
          _currencyFormat.format(data.totalInterest),
          'ต้นทุนจากการกู้ยืม',
          Icons.trending_down,
          const Color(0xFFFFF1F1),
          const Color(0xFFEF5350),
        ),
        _buildSummaryCard(
          'ชำระเงินต้นแล้ว',
          _currencyFormat.format(principalPaid),
          'หนี้ที่ชำระจริง',
          Icons.monetization_on_outlined,
          const Color(0xFFE8F5E9),
          const Color(0xFF2D955F),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    String sub,
    IconData icon,
    Color bg,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.kanit(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            sub,
            style: GoogleFonts.kanit(fontSize: 11, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildChartsSection(RepaymentSimulationResponse data) {
    return Column(
      children: [
        Row(
          children: [
            _buildTabButton('กราฟ', true),
            const SizedBox(width: 12),
            _buildTabButton('ลำดับการชำระ', false),
          ],
        ),
        const SizedBox(height: 24),
        _buildLineChartCard(data),
        const SizedBox(height: 24),
        _buildBarChartCard(data),
      ],
    );
  }

  Widget _buildTabButton(String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: isSelected ? Border.all(color: Colors.grey.shade200) : null,
      ),
      child: Text(
        label,
        style: GoogleFonts.kanit(
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.black : Colors.grey.shade600,
        ),
      ),
    );
  }

  Widget _buildLineChartCard(RepaymentSimulationResponse data) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'หนี้คงเหลือตามระยะเวลา',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'การลดลงของยอดหนี้ที่คาดการณ์รายเดือน',
            style: GoogleFonts.kanit(fontSize: 13, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) =>
                      FlLine(color: Colors.grey.shade100, strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 44,
                      getTitlesWidget: (value, meta) {
                        if (value == meta.max) return const SizedBox();
                        String text = '';
                        if (value >= 1000) {
                          text = '${(value / 1000).toStringAsFixed(0)}K';
                        } else {
                          text = value.toStringAsFixed(0);
                        }
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          space: 8,
                          child: Text(
                            text,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value % 2 != 0) return const SizedBox();
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            'M${value.toInt()}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: data.monthlyResults
                        .map(
                          (m) => FlSpot(
                            m.monthNo.toDouble(),
                            m.remainingDebtTotal,
                          ),
                        )
                        .toList(),
                    isCurved: true,
                    color: const Color(0xFF2D955F),
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF2D955F).withOpacity(0.05),
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

  Widget _buildBarChartCard(RepaymentSimulationResponse data) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              Text(
                'รายละเอียดการชำระเงินรายเดือน',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildLegendCircle(const Color(0xFF2D955F), 'ชำระแล้ว'),
                  const SizedBox(width: 12),
                  _buildLegendCircle(const Color(0xFFEF5350), 'ดอกเบี้ย'),
                ],
              ),
            ],
          ),
          Text(
            'ยอดชำระเทียบกับดอกเบี้ยในแต่ละเดือน',
            style: GoogleFonts.kanit(fontSize: 13, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 44,
                      getTitlesWidget: (value, meta) {
                        if (value == meta.max) return const SizedBox();
                        String text = '';
                        if (value >= 1000) {
                          text = '${(value / 1000).toStringAsFixed(0)}K';
                        } else {
                          text = value.toStringAsFixed(0);
                        }
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          space: 8,
                          child: Text(
                            text,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            'M${value.toInt()}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: data.monthlyResults.take(10).map((m) {
                  return BarChartGroupData(
                    x: m.monthNo,
                    barRods: [
                      BarChartRodData(
                        toY: m.paidThisMonth + m.monthInterest,
                        color: Colors.transparent,
                        width: 16,
                        backDrawRodData: BackgroundBarChartRodData(show: false),
                        rodStackItems: [
                          BarChartRodStackItem(
                            0,
                            m.paidThisMonth,
                            const Color(0xFF2D955F),
                          ),
                          BarChartRodStackItem(
                            m.paidThisMonth,
                            m.paidThisMonth + m.monthInterest,
                            const Color(0xFFEF5350),
                          ),
                        ],
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendCircle(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.kanit(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildMonthlyBreakdownList(RepaymentSimulationResponse data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            Text(
              'รายละเอียดรายเดือน',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F4F2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${data.estimatedMonths} เดือน',
                style: GoogleFonts.kanit(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          ],
        ),
        Text(
          'คลิกที่เดือนเพื่อดูรายละเอียดของแต่ละหนี้',
          style: GoogleFonts.kanit(fontSize: 13, color: Colors.grey.shade500),
        ),
        const SizedBox(height: 24),
        ...data.monthlyResults.asMap().entries.map((entry) {
          final idx = entry.key;
          final month = entry.value;
          final isLast = idx == data.monthlyResults.length - 1;
          final isExpanded = _expandedMonths.contains(month.monthNo);

          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Column(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isLast ? const Color(0xFF2D955F) : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isLast
                              ? const Color(0xFF2D955F)
                              : Colors.grey.shade300,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '${month.monthNo}',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            color: isLast ? Colors.white : Colors.black54,
                          ),
                        ),
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: Colors.grey.shade300,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isExpanded) {
                          _expandedMonths.remove(month.monthNo);
                        } else {
                          _expandedMonths.add(month.monthNo);
                        }
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isExpanded
                              ? const Color(0xFF2D955F)
                              : Colors.grey.shade200,
                          width: isExpanded ? 2 : 1,
                        ),
                        boxShadow: isExpanded
                            ? [
                                BoxShadow(
                                  color: const Color(
                                    0xFF2D955F,
                                  ).withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'เดือนที่ ${month.monthNo}',
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Icon(
                                isExpanded
                                    ? Icons.keyboard_arrow_up
                                    : Icons.keyboard_arrow_down,
                                color: isExpanded
                                    ? const Color(0xFF2D955F)
                                    : Colors.grey,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _buildMonthStat(
                                'ชำระแล้ว',
                                _currencyFormat.format(month.paidThisMonth),
                                Colors.black,
                              ),
                              const SizedBox(width: 16),
                              _buildMonthStat(
                                'ดอกเบี้ย',
                                _currencyFormat.format(month.monthInterest),
                                Colors.red.shade400,
                              ),
                              const SizedBox(width: 16),
                              _buildMonthStat(
                                'คงเหลือ',
                                _currencyFormat.format(
                                  month.remainingDebtTotal,
                                ),
                                Colors.grey.shade600,
                              ),
                            ],
                          ),
                          if (isExpanded) ...[
                            const SizedBox(height: 20),
                            const Divider(),
                            const SizedBox(height: 12),
                            ...month.debtPayments.map(
                              (p) => _buildDebtPaymentDetail(p),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildDebtPaymentDetail(DebtPayment payment) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                payment.debtName,
                style: GoogleFonts.kanit(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                _currencyFormat.format(payment.minPaid + payment.extraPaid),
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: const Color(0xFF2D955F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              _buildSmallStat('Min: ', _currencyFormat.format(payment.minPaid)),
              const SizedBox(width: 12),
              if (payment.extraPaid > 0)
                _buildSmallStat(
                  'Extra: ',
                  _currencyFormat.format(payment.extraPaid),
                ),
              const Spacer(),
              _buildSmallStat(
                'Int: ',
                _currencyFormat.format(payment.interestAdded),
                isRed: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallStat(String label, String value, {bool isRed = false}) {
    return RichText(
      text: TextSpan(
        style: GoogleFonts.kanit(fontSize: 11, color: Colors.grey.shade500),
        children: [
          TextSpan(text: label),
          TextSpan(
            text: value,
            style: TextStyle(
              color: isRed ? Colors.red.shade300 : Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthStat(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.kanit(fontSize: 11, color: Colors.grey.shade500),
        ),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(Object error) {
    final errorStr = error.toString();
    final bool isBudgetError = errorStr.contains('400');

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isBudgetError
                    ? const Color(0xFFFFF3E0)
                    : const Color(0xFFFFEBEE),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isBudgetError
                    ? Icons.account_balance_wallet_outlined
                    : Icons.error_outline_rounded,
                size: 64,
                color: isBudgetError
                    ? const Color(0xFFF57C00)
                    : const Color(0xFFEB5757),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              isBudgetError
                  ? 'งบประมาณรายเดือนไม่เพียงพอ'
                  : 'ขออภัย! เกิดข้อผิดพลาดบางอย่าง',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isBudgetError
                  ? 'งบประมาณรายเดือนของคุณต่ำกว่ายอดชำระขั้นต่ำที่จำเป็นในการเคลียร์หนี้ กรุณาเพิ่มงบประมาณและลองใหม่อีกครั้ง'
                  : 'เราพบข้อผิดพลาดขณะคำนวณแผนการชำระหนี้ของคุณ กรุณาลองใหม่อีกครั้งในภายหลัง หรือติดต่อฝ่ายสนับสนุนหากปัญหายังคงอยู่',
              textAlign: TextAlign.center,
              style: GoogleFonts.kanit(
                fontSize: 16,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D955F),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  isBudgetError ? 'ปรับงบประมาณ' : 'ย้อนกลับ',
                  style: GoogleFonts.kanit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomConfirmFooter() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/home',
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2D955F),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: Text(
              'ยืนยันแผน',
              style: GoogleFonts.kanit(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
