import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../features/simulator/data/services/repaymentTypeService.dart';
import '../../../../features/simulator/presentation/RepaymentSimulatorPage.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/services/debt_service.dart';
import '../../domain/models/debt_response.dart';

class DebtOverviewPage extends StatefulWidget {
  const DebtOverviewPage({super.key});

  @override
  State<DebtOverviewPage> createState() => _DebtOverviewPageState();
}

class _DebtOverviewPageState extends State<DebtOverviewPage> {
  final DebtService _debtService = DebtService();
  List<DebtResponse> _debtResponses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final List<DebtResponse> responses = await _debtService.getAllDebt();
      if (!mounted) return;
      setState(() {
        _debtResponses = responses;
      });
    } catch (e) {
      debugPrint("Error loading debts: $e");
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteDebt(DebtResponse debt) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'ยืนยันการลบ',
          style: GoogleFonts.kanit(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'คุณแน่ใจหรือไม่ว่าต้องการลบรายการหนี้ "${debt.debtName}"? รายการนี้จะถูกลบถาวร',
          style: GoogleFonts.kanit(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'ยกเลิก',
              style: GoogleFonts.kanit(color: Colors.black45),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEB5757),
              foregroundColor: Colors.white,
            ),
            child: Text('ลบ', style: GoogleFonts.kanit()),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await _debtService.deleteDebt(debt.debtId);
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('ลบรายการหนี้สำเร็จ')));
        }
      } catch (e) {
        debugPrint("Error deleting debt: $e");
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาดในการลบ: $e')));
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeDebts = _debtResponses.where((d) => d.isActive).toList()
      ..sort((a, b) => a.principalAmount.compareTo(b.principalAmount));
    final closedDebts = _debtResponses.where((d) => !d.isActive).toList();

    double totalPrincipal = activeDebts.fold(
      0.0,
      (sum, d) => sum + d.principalAmount,
    );
    double avgInterest = activeDebts.isEmpty
        ? 0.0
        : activeDebts.fold(0.0, (sum, d) => sum + d.interestRate) /
              activeDebts.length;
    double totalMinPayment = activeDebts.fold(
      0.0,
      (sum, d) => sum + d.minPayment,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFEB5757)),
              )
            : RefreshIndicator(
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'สวัสดี, ยินดีต้อนรับ',
                        style: GoogleFonts.kanit(
                          fontSize: 14,
                          color: Colors.black45,
                        ),
                      ),
                      Text(
                        'ภาพรวมหนี้สิน',
                        style: GoogleFonts.kanit(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildSummaryCard(
                        totalPrincipal: totalPrincipal,
                        activeCount: activeDebts.length,
                        totalCount: _debtResponses.length,
                        avgInterest: avgInterest,
                        minPayment: totalMinPayment,
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'เมนูลัด',
                        style: GoogleFonts.kanit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildQuickMenu(),
                      const SizedBox(height: 32),
                      _buildSectionHeader(
                        'หนี้ที่ใช้งานอยู่',
                        activeDebts.length,
                      ),
                      const SizedBox(height: 16),
                      if (activeDebts.isEmpty)
                        _buildEmptyState('ไม่มีรายการหนี้ที่ใช้งานอยู่')
                      else
                        ...activeDebts.map((debt) => _buildDebtCard(debt)),
                      const SizedBox(height: 32),
                      _buildSectionHeader(
                        'หนี้ที่ปิดการใช้งาน',
                        closedDebts.length,
                      ),
                      const SizedBox(height: 16),
                      if (closedDebts.isEmpty)
                        _buildEmptyState('ไม่มีรายการหนี้ที่ปิดการใช้งาน')
                      else
                        ...closedDebts.map(
                          (debt) => _buildClosedDebtCard(debt),
                        ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required double totalPrincipal,
    required int activeCount,
    required int totalCount,
    required double avgInterest,
    required double minPayment,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFEB5757),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEB5757).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.monetization_on_outlined,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'ยอดหนี้คงเหลือทั้งหมด',
                style: GoogleFonts.kanit(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '฿${NumberFormat('#,###.00').format(totalPrincipal)}',
            style: GoogleFonts.kanit(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'จำนวนหนี้ที่ใช้งาน',
                      style: GoogleFonts.kanit(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$activeCount / $totalCount รายการ',
                      style: GoogleFonts.kanit(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 40,
                width: 1,
                color: Colors.white.withOpacity(0.2),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ดอกเบี้ยเฉลี่ย',
                      style: GoogleFonts.kanit(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${avgInterest.toStringAsFixed(1)}% ต่อปี',
                      style: GoogleFonts.kanit(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.trending_down, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  'ยอดจ่ายขั้นต่ำรวม: ฿${NumberFormat('#,###.00').format(minPayment)}/เดือน',
                  style: GoogleFonts.kanit(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickMenu() {
    final menus = [
      {
        'icon': Icons.add_circle_outline,
        'label': 'สร้างหนี้',
        'color': const Color(0xFFFFEBEE),
        'iconColor': const Color(0xFFEB5757),
        'route': '/add_debt',
      },
      {
        'icon': Icons.track_changes_outlined,
        'label': 'กลยุทธ์ชำระ',
        'color': const Color(0xFFFFF3E0),
        'iconColor': const Color(0xFFFF9800),
        'route': '/simulator', // Needs to go to strategy screen
      },
      {
        'icon': Icons.bar_chart,
        'label': 'ดูแผนของคุณ',
        'color': const Color(0xFFE3F2FD),
        'iconColor': const Color(0xFF1976D2),
        'route': '/simulator_results', // Placeholder for results
      },
      {
        'icon': Icons.account_balance_wallet_outlined,
        'label': 'รายรับ/รายจ่าย',
        'color': const Color(0xFFF1F8E9),
        'iconColor': const Color(0xFF8BC34A),
        'route': '/expense_entry',
      },
      {
        'icon': Icons.credit_card,
        'label': 'ชำระหนี้',
        'color': const Color(0xFFE8F5E9),
        'iconColor': const Color(0xFF2D955F),
        'route': '/pay_debt',
      },
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: menus.map((menu) {
          return Padding(
            padding: const EdgeInsets.only(right: 20),
            child: GestureDetector(
              onTap: () async {
                if (menu['route'] == '/simulator_results') {
                  setState(() => _isLoading = true);
                  try {
                    final overview = await RepaymentStrategyService()
                        .fetchStrategies();
                    if (!mounted) return;
                    // Navigate to simulator with existing budget and first strategy as fallback
                    final strategyId = overview.strategies.isNotEmpty
                        ? overview.strategies.first.strategyId
                        : "snowball"; // Fallback
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RepaymentSimulatorPage(
                          monthlyBudget: overview.monthlyBudget,
                          strategy: strategyId,
                          showConfirmButton: false,
                        ),
                      ),
                    );
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('ไม่พบข้อมูลแผนของคุณ: $e')),
                      );
                    }
                  } finally {
                    if (mounted) setState(() => _isLoading = false);
                  }
                } else {
                  Navigator.pushNamed(
                    context,
                    menu['route'] as String,
                  ).then((_) => _loadData());
                }
              },
              child: Column(
                children: [
                  Container(
                    width: 56, // Fixed width for alignment as in Image 1
                    height: 56,
                    decoration: BoxDecoration(
                      color: menu['color'] as Color,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      menu['icon'] as IconData,
                      color: menu['iconColor'] as Color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    menu['label'] as String,
                    style: GoogleFonts.kanit(
                      fontSize: 12,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.kanit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        Text(
          '$count รายการ',
          style: GoogleFonts.kanit(fontSize: 13, color: Colors.black26),
        ),
      ],
    );
  }

  Widget _buildDebtCard(DebtResponse debt) {
    final remainingDays = debt.endDate.difference(DateTime.now()).inDays;
    final totalDays = debt.endDate.difference(debt.startDate).inDays;
    final progress = totalDays > 0
        ? (1 - (remainingDays / totalDays)).clamp(0.0, 1.0)
        : 1.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.credit_card_outlined,
                  color: Color(0xFFEB5757),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      debt.debtName,
                      style: GoogleFonts.kanit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${debt.debtType.debtTypeName} / ${debt.repaymentType.typeName}',
                      style: GoogleFonts.kanit(
                        fontSize: 12,
                        color: Colors.black45,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.black12),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '฿${NumberFormat('#,###.00').format(debt.principalAmount)}',
                style: GoogleFonts.kanit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.edit_outlined,
                      color: Color(0xFF2196F3),
                      size: 20,
                    ),
                    onPressed: () =>
                        Navigator.pushNamed(
                          context,
                          '/add_debt',
                          arguments: debt,
                        ).then((value) {
                          if (value == true) _loadData();
                        }),
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(8),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Color(0xFFEB5757),
                      size: 20,
                    ),
                    onPressed: () => _deleteDebt(debt),
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(8),
                  ),
                ],
              ),
            ],
          ),
          Text(
            'ดอกเบี้ย ${debt.interestRate}%',
            style: GoogleFonts.kanit(fontSize: 13, color: Colors.black45),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    size: 14,
                    color: Colors.black26,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'เหลืออีก $remainingDays วัน',
                    style: GoogleFonts.kanit(
                      fontSize: 12,
                      color: Colors.black38,
                    ),
                  ),
                ],
              ),
              Text(
                DateFormat('dd MMM yy', 'th').format(debt.endDate),
                style: GoogleFonts.kanit(fontSize: 12, color: Colors.black38),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: const Color(0xFFF1F3F4),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFFEB5757),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClosedDebtCard(DebtResponse debt) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F4).withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.02)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.block, color: Colors.black26, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  debt.debtName,
                  style: GoogleFonts.kanit(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.black45,
                  ),
                ),
                Text(
                  '฿${NumberFormat('#,###.00').format(debt.principalAmount)} - ${debt.debtType.debtTypeName}',
                  style: GoogleFonts.kanit(fontSize: 12, color: Colors.black26),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'ปิดใช้งาน',
              style: GoogleFonts.kanit(fontSize: 11, color: Colors.black26),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.02)),
      ),
      child: Column(
        children: [
          const Icon(Icons.inbox_outlined, size: 48, color: Colors.black12),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.kanit(color: Colors.black26, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
