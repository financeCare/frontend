import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../data/models/repayment_simulation_model.dart';
import '../data/services/repaymentTypeService.dart';

class RepaymentSimulatorPage extends StatefulWidget {
  final double monthlyBudget;
  final String strategy;

  const RepaymentSimulatorPage({
    super.key,
    required this.monthlyBudget,
    required this.strategy,
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
        actions: [
          _buildActionButton(
            Icons.refresh,
            'Re-simulate',
            () => Navigator.pop(context),
          ),
          const SizedBox(width: 16),
        ],
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
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('No data found'));
          }

          final data = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSimulationCompleteBadge(),
                const SizedBox(height: 12),
                Text(
                  'Your Repayment Plan',
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
                            'Based on your selected strategy, here is the projected timeline to become debt-free in ',
                      ),
                      TextSpan(
                        text: '${data.estimatedMonths} months',
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
      bottomNavigationBar: _buildBottomConfirmFooter(),
    );
  }

  Widget _buildActionButton(
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool isPrimary = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isPrimary ? const Color(0xFF2D955F) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isPrimary ? const Color(0xFF2D955F) : Colors.grey.shade300,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isPrimary ? Colors.white : Colors.black,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.kanit(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isPrimary ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimulationCompleteBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, size: 14, color: Color(0xFF2D955F)),
          const SizedBox(width: 8),
          Text(
            'Simulation Complete',
            style: GoogleFonts.kanit(
              fontSize: 12,
              color: const Color(0xFF2D955F),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(RepaymentSimulationResponse data) {
    // principal paid calculation: totalPaid - totalInterest
    final principalPaid = data.totalPaid - data.totalInterest;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildSummaryCard(
            'Estimated Duration',
            '${data.estimatedMonths} months',
            'Until debt-free',
            Icons.calendar_today_outlined,
            const Color(0xFFE8F5E9),
            const Color(0xFF2D955F),
          ),
          const SizedBox(width: 16),
          _buildSummaryCard(
            'Total Payment',
            _currencyFormat.format(data.totalPaid),
            'Principal + Interest',
            Icons.payments_outlined,
            const Color(0xFFE3F2FD),
            const Color(0xFF1976D2),
          ),
          const SizedBox(width: 16),
          _buildSummaryCard(
            'Total Interest',
            _currencyFormat.format(data.totalInterest),
            'Cost of borrowing',
            Icons.trending_up,
            const Color(0xFFFFF3E0),
            const Color(0xFFF57C00),
          ),
          const SizedBox(width: 16),
          _buildSummaryCard(
            'Principal Paid',
            _currencyFormat.format(principalPaid),
            'Actual debt cleared',
            Icons.account_balance_wallet_outlined,
            const Color(0xFFF3E5F5),
            const Color(0xFF7B1FA2),
          ),
        ],
      ),
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
      width: 180,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.kanit(fontSize: 13, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            sub,
            style: GoogleFonts.kanit(fontSize: 12, color: Colors.grey.shade500),
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
            _buildTabButton('Charts', true),
            const SizedBox(width: 12),
            _buildTabButton('Payoff Order', false),
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
            'Remaining Debt Over Time',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Projected balance decrease month by month',
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
                'Monthly Payment Breakdown',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildLegendCircle(const Color(0xFF2D955F), 'Paid'),
                  const SizedBox(width: 12),
                  _buildLegendCircle(const Color(0xFFEF5350), 'Interest'),
                ],
              ),
            ],
          ),
          Text(
            'Payment applied vs interest charged each month',
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
              'Monthly Breakdown',
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
                '${data.estimatedMonths} months',
                style: GoogleFonts.kanit(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          ],
        ),
        Text(
          'Click on a month to see individual debt details',
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
                                'Month ${month.monthNo}',
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
                                'Paid',
                                _currencyFormat.format(month.paidThisMonth),
                                Colors.black,
                              ),
                              const SizedBox(width: 16),
                              _buildMonthStat(
                                'Interest',
                                _currencyFormat.format(month.monthInterest),
                                Colors.red.shade400,
                              ),
                              const SizedBox(width: 16),
                              _buildMonthStat(
                                'Remaining',
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

  Widget _buildBottomConfirmFooter() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: const Color(0xFF2D955F).withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ready to start your repayment journey?',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Confirm this plan and we will set up automatic reminders for you.',
                      style: GoogleFonts.kanit(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await RepaymentStrategyService().createPlan(
                      monthlyBudget: widget.monthlyBudget,
                      strategyId: widget.strategy,
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Plan confirmed successfully!'),
                        ),
                      );
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    }
                  } catch (e) {
                    if (mounted)
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D955F),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Confirm Plan',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'This is a simulation based on current data. Actual results may vary based on payment timing and interest rate changes.',
            textAlign: TextAlign.center,
            style: GoogleFonts.kanit(fontSize: 10, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}
